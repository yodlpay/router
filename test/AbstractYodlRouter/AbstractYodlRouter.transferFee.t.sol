// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";
import {MockERC20} from "./shared/MockUSDC.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
    }

    // Cases:
    // 1. mock fee < 0 should return 0 (done)
    // 2. non-native token, from address(this) should safeTransfer (check balances)
    // 3. non-native token, from != address(this) should safeTransferFrom (check balances)
    // 4. native token, from address(this) should call{value: fee} (check balances) and not revert
    // 5. native token, from != address(this) should revert
    // 6. (maybe) non-native token, from != address(this) should revert
    // NB fee should be returned in all success cases
    /* 
    

    /* 
    * Scenario: calculated fee is less than 0. Should return 0.
    * NB: 100 * 10 / 10_000 == 0.01 - calculateFee will return 0
    */
    function test_TransferFee_CalculatedFeeIsZero() public {
        uint256 amount = 100;
        uint256 feeBps = 10; // 0.1%
        // address token = abstractRouter.NATIVE_TOKEN(); // could be any in this case
        address token = abstractRouter.NATIVE_TOKEN(); // could be any in this case
        address from = address(this); // any
        address to = address(0xdead); // any

        uint256 res = abstractRouter.exposed_transferFee(amount, feeBps, token, from, to);
        assertEq(res, 0);
    }

    /* 
    * Scenario: Non-native token, from address(this) should safeTransfer (check balances)
    * NB: feeBps can go up to ~600 % in this test.
    */
    function testFuzz_TransferFee_NonNativeTokenFromContract(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);

        address from = address(abstractRouter);
        address to = address(0xdead); // any
        MockERC20 tokenA = new MockERC20("MockTokenA", "MTA", 18); // Create a new token

        deal(address(tokenA), address(abstractRouter), 1e68, true); // Give the YodlRouter some tokens
        uint256 toBalanceBefore = tokenA.balanceOf(to); // Get the user (to) balance

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, address(tokenA), from, to);
        uint256 toBalanceAfter = tokenA.balanceOf(to); // Get the user balance again

        // Also check baklance of conttract befire/after
        assertEq(toBalanceAfter, toBalanceBefore + fee);
    }

    /* 
    * Scenario: Non-native token, from address(this) should safeTransfer (check balances)
    * NB: feeBps can go up to ~600 % in this test.
    */
    function testFuzz_TransferFee_NonNativeTokenFromOtherAddress(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);

        address from = address(0x12345); // any
        address to = address(0xdead); // any
        MockERC20 tokenA = new MockERC20("MockTokenA", "MTA", 18); // Create a new token

        /* Approve tokenA spend on behalf of from */
        vm.prank(from);
        tokenA.approve(address(abstractRouter), type(uint256).max);

        deal(address(tokenA), address(from), 1e68, true); // Give from address some tokens
        uint256 fromBalanceBefore = tokenA.balanceOf(from); 
        uint256 toBalanceBefore = tokenA.balanceOf(to); 

        uint256 fee = abstractRouter.exposed_transferFee(amount, feeBps, address(tokenA), from, to);
        uint256 fromBalanceAfter = tokenA.balanceOf(from); 
        uint256 toBalanceAfter = tokenA.balanceOf(to); 

        assertEq(fromBalanceAfter, fromBalanceBefore - fee);
        assertEq(toBalanceAfter, toBalanceBefore + fee);
    }

    /* 
    * Scenario: Non-native token, from address(this) should safeTransfer (check balances)
    * NB: feeBps can go up to ~600 % in this test.
    */
    function testFuzz_TransferFee_NativeTokenFromOtherAddress(uint256 amount, uint16 feeBps) public {
        vm.assume(amount < 1e68);

        address from = address(0x12345); // any
        address to = address(0xdead); // any
        MockERC20 tokenA = new MockERC20("MockTokenA", "MTA", 18); // Create a new token

        deal(address(tokenA), address(from), 1e68, true); // Give the YodlRouter some tokens
        uint256 userBalanceBefore = tokenA.balanceOf(to); // Get the user (to) balance

        // vm.expectRevert("can only transfer eth from the router address");
        abstractRouter.exposed_transferFee(amount, feeBps, address(tokenA), from, to);
        uint256 userBalanceAfter = tokenA.balanceOf(to); // Get the user balance again

        assertEq(userBalanceAfter, userBalanceBefore);
    }
}

//     /// @notice Calculates and transfers fee directly from an address to another
//     /// @dev This can be used for directly transferring the Yodl fee from the sender to the treasury, or transferring
//     /// the extra fee to the extra fee receiver.
//     /// @param amount Amount from which to calculate the fee
//     /// @param feeBps The size of the fee in basis points
//     /// @param token The token which is being used to pay the fee. Can be an ERC20 token or the native token
//     /// @param from The address from which we are transferring the fee
//     /// @param to The address to which the fee will be sent
//     /// @return The fee sent
//     function transferFee(uint256 amount, uint256 feeBps, address token, address from, address to)
//         internal
//         returns (uint256)
//     {
//         uint256 fee = calculateFee(amount, feeBps);
//         if (fee > 0) {
//             if (token != NATIVE_TOKEN) {
//                 // ERC20 token
//                 if (from == address(this)) {
//                     TransferHelper.safeTransfer(token, to, fee);
//                 } else {
//                     // safeTransferFrom requires approval
//                     TransferHelper.safeTransferFrom(token, from, to, fee);
//                 }
//             } else {
//                 require(from == address(this), "can only transfer eth from the router address");

//                 // Native ether
//                 (bool success,) = to.call{value: fee}("");
//                 require(success, "transfer failed in transferFee");
//             }
//             return fee;
//         } else {
//             return 0;
//         }
//     }
