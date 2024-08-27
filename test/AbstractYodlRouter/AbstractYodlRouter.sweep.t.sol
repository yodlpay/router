// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./shared/TestableAbstractYodlRouter.t.sol";
import {IERC20} from "@openzeppelin/contracts//token/ERC20/IERC20.sol";

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
        IERC20 tokenA = IERC20(address(0x12345));
        deal(address(tokenA), address(abstractRouter), amount, true);
        uint256 treasuryTokenBalanceBefore = tokenA.balanceOf(abstractRouter.yodlFeeTreasury()); // Get the treasury balance
        console.log("treasuryTokenBalanceBefore: ", treasuryTokenBalanceBefore);

        // // Try to sweep them to the treasuryAddress
        // abstractRouter.sweep(address(tokenA));

        // // Ensure that they have successfully been transferred
        // assertEq(tokenA.balanceOf(abstractRouter.yodlFeeTreasury()), amount);
    }

    // function test_Sweep(uint256 amount) public {
    //         // Mint some tokens for the contract
    //         token.mint(address(hiroRouterV1), amount);

    //         // Try to sweep them to the treasuryAddress
    //         hiroRouterV1.sweep(address(token));

    //         // Ensure that they have successfully been transferred
    //         assertEq(token.balanceOf(address(treasuryAddress)), amount);
    //     }
}

//    function test_SweepAllowsOnlyOwnerFail() public {
//         // Mint and transfer token to YodlRouter
//         uint256 amount = 1 ether;
//         token.mint(senderAddress, amount);
//         vm.prank(senderAddress);
//         token.transfer(address(hiroRouterV1), amount);

//         vm.prank(senderAddress);
//         vm.expectRevert("Ownable: caller is not the owner");
//         hiroRouterV1.sweep(address(token));
//     }
