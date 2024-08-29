// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";

import "../AbstractYodlRouter.sol";
import "../../lib/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
import "../interfaces/IBeforeHook.sol";

abstract contract YodlUniswapRouter is AbstractYodlRouter, Test {
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
        console.log("01");
        require(address(uniswapRouter) != address(0), "uniswap router not present");
        console.log("02");
        (address tokenOut, address tokenIn) = decodeTokenOutTokenInUniswap(params.path, params.swapType);
        console.log("03");
        uint256 amountSpent;

        console.log("1");

        // This is how much the recipient needs to receive
        uint256 amountOutExpected;
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            console.log("2");
            // Convert amountOut from invoice currency to swap currency using price feed
            int256[2] memory prices;
            address[2] memory priceFeeds;

            console.log("params.priceFeeds: ", params.priceFeeds[0].feedAddress);
            console.log("params.amountOut: ", params.amountOut);
            (amountOutExpected, priceFeeds, prices) = exchangeRate(params.priceFeeds, params.amountOut);
            console.log("3");
            emitConversionEvent(params.priceFeeds, prices);
            console.log("4");
        } else {
            amountOutExpected = params.amountOut;
        }
        if (params.yAppList.length > 0) {
            for (uint256 i = 0; i < params.yAppList.length; i++) {
                IBeforeHook(params.yAppList[i].yApp).beforeHook(
                    tx.origin,
                    params.receiver,
                    amountOutExpected,
                    tokenOut,
                    params.yAppList[i].sessionId,
                    params.yAppList[i].payload
                );
            }
        }
        console.log("5");

        // There should be no other situation in which we send a transaction with native token
        if (msg.value != 0) {
            console.log("6");
            // Wrap the native token
            require(msg.value >= params.amountIn, "insufficient gas provided");
            wrappedNativeToken.deposit{value: params.amountIn}();
            console.log("7");

            // Update the tokenIn to wrapped native token
            tokenIn = address(wrappedNativeToken);
        } else {
            console.log("8");
            console.log("tx.origin", tx.origin);
            console.log("params.sender", params.sender);
            // Transfer the ERC20 token from the sender to the YodlRouter
            TransferHelper.safeTransferFrom(tokenIn, tx.origin, address(this), params.amountIn);
            console.log("9");
        }
        console.log("10");
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), params.amountIn);
        console.log("11");

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
                amountOut: amountOutExpected,
                amountInMaximum: params.amountIn,
                sqrtPriceLimitX96: 0
            });

            console.log("12"); // HERE

            console.log("uniswapRouter address: ", address(uniswapRouter));
            amountSpent = uniswapRouter.exactOutputSingle(routerParams);
            console.log("amountSpent", amountSpent);

            // Check the balance of tokenOut after the swap
            uint256 balanceAfterSwap1 = IERC20(tokenIn).balanceOf(address(this));
            console.log("Balance of tokenIn after swap", balanceAfterSwap1);
            uint256 balanceAfterSwap = IERC20(tokenOut).balanceOf(address(this));
            console.log("Balance of tokenOut after swap", balanceAfterSwap);
            console.log("13");
        } else {
            // We need to extract the path details so that we can use the tokenIn value from earlier which may have been replaced by WETH
            console.log("14");
            (, uint24 poolFee2, address tokenBase, uint24 poolFee1,) =
                abi.decode(params.path, (address, uint24, address, uint24, address));
            console.log("15");

            IV3SwapRouter.ExactOutputParams memory routerParams = IV3SwapRouter.ExactOutputParams({
                path: abi.encodePacked(tokenOut, poolFee2, tokenBase, poolFee1, tokenIn),
                recipient: address(this),
                amountOut: amountOutExpected,
                amountInMaximum: params.amountIn
            });

            console.log("16");
            amountSpent = uniswapRouter.exactOutput(routerParams);
            console.log("17");
        }

        // Handle unwrapping wrapped native token
        if (useNativeToken) {
            // Unwrap and use NATIVE_TOKEN address as tokenOut
            console.log("18");
            IWETH9(wrappedNativeToken).withdraw(amountOutExpected);
            tokenOut = NATIVE_TOKEN;
            console.log("19");
        }

        // Calculate fee from amount out
        uint256 totalFee = 0;
        if (params.memo != "") {
            console.log("20");
            string memory memoString = string(abi.encodePacked(params.memo));
            console.log("params.memo as string", memoString);
            totalFee += calculateFee(amountOutExpected, yodlFeeBps);
            console.log("21");
        }

        // Handle extra fees
        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            console.log("22");
            require(params.extraFeeBps < MAX_EXTRA_FEE_BPS, "extraFeeBps too high");

            totalFee +=
                transferFee(amountOutExpected, params.extraFeeBps, tokenOut, address(this), params.extraFeeReceiver);
            console.log("23");
        }

        if (tokenOut == NATIVE_TOKEN) {
            console.log("24");
            (bool success,) = params.receiver.call{value: amountOutExpected - totalFee}("");
            console.log("25");
            require(success, "transfer failed");
            emit YodlNativeTokenTransfer(params.sender, params.receiver, amountOutExpected - totalFee);
        } else {
            // transfer tokens to receiver
            console.log("26");
            TransferHelper.safeTransfer(tokenOut, params.receiver, amountOutExpected - totalFee);
            console.log("27");
        }

        console.log("28");
        emit Yodl(params.sender, params.receiver, tokenOut, amountOutExpected, totalFee, params.memo);

        console.log("29");
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), 0);
        console.log("30");

        return amountSpent;
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
