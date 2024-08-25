// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import "../../../lib/v3-periphery/contracts/interfaces/external/IWETH9.sol";

contract TestableAbstractYodlRouter is AbstractYodlRouter {
    constructor(string memory _version, address _yodlFeeTreasury, uint256 _yodlFeeBps, address _wrappedNativeToken)
        AbstractYodlRouter()
    {
        version = _version;
        yodlFeeTreasury = _yodlFeeTreasury;
        yodlFeeBps = _yodlFeeBps;
        wrappedNativeToken = IWETH9(_wrappedNativeToken);
        /* ArbitrumOneYodlRouter.sol */
        // version = "vSam";
        // yodlFeeBps = 20;
        // yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        // wrappedNativeToken = IWETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    }

    // Implement any abstract functions here if needed
}
