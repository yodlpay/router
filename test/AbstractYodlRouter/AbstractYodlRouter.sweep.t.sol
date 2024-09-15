// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";
import {IERC20} from "@openzeppelin/contracts//token/ERC20/IERC20.sol";
import {MyMockERC20} from "@test/AbstractYodlRouter/shared/MyMockERC20.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness(address(0));
    }

    /* 
    * Scenario: Sweep native token
    */
    function testFuzz_Sweep_Native(uint256 amount) public {
        uint256 treasuryETHBalanceBefore = abstractRouter.yodlFeeTreasury().balance; // Get the treasury balance
        vm.deal(address(abstractRouter), amount); // Give the YodlRouter some eth

        abstractRouter.sweep(abstractRouter.NATIVE_TOKEN()); // Sweep YodlRouter
        uint256 treasuryETHBalanceAfter = abstractRouter.yodlFeeTreasury().balance; // Get the new treasury balance

        assertEq(treasuryETHBalanceAfter - treasuryETHBalanceBefore, amount); // Ensure that they have successfully been transferred
    }

    /* 
    * Scenario: Sweep non-native token
    */
    function testFuzz_Sweep_Token(uint256 amount) public {
        MyMockERC20 tokenA = new MyMockERC20("MockTokenA", "MTA", 18); // Create a new token

        deal(address(tokenA), address(abstractRouter), amount, true); // Give the YodlRouter some tokens
        uint256 treasuryBalanceBefore = tokenA.balanceOf(abstractRouter.yodlFeeTreasury()); // Get the treasury balance

        abstractRouter.sweep(address(tokenA)); // Sweep YodlRouter
        uint256 treasuryBalanceAfter = tokenA.balanceOf(abstractRouter.yodlFeeTreasury()); // Get the treasury balance

        assertEq((treasuryBalanceAfter - treasuryBalanceBefore), amount);
    }
}
