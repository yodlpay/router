// // SPDX-License-Identifier: GPL-2.0-or-later
// pragma solidity ^0.8.26;

// import {SwapRouter02} from "@uniswap/swap-router-contracts/SwapRouter02.sol";

// contract MockUniswapRouter is SwapRouter02 {
//     uint256 private _amountSpent;

//     constructor(IPoolInitializer _poolInitializer, IApproveAndCall _ApproveAndCall)
//         SwapRouter02(_poolInitializer, _ApproveAndCall)
//     {}

//     // function setAmountSpent(uint256 amount) external {
//     //     _amountSpent = amount;
//     // }

//     // // Override only the functions you need for your tests
//     // function exactOutputSingle(ExactOutputSingleParams calldata params)
//     //     external
//     //     payable
//     //     override
//     //     returns (uint256 amountIn)
//     // {
//     //     return _amountSpent;
//     // }

//     // function exactOutput(ExactOutputParams calldata params) external payable override returns (uint256 amountIn) {
//     //     return _amountSpent;
//     // }

//     // You can override more functions as needed for your tests
// }
