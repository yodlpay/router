// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";
import {MyMockERC20} from "@test/AbstractYodlRouter/shared/MyMockERC20.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
    }

    /* 
    * Should return 0 when calculated fee < 0. 
    * 100 * 10 / 10_000 == 0.01 - calculateFee will return 0
    */
    function test_TransferFee_CalculatedFeeIsZero() public {
        uint256 amount = 100;
        uint256 feeBps = 10; // 0.1%
        address token = abstractRouter.NATIVE_TOKEN(); // any
        address from = address(1); // any
        address to = address(2); // any

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, token, from, to);
        assertEq(fee, 0);
    }

    /* 
    * Scenario: Non-native token, from YodlRouter. Should tranfer fee from --> to
    */
    function testFuzz_TransferFee_NonNativeTokenFromContract(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);
        vm.assume(feeBps > 0 && feeBps <= 10000); // Ensure fee is between 0% and 100%

        address from = address(abstractRouter);
        address to = address(1);
        MyMockERC20 tokenA = new MyMockERC20("MockTokenA", "MTA", 18);

        deal(address(tokenA), address(abstractRouter), 1e68, true); // Give the YodlRouter some tokens
        uint256 fromBalanceBefore = tokenA.balanceOf(from);
        uint256 toBalanceBefore = tokenA.balanceOf(to);

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, address(tokenA), from, to);
        uint256 fromBalanceAfter = tokenA.balanceOf(from);
        uint256 toBalanceAfter = tokenA.balanceOf(to);

        assertEq(fromBalanceAfter, fromBalanceBefore - fee);
        assertEq(toBalanceAfter, toBalanceBefore + fee);
    }

    /* 
    * Scenario: Non-native token, from external address. Should tranfer fee from --> to
    */
    function testFuzz_TransferFee_NonNativeTokenFromOtherAddress(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);
        vm.assume(feeBps > 0 && feeBps <= 10000); // Ensure fee is between 0% and 100%

        address from = address(1);
        address to = address(2);
        MyMockERC20 tokenA = new MyMockERC20("MockTokenA", "MTA", 18);

        deal(address(tokenA), address(from), 1e68, true); // Give from address some tokens

        /* Approve tokenA spend on behalf of 'from' */
        vm.prank(from);
        tokenA.approve(address(abstractRouter), type(uint256).max);

        uint256 fromBalanceBefore = tokenA.balanceOf(from);
        uint256 toBalanceBefore = tokenA.balanceOf(to);

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, address(tokenA), from, to);

        uint256 fromBalanceAfter = tokenA.balanceOf(from);
        uint256 toBalanceAfter = tokenA.balanceOf(to);

        assertEq(fromBalanceAfter, fromBalanceBefore - fee);
        assertEq(toBalanceAfter, toBalanceBefore + fee);
    }

    /*
    * Scenario: native token, from YodlRouter. Should tranfer fee from --> to 
    */
    function testFuzz_TransferFee_NativeTokenFromContract(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);
        vm.assume(feeBps > 0 && feeBps <= 10000); // Ensure fee is between 0% and 100%

        address from = address(abstractRouter);
        address to = address(1);

        vm.deal(from, 1e68); // Give ETH to 'from'

        uint256 fromBalanceBefore = from.balance;
        uint256 toBalanceBefore = to.balance;

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, abstractRouter.NATIVE_TOKEN(), from, to);

        uint256 fromBalanceAfter = from.balance;
        uint256 toBalanceAfter = to.balance;

        assertEq(fromBalanceAfter, fromBalanceBefore - fee);
        assertEq(toBalanceAfter, toBalanceBefore + fee);
    }

    /* 
    * Scenario: native token, from external address. Shold revert with message.
    */
    function test_TransferFee_NativeTokenFromOtherAddress() public {
        /* Make sure fee is > 0, otherwise it will return 0 */
        uint256 amount = 1000;
        uint16 feeBps = 200;

        address from = address(1);
        address to = address(2);
        address tokenA = abstractRouter.NATIVE_TOKEN();

        vm.deal(from, 1e68); // Give ETH to 'from'

        uint256 fromBalanceBefore = from.balance;
        uint256 toBalanceBefore = to.balance;

        vm.expectRevert("can only transfer eth from the router address");
        abstractRouter.exposed_transferFee(amount, feeBps, tokenA, from, to);

        uint256 fromBalanceAfter = from.balance;
        uint256 toBalanceAfter = to.balance;

        assertEq(fromBalanceAfter, fromBalanceBefore, "From balance should not change");
        assertEq(toBalanceAfter, toBalanceBefore, "To balance should not change");
    }
}
