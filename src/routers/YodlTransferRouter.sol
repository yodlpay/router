// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../AbstractYodlRouter.sol";
import "../interfaces/IBeforeHook.sol";

abstract contract YodlTransferRouter is AbstractYodlRouter {
    struct YodlTransferParams {
        // The message attached to the payment. If present, the router will take a fee.
        bytes32 memo;
        // The amount to pay before any price feeds are applied. This amount will be converted by the price feeds and then the sender will pay the converted amount in the given token.
        uint256 amount;
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
        YApp[] yAppList;
    }

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
     * @param params Struct that contains all the relevant parameters. See `YodlNativeParams` for more details.
     * @return Amount received by the receiver
     */
    function yodlWithToken(YodlTransferParams calldata params) external payable returns (uint256) {
        require(params.amount != 0, "invalid amount");

        uint256 outAmountGross = params.amount;

        // transform amount with priceFeeds
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            {
                int256[2] memory prices;
                (outAmountGross, prices) = exchangeRate(params.priceFeeds, params.amount);
                emitConversionEvent(params.priceFeeds, prices);
            }
        }

        if (params.token != NATIVE_TOKEN) {
            // ERC20 token
            require(
                IERC20(params.token).allowance(msg.sender, address(this)) >= outAmountGross, "insufficient allowance"
            );
        } else {
            // Native ether
            require(msg.value >= outAmountGross, "insufficient gas provided");
        }

        uint256 totalFee = 0;

        if (params.memo != "" || params.yAppList.length > 0) {
            totalFee += calculateFee(outAmountGross, yodlFeeBps);
        }

        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(params.extraFeeBps < MAX_EXTRA_FEE_BPS, "extraFeeBps too high");

            totalFee += transferFee(
                outAmountGross,
                params.extraFeeBps,
                params.token,
                params.token == NATIVE_TOKEN ? address(this) : msg.sender,
                params.extraFeeReceiver
            );
        }

        uint256 outAmountNet = outAmountGross - totalFee;
        if (params.yAppList.length > 0) {
            for (uint256 i = 0; i < params.yAppList.length; i++) {
                IBeforeHook(params.yAppList[i].yApp).beforeHook(
                    msg.sender,
                    params.receiver,
                    outAmountGross,
                    params.token,
                    params.yAppList[i].sessionId,
                    params.yAppList[i].payload
                );
            }
        }

        // Transfer to receiver
        if (params.token != NATIVE_TOKEN) {
            // ERC20 token
            TransferHelper.safeTransferFrom(params.token, msg.sender, params.receiver, outAmountNet);
        } else {
            // Native ether
            (bool success,) = params.receiver.call{value: outAmountNet}("");
            require(success, "transfer of the native token to the recipient failed");
            emit YodlNativeTokenTransfer(msg.sender, params.receiver, outAmountNet);
        }

        emit Yodl(msg.sender, params.receiver, params.token, outAmountGross, totalFee, params.memo);

        return outAmountNet;
    }
}
