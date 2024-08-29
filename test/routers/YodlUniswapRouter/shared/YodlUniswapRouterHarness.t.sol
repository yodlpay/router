// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ISwapRouter02} from "swap-router-contracts/interfaces/ISwapRouter02.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlUniswapRouter} from "@src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "@test/AbstractYodlRouter/shared/AbstractYodlRouterHarness.t.sol";

contract YodlUniswapRouterHarness is YodlUniswapRouter, AbstractYodlRouterHarness {
    constructor(address _uniswapRouter) YodlUniswapRouter(_uniswapRouter) AbstractYodlRouterHarness() {
        // Additional initialization if needed
    }

    // Expose internal functions for testing
    function exposed_decodeTokenOutTokenInUniswap(bytes memory path, SwapType swapType)
        external
        pure
        returns (address, address)
    {
        return decodeTokenOutTokenInUniswap(path, swapType);
    }

    function exposed_decodeSinglePoolFee(bytes memory path) external pure returns (uint24) {
        return decodeSinglePoolFee(path);
    }

    // Mock the Uniswap router for testing
    function setMockUniswapRouter(address _mockRouter) external {
        uniswapRouter = ISwapRouter02(_mockRouter);
    }

    // Helper function to simulate a swap (to be implemented in your test file)
    function simulateSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external {
        // Implementation depends on how you want to mock the swap
        // This could involve transferring tokens, updating balances, etc.
    }

    // Override verifyRateSignature to resolve diamond inheritance
    function verifyRateSignature(PriceFeed calldata priceFeed)
        public
        view
        override(AbstractYodlRouter, AbstractYodlRouterHarness)
        returns (bool)
    {
        return AbstractYodlRouterHarness.verifyRateSignature(priceFeed);
    }

    // Add any other helper functions or state variables needed for testing
}
