// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./utils/TestableAbstractYodlRouter.t.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;
    address[2] priceFeedAddresses = [address(13480), address(13481)];
    // uint256 constant APPROX_MAX_AMOUNT = 1e68;

    function setUp() public {
        abstractRouter = new TestableAbstractYodlRouter();
    }

    function test_ExchangeRate() public view {
        // vm.assume(feeBps < 5000 && amount < APPROX_MAX_AMOUNT);
        // assertEq(abstractRouter.calculateFee(amount, feeBps), amount * feeBps / 10000);
    }

    // Your test functions go here
}
