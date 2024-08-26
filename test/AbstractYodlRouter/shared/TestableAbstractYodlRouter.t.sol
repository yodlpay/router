// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import "../../../lib/v3-periphery/contracts/interfaces/external/IWETH9.sol";

// Hardcode or pass constructor arguments??

contract TestableAbstractYodlRouter is AbstractYodlRouter {
    // constructor(string memory _version, address _yodlFeeTreasury, uint256 _yodlFeeBps, address _wrappedNativeToken)

    AbstractYodlRouter.PriceFeed public blankPriceFeed; // conenience var for testing purposes

    constructor() AbstractYodlRouter() {
        // version = _version;
        // yodlFeeTreasury = _yodlFeeTreasury;
        // yodlFeeBps = _yodlFeeBps;
        // wrappedNativeToken = IWETH9(_wrappedNativeToken);
        /* Value from ArbitrumOneYodlRouter.sol in old code*/
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        /* Assign '0' values to blankPriceFeed */
        blankPriceFeed = AbstractYodlRouter.PriceFeed({
            feedAddress: address(0),
            feedType: 0,
            currency: "",
            amount: 0,
            deadline: 0,
            signature: ""
        });
    }

    // Add a function to get the blankPriceFeed as a struct
    function getBlankPriceFeed() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return blankPriceFeed;
    }

    function createUSDPriceFeed(
        address feedAddress,
        int8 feedType,
        string memory currency,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public pure returns (AbstractYodlRouter.PriceFeed memory) {
        return AbstractYodlRouter.PriceFeed({
            feedAddress: feedAddress,
            feedType: feedType,
            currency: currency,
            amount: amount,
            deadline: deadline,
            signature: signature
        });
    }

    // Implement any abstract functions here if needed
}
