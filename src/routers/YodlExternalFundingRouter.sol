// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../AbstractYodlRouter.sol";
import "../interfaces/IBeforeHook.sol";

abstract contract YodlExternalFundingRouter is AbstractYodlRouter {
    struct YodlExternalFundingParams {
        // The message attached to the payment. If present, the router will take a fee.
        bytes32 memo;
        // The amount to be transfered to the router in terms of swapped tokenOut. This includes the convenience fee.
        uint256 amount;
        // The amount to pay in terms of invoice currency. Used only for emitting price feeds/exchange rates for indexing purposes.
        uint256 invoiceAmount;
        // Array of Chainlink price feeds. See `exchangeRate` method for more details.
        PriceFeed[2] priceFeeds;
        // Token address to be used for the payment. Either an ERC20 token or the native token address.
        address token;
        // Address to receive the payment
        address receiver;
        // Address to receive an extra fee that is taken from the payment amount
        address extraFeeReceiver;
        // Size of the extra fee in terms of basis points (or 0 for none)
        uint256 extraFeeBps;
        // Metadata tracker for the payment
        uint256 yd;
        // List of YApps that are allowed to be called with IBeforeHook.beforeHook extension
        Guard[] guards;
        // Array of webhook addresses and their associated calldata
        Webhook[] webhooks;
        // Convenience fee in basis points (or 0 for none)
        uint256 convenienceFeeBps;
    }

    /**
     * @notice Handles payments when sending tokens after DEX swap.
     * ## Example: Pay without pricefeeds, e.g. USDC transfer
     *
     * yodlWithSwappedToken(
     *   "tx-123",         // memo
     *   5*10**18,         // 5$
     *   [0x0, 0x0],       // no pricefeeds
     *   0xUSDC,           // usdc token address
     *   0xAlice           // receiver token address
     * )
     *
     * ## Example: Pay with pricefeeds (EUR / USD)
     *
     * The user entered the amount in EUR, which gets converted into
     * USD by the on-chain pricefeed.
     *
     * yodlWithSwappedToken(
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
     * yodlWithSwappedToken(
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
     * @param params Struct that contains all the relevant parameters. See `YodlNativeParams` for more details.
     * @return Amount received by the receiver
     */
    function yodlWithSwappedToken(YodlExternalFundingParams calldata params) external payable returns (uint256) {
        require(params.amount != 0, "invalid amount");

        uint256 outAmountGross = params.amount;

        // Calculate exchange rate and emit for indexing purposes
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            {
                int256[2] memory prices;
                address[2] memory priceFeedsUsed;
                (, priceFeedsUsed, prices) = exchangeRate(params.priceFeeds, params.invoiceAmount);
                emitConversionEvent(params.priceFeeds, prices);
            }
        }

        if (params.guards.length > 0) {
            for (uint256 i = 0; i < params.guards.length; i++) {
                IBeforeHook(params.guards[i].guardAddress).beforeHook(
                    msg.sender, params.receiver, outAmountGross, params.token, params.guards[i].payload
                );
            }
        }

        // Transfer full amount to router first
        if (params.token != NATIVE_TOKEN) {
            require(
                IERC20(params.token).allowance(msg.sender, address(this)) >= outAmountGross, "insufficient allowance"
            );
            TransferHelper.safeTransferFrom(params.token, msg.sender, address(this), outAmountGross);
        } else {
            require(msg.value >= outAmountGross, "insufficient gas provided");
        }

        uint256 totalFee = calculateFee(outAmountGross, params.convenienceFeeBps);

        if (params.memo != "" || params.guards.length > 0) {
            totalFee += calculateFee(outAmountGross, yodlFeeBps);
        }

        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(params.extraFeeBps < MAX_EXTRA_FEE_BPS, "extraFeeBps too high");

            totalFee +=
                transferFee(outAmountGross, params.extraFeeBps, params.token, address(this), params.extraFeeReceiver);
        }

        uint256 outAmountNet = outAmountGross - totalFee;
        // Transfer to receiver
        if (params.token != NATIVE_TOKEN) {
            TransferHelper.safeTransfer(params.token, params.receiver, outAmountNet);
        } else {
            (bool success,) = params.receiver.call{value: outAmountNet}("");
            require(success, "transfer of the native token to the recipient failed");
            emit YodlNativeTokenTransfer(msg.sender, params.receiver, outAmountNet);
        }

        emit Yodl(msg.sender, params.receiver, params.token, outAmountGross, totalFee, params.memo);

        return outAmountNet;
    }
}
