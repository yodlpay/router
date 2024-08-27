// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
    }

    /* 
    * Scenario: fuzz testing amount and feeBps
    */
    function testFuzz_TransferFee(uint256 amount, uint256 feeBps) public view {
        // set up vars
        // uint256 amount, uint256 feeBps, address token, address from, address to

        // make the call
        // abstractRouter.exposed_transferFee(amount, feeBps, token, from, to);
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
