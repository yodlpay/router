// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./shared/TestableAbstractYodlRouter.t.sol";
import {IERC20} from "@openzeppelin/contracts//token/ERC20/IERC20.sol";
import {MockERC20} from "./shared/MockUSDC.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;
    uint256 constant APPROX_MAX_AMOUNT = 1e68;

    function setUp() public {
        abstractRouter = new TestableAbstractYodlRouter();
    }

    // /// @notice Transfers all fees or slippage collected by the router to the treasury address
    // /// @param token The address of the token we want to transfer from the router
    // function sweep(address token) external {
    //     if (token == NATIVE_TOKEN) {
    //         // transfer native token out of contract
    //         (bool success,) = yodlFeeTreasury.call{value: address(this).balance}("");
    //         require(success, "transfer failed in sweep");
    //     } else {
    //         // transfer ERC20 contract
    //         TransferHelper.safeTransfer(token, yodlFeeTreasury, IERC20(token).balanceOf(address(this)));
    //     }
    // }

    // create test for sweep function

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
        MockERC20 tokenA = new MockERC20("MockTokenA", "MTA", 18); // Create a new token

        deal(address(tokenA), address(abstractRouter), amount, true); // Give the YodlRouter some tokens
        uint256 treasuryBalanceBefore = tokenA.balanceOf(abstractRouter.yodlFeeTreasury()); // Get the treasury balance

        abstractRouter.sweep(address(tokenA)); // Sweep YodlRouter
        uint256 treasuryBalanceAfter = tokenA.balanceOf(abstractRouter.yodlFeeTreasury()); // Get the treasury balance

        assertEq((treasuryBalanceAfter - treasuryBalanceBefore), amount);
    }
}
