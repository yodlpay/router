// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;
    uint256 constant APPROX_MAX_AMOUNT = 1e68;
    // address mockWrappedNativeToken;
    // address mockYodlFeeTreasury;
    // uint256 constant YODL_FEE_BPS = 100; // 1%

    function setUp() public {
        // mockWrappedNativeToken = address(0x1);
        // mockYodlFeeTreasury = address(0x2);

        // helperContract = new AbstractYodlRouterHarness(mockWrappedNativeToken, mockYodlFeeTreasury, YODL_FEE_BPS);
        abstractRouter = new AbstractYodlRouterHarness(AbstractYodlRouter.ChainType.L1, address(0));
    }

    /* 
    * Scenario: fuzz testing amount and feeBps
    */
    function testFuzz_CalculateFee(uint256 amount, uint256 feeBps) public view {
        vm.assume(feeBps < 5000 && amount < APPROX_MAX_AMOUNT);
        assertEq(abstractRouter.calculateFee(amount, feeBps), amount * feeBps / 10000);
    }

    /* 
    * Scenario: feeBps is 0
    */
    function testFuzz_CalculateFee_FeePbsZero(uint256 amount) public view {
        uint256 feeBps = 0;
        assertEq(abstractRouter.calculateFee(amount, feeBps), 0);
    }

    /* 
    * Scenario: fee * amount < 10000 results in 0
    */
    function test_CalculateFee_ResultZero() public view {
        uint256 amount = 100; // e.g. 0.000100 USDC
        uint256 feePbs = 20; // 0.2%
        assertEq(abstractRouter.calculateFee(amount, feePbs), 0);
    }
}
