pragma solidity ^0.8.26;

import "../AbstractYodlRouter.sol";


abstract contract YodlNativeRouter is AbstractYodlRouter {
    /**
     * @notice Handles payments when sending tokens directly without DEX.
     * ## Example: Pay without pricefeeds, e.g. USDC transfer
     *
     * yodlWithToken(
     *   "tx-123",         // memo
     *   5*10**18,         // 5$
     *   [0x0, 0x0],  // no pricefeeds
     *   0xUSDC,           // usdc token address
     *   0xAlice           // receiver token address
     * )
     *
     * ## Example: Pay with pricefeeds (EUR / USD)
     *
     * The user entered the amount in EUR, which gets converted into
     * USD by the on-chain pricefeed.
     *
     * yodlWithToken(
     *     "tx-123",               // memo
     *     4.5*10**18,             // 4.5 EUR (~5$).
     *     [0xEURUSD, 0x0],   // EUR/USD price feed
     *     0xUSDC,                 // usdc token address
     *     0xAlice                 // receiver token address
     * )
     *
     *
     * ## Example: Pay with extra fee
     *
     * 3rd parties can receive an extra fee that is taken directly from
     * the receivable amount.
     *
     * yodlWithToken(
     *     "tx-123",               // memo
     *     4.5*10**18,             // 4.5 EUR (~5$).
     *     [0xEURUSD, 0x0],   //
     *     0xUSDC,                 // usdc token address
     *     0xAlice,                // receiver token address
     *     0x3rdParty              // extra fee for 3rd party provider
     *     50,                    // extra fee bps 0.5%
     * )
     * @dev This is the most gas efficient payment method. It supports currency conversion using price feeds. The
     * native token (ETH, AVAX, MATIC) is represented by the NATIVE_TOKEN constant.
     * @param memo The message attached to the payment. If present, the router will take a fee.
     * @param amount The amount to pay before any price feeds are applied. This amount will be converted by the price
     * feeds and then the sender will pay the converted amount in the given token.
     * @param priceFeeds Array of Chainlink price feeds. See `exchangeRate` method for more details.
     * @param token Token address to be used for the payment. Either an ERC20 token or the native token address.
     * @param receiver Address to receive the payment
     * @param extraFeeReceiver Address to receive an extra fee that is taken from the payment amount
     * @param extraFeeBps Size of the extra fee in terms of basis points (or 0 for none)
     * @param yd Metadata tracker for the payment
     * @return Amount received by the receiver
     */
    function yodlWithToken(
        bytes32 memo,
        uint256 amount,
        address[2] calldata priceFeeds,
        address token,
        address receiver,
        address extraFeeReceiver,
        uint256 extraFeeBps,
        uint256 yd
    ) external payable returns (uint256) {
        require(amount != 0, "invalid amount");

        uint256 finalAmount = amount;

        // transform amount with priceFeeds
        if (priceFeeds[0] != address(0) || priceFeeds[1] != address(0)) {
            {
                int256[2] memory prices;
                address[2] memory priceFeedsUsed;
                (finalAmount, priceFeedsUsed, prices) = exchangeRate(
                    priceFeeds,
                    amount
                );
                emit Convert(
                    priceFeedsUsed[0],
                    priceFeedsUsed[1],
                    prices[0],
                    prices[1]
                );
            }
        }

        if (token != NATIVE_TOKEN) {
            // ERC20 token
            require(
                IERC20(token).allowance(msg.sender, address(this)) >= finalAmount,
                "insufficient allowance"
            );
        } else {
            // Native ether
            require(msg.value >= finalAmount, "insufficient gas provided");
        }

        uint256 totalFee = 0;

        if (memo != "") {
            totalFee += transferFee(
                finalAmount,
                baseFeeBps,
                token,
                token == NATIVE_TOKEN ? address(this) : msg.sender,
                feeTreasury
            );
        }

        if (extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(extraFeeBps < MAX_FEE_BPS, "extraFeeBps too high");

            totalFee += transferFee(
                finalAmount,
                extraFeeBps,
                token,
                token == NATIVE_TOKEN ? address(this) : msg.sender,
                extraFeeReceiver
            );
        }

        // Transfer to receiver
        if (token != NATIVE_TOKEN) {
            // ERC20 token
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                receiver,
                finalAmount - totalFee
            );
        } else {
            // Native ether
            (bool success,) = receiver.call{value: finalAmount - totalFee}("");
            require(success, "transfer of the native token to the recipient failed");
            emit YodlNativeTokenTransfer(msg.sender, receiver, finalAmount - totalFee);
            if (msg.value > finalAmount) {
                // Return excess ether
                (bool dustSuccess,) = msg.sender.call{value: msg.value - finalAmount}("");
                require(dustSuccess, "transfer of the dust to the sender failed");
            }
        }

        emit Yodl(msg.sender, receiver, token, finalAmount, totalFee, memo);

        return finalAmount - totalFee;
    }
}