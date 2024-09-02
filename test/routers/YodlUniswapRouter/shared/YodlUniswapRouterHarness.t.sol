// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ISwapRouter02} from "swap-router-contracts/interfaces/ISwapRouter02.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlUniswapRouter} from "@src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "@test/AbstractYodlRouter/shared/AbstractYodlRouterHarness.t.sol";

contract YodlUniswapRouterHarness is YodlUniswapRouter, AbstractYodlRouterHarness {
    constructor(address _uniswapRouter) YodlUniswapRouter(_uniswapRouter) AbstractYodlRouterHarness() {}

    /* Expose internal functions for testing */
    function exposed_decodeTokenOutTokenInUniswap(bytes memory path, SwapType swapType)
        external
        pure
        returns (address, address)
    {
        return decodeTokenOutTokenInUniswap(path, swapType);
    }

    /* Expose internal functions */

    function exposed_decodeSinglePoolFee(bytes memory path) external pure returns (uint24) {
        return decodeSinglePoolFee(path);
    }

    /* Override verifyRateSignature to resolve diamond inheritance */

    function verifyRateSignature(PriceFeed calldata priceFeed)
        public
        view
        override(AbstractYodlRouter, AbstractYodlRouterHarness)
        returns (bool)
    {
        return AbstractYodlRouterHarness.verifyRateSignature(priceFeed);
    }

    /* Helper functions */

    function setUniswapRouter(address _newUniswapRouter) external {
        uniswapRouter = ISwapRouter02(_newUniswapRouter);
    }
}
