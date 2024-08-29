// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../AbstractYodlRouter.sol";
import "../../lib/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
import "../interfaces/IBeforeHook.sol";

abstract contract YodlUniswapRouter is AbstractYodlRouter {
    ISwapRouter02 public uniswapRouter;

    enum SwapType {
        SINGLE,
        MULTI
    }

    /// @notice Parameters for a payment through Uniswap
    struct YodlUniswapParams {
        address sender;
        address receiver;
        uint256 amountIn; // amount of tokenIn needed to satisfy amountOut
        uint256 amountOut; // The exact amount expected by merchant in tokenOut
        bytes32 memo;
        bytes path; // (address: tokenOut, uint24 poolfee, address: tokenIn) OR (address: tokenOut, uint24 poolfee2, address: tokenBase, uint24 poolfee1, tokenIn)
        PriceFeed[2] priceFeeds;
        address extraFeeReceiver;
        uint256 extraFeeBps;
        SwapType swapType;
        uint256 yd;
        // List of YApps that are allowed to be called with IBeforeHook.beforeHook extension
        YApp[] yAppList;
    }

    constructor(address _uniswapRouter) {
        uniswapRouter = ISwapRouter02(_uniswapRouter);
    }

    /// @notice Handles a payment with a swap through Uniswap
    /// @dev This needs to have a valid Uniswap router or it will revert. Excess tokens from the swap as a result
    /// of slippage are in terms of the token in.
    /// @param params Struct that contains all the relevant parameters. See `YodlUniswapParams` for more details.
    /// @return The amount spent in terms of token in by Uniswap to complete this payment
    function yodlWithUniswap(YodlUniswapParams calldata params) external payable returns (uint256) {
        require(address(uniswapRouter) != address(0), "uniswap router not present");
        (address tokenOut, address tokenIn) = decodeTokenOutTokenInUniswap(params.path, params.swapType);
        uint256 inAmount;

        // This is how much the recipient needs to receive
        uint256 outAmountGross;
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            // Convert amountOut from invoice currency to swap currency using price feed
            int256[2] memory prices;
            address[2] memory priceFeeds;
            (outAmountGross, priceFeeds, prices) = exchangeRate(params.priceFeeds, params.amountOut);
            emitConversionEvent(params.priceFeeds, prices);
        } else {
            outAmountGross = params.amountOut;
        }

        if (params.yAppList.length > 0) {
            for (uint256 i = 0; i < params.yAppList.length; i++) {
                IBeforeHook(params.yAppList[i].yApp).beforeHook(
                    tx.origin,
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
            tokenIn = address(wrappedNativeToken);
        } else {
            // Transfer the ERC20 token from the sender to the YodlRouter
            TransferHelper.safeTransferFrom(tokenIn, tx.origin, address(this), params.amountIn);
        }
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), params.amountIn);

        // Special case for when we want native token out
        bool useNativeToken = false;
        if (tokenOut == NATIVE_TOKEN) {
            useNativeToken = true;
            tokenOut = address(wrappedNativeToken);
        }

        if (params.swapType == SwapType.SINGLE) {
            IV3SwapRouter.ExactOutputSingleParams memory routerParams = IV3SwapRouter.ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: decodeSinglePoolFee(params.path),
                recipient: address(this),
                amountOut: outAmountGross,
                amountInMaximum: params.amountIn,
                sqrtPriceLimitX96: 0
            });

            outAmountNet = uniswapRouter.exactOutputSingle(routerParams);
        } else {
            // We need to extract the path details so that we can use the tokenIn value from earlier which may have been replaced by WETH
            (, uint24 poolFee2, address tokenBase, uint24 poolFee1,) =
                abi.decode(params.path, (address, uint24, address, uint24, address));

            IV3SwapRouter.ExactOutputParams memory routerParams = IV3SwapRouter.ExactOutputParams({
                path: abi.encodePacked(tokenOut, poolFee2, tokenBase, poolFee1, tokenIn),
                recipient: address(this),
                amountOut: outAmountGross,
                amountInMaximum: params.amountIn
            });

            inAmount = uniswapRouter.exactOutput(routerParams);
        }

        // Handle unwrapping wrapped native token
        if (useNativeToken) {
            // Unwrap and use NATIVE_TOKEN address as tokenOut
            IWETH9(wrappedNativeToken).withdraw(outAmountGross);
            tokenOut = NATIVE_TOKEN;
        }

        // Calculate fee from amount out
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
            (bool success,) = params.receiver.call{value: outAmountGross - totalFee}("");
            require(success, "transfer failed");
            emit YodlNativeTokenTransfer(params.sender, params.receiver, outAmountGross - totalFee);
        } else {
            // transfer tokens to receiver
            TransferHelper.safeTransfer(tokenOut, params.receiver, outAmountGross - totalFee);
        }

        emit Yodl(params.sender, params.receiver, tokenOut, outAmountGross, totalFee, params.memo);

        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), 0);

        return inAmount;
    }

    /// @notice Helper method to determine the token in and out from a Uniswap path
    /// @param path The path for a Uniswap swap
    /// @param swapType Enum for whether the swap is a single hop or multiple hop
    /// @return The tokenOut and tokenIn
    function decodeTokenOutTokenInUniswap(bytes memory path, SwapType swapType)
        internal
        pure
        returns (address, address)
    {
        address tokenOut;
        address tokenIn;
        if (swapType == SwapType.SINGLE) {
            (tokenOut,, tokenIn) = abi.decode(path, (address, uint24, address));
        } else {
            (tokenOut,,,, tokenIn) = abi.decode(path, (address, uint24, address, uint24, address));
        }
        return (tokenOut, tokenIn);
    }

    /// @notice Helper method to get the fee for a single hop swap for Uniswap
    /// @param path The path for a Uniswap swap
    /// @return The pool fee for given swap path
    function decodeSinglePoolFee(bytes memory path) internal pure returns (uint24) {
        (, uint24 poolFee,) = abi.decode(path, (address, uint24, address));
        return poolFee;
    }
}
