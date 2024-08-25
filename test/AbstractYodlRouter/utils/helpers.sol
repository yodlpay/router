// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";

// /**
//  * @notice Struct to hold the price feed information, it's either Chainlink or external
//  * @param feedAddress The address of the Chainlink price feed, ZERO otherwise
//  * @param feedType The type of the price feed, 1 for Chainlink, 2 for external
//  * @param currency The currency of the price feed, if external, ZERO otherwise
//  * @param amount The amount to be converted by the price feed exchange rates, if external, ZERO otherwise
//  * @param decimals The number of decimals in the price feed, if external, ZERO otherwise
//  * @param signature The signature of the price feed, if external, ZERO otherwise
//  */
// struct PriceFeed {
//     address feedAddress;
//     int8 feedType;
//     string currency;
//     uint256 amount;
//     uint256 deadline;
//     bytes signature;
// }

function generatePriceFeed(
    address feedAddress,
    int8 feedType,
    string memory currency,
    uint256 amount,
    uint256 deadline,
    bytes memory signature
) pure returns (AbstractYodlRouter.PriceFeed memory) {
    return AbstractYodlRouter.PriceFeed({
        feedAddress: feedAddress,
        feedType: feedType,
        currency: currency,
        amount: amount,
        deadline: deadline,
        signature: signature
    });
}

// function generatePriceFeed(
//   AbstractYodlRouter.PriceFeed priceFeed,
//   uint256 price,
//   string timestamp
// ): AbstractYodlRouter.PriceFeed {
//   return {
//     ...priceFeed,
//     price,
//     timestamp
//   };
// }
