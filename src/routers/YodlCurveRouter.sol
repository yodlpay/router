// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../interfaces/ICurveRouterNG.sol";
import "../AbstractYodlRouter.sol";
import "../interfaces/IBeforeHook.sol";

abstract contract YodlCurveRouter is AbstractYodlRouter {
    ICurveRouterNG public curveRouter;

    /// @notice Parameters for a payment through Curve
    /// @dev The`route`, `swapParams` and `pools` should be determined client-side by the CurveJS client.
    struct YodlCurveParams {
        address sender;
        address receiver;
        uint256 amountIn; // amount of tokenIn needed to satisfy amountOut
        // The exact amount expected by merchant in tokenOut
        // If we are using price feeds, this is in terms of the invoice amount, but it must have the same decimals as tokenOut
        uint256 amountOut;
        bytes32 memo;
        address[11] route;
        uint256[5][5] swapParams;
        address[5] pools;
        PriceFeed[2] priceFeeds;
        address extraFeeReceiver;
        uint256 extraFeeBps;
        uint256 yd;
        // List of YApps that are allowed to be called with IBeforeHook.beforeHook extension
        YApp[] yAppList;
    }

    constructor(address _curveRouter) {
        curveRouter = ICurveRouterNG(_curveRouter);
    }

    /// @notice Handles a payment with a swap through Curve
    /// @dev This needs to have a valid Curve router or it will revert. Excess tokens from the swap as a result
    /// of slippage are in terms of the token out.
    /// @param params Struct that contains all the relevant parameters. See `YodlCurveParams` for more details.
    /// @return The amount received in terms of token out by the Curve swap
    function yodlWithCurve(YodlCurveParams calldata params) external payable returns (uint256) {
        require(address(curveRouter) != address(0), "curve router not present");
        (address tokenOut, address tokenIn) = decodeTokenOutTokenInCurve(params.route);

        // This is how much the recipient needs to receive
        uint256 outAmountGross;
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            // Convert amountOut from invoice currency to swap currency using price feed
            int256[2] memory prices;
            address[2] memory priceFeeds;
            (outAmountGross, priceFeeds, prices) = exchangeRate(params.priceFeeds, params.amountOut);
            emitConversionEvent(params.priceFeeds, prices);
        } else {
            // no conversion. tokenOut.currency matches invoiceCurrency.
            outAmountGross = params.amountOut;
        }
        if (params.yAppList.length > 0) {
            for (uint256 i = 0; i < params.yAppList.length; i++) {
                IBeforeHook(params.yAppList[i].yApp).beforeHook(
                    msg.sender,
                    params.receiver,
                    outAmountGross,
                    tokenOut,
                    params.yAppList[i].sessionId,
                    params.yAppList[i].payload
                );
            }
        }

        // There should be no other situation in which we send a transaction with native token
        if (msg.value != 0) {
            // Wrap the native token
            require(msg.value >= params.amountIn, "insufficient gas provided");
            wrappedNativeToken.deposit{value: params.amountIn}();

            // Update the tokenIn to wrapped native token
            // wrapped native token has the same number of decimals as native token
            // wrapped native token is already the first token in the route parameter
            tokenIn = address(wrappedNativeToken);
        } else {
            // Transfer the ERC20 token from the sender to the YodlRouter
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), params.amountIn);
        }
        TransferHelper.safeApprove(tokenIn, address(curveRouter), params.amountIn);

        // Make the swap - the YodlRouter will receive the tokens
        uint256 amountOut = curveRouter.exchange(
            params.route,
            params.swapParams,
            params.amountIn,
            outAmountGross, // this will revert if we do not get at least this amount
            params.pools, // this is for zap contracts
            address(this) // the Yodl router will receive the tokens
        );
        require(amountOut >= outAmountGross, "amountOut is less then outAmountGross");

        // Handle fees for the transaction - in terms out the token out
        uint256 totalFee = 0;
        if (params.memo != "" || params.yAppList.length > 0) {
            totalFee += calculateFee(outAmountGross, yodlFeeBps);
        }

        // Handle extra fees
        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(params.extraFeeBps < MAX_EXTRA_FEE_BPS, "extraFeeBps too high");

            totalFee +=
                transferFee(outAmountGross, params.extraFeeBps, tokenOut, address(this), params.extraFeeReceiver);
        }
        if (tokenOut == NATIVE_TOKEN) {
            // Handle unwrapping wrapped native token
            uint256 balance = IWETH9(wrappedNativeToken).balanceOf(address(this));
            // Unwrap and use NATIVE_TOKEN address as tokenOut
            require(balance >= outAmountGross, "Wrapped balance is less then outAmountGross");
            IWETH9(wrappedNativeToken).withdraw(balance);
            // Need to transfer native token to receiver
            (bool success,) = params.receiver.call{value: outAmountGross - totalFee}("");
            require(success, "transfer of native to receiver failed");
            emit YodlNativeTokenTransfer(params.sender, params.receiver, outAmountGross - totalFee);
        } else {
            // Transfer tokens to receiver
            TransferHelper.safeTransfer(tokenOut, params.receiver, outAmountGross - totalFee);
        }
        emit Yodl(params.sender, params.receiver, tokenOut, outAmountGross, totalFee, params.memo);

        return amountOut;
    }

    /// @notice Helper method to determine the token in and out from a Curve route
    /// @param route Route for a Curve swap in the form of [token, pool address, token...] with zero addresses once the
    /// swap has completed
    /// @return The tokenOut and tokenIn
    function decodeTokenOutTokenInCurve(address[11] memory route) internal pure returns (address, address) {
        address tokenIn = route[0];
        address tokenOut = route[2];
        // Output tokens can be located at indices 2, 4, 6 or 8, if the loop finds nothing, then it is index 2
        for (uint256 i = 5; i >= 2; i--) {
            if (route[i * 2] != address(0)) {
                tokenOut = route[i * 2];
                break;
            }
        }
        require(tokenOut != address(0), "Invalid route parameter");
        return (tokenOut, tokenIn);
    }
}
