// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./shared/TestableAbstractYodlRouter.t.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;
    uint256 constant APPROX_MAX_AMOUNT = 1e68;
    // address mockWrappedNativeToken;
    // address mockYodlFeeTreasury;
    // uint256 constant YODL_FEE_BPS = 100; // 1%

    function setUp() public {
        // mockWrappedNativeToken = address(0x1);
        // mockYodlFeeTreasury = address(0x2);

        // helperContract = new TestableAbstractYodlRouter(mockWrappedNativeToken, mockYodlFeeTreasury, YODL_FEE_BPS);
        abstractRouter = new TestableAbstractYodlRouter();
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
    function test_CalculateFee_FeePbsZero() public view {
        uint256 amount = 1000;
        uint256 FEE_PBS = 0;
        uint256 expected = 0;
        uint256 actual = abstractRouter.calculateFee(amount, FEE_PBS);
        console.log("Expected: ", expected);
        console.log("Actual: ", actual);
        assertEq(abstractRouter.calculateFee(amount, FEE_PBS), 0);
    }
}
