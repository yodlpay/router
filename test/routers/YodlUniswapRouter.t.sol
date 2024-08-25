// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";

contract YodlUniswapRouterTest is Test, AbstractYodlRouter {
    AbstractYodlRouter abstractRouter;

    function setUp() public {
        // Deploy a mock implementation of AbstractYodlRouter
        abstractRouter = new AbstractYodlRouter();
    }
}
