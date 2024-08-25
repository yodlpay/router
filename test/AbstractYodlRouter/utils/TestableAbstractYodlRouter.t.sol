// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import "../../../lib/v3-periphery/contracts/interfaces/external/IWETH9.sol";

contract TestableAbstractYodlRouter is AbstractYodlRouter {
    constructor(string memory _version, address _yodlFeeTreasury, uint256 _yodlFeeBps, address _wrappedNativeToken) {
        version = _version;
        yodlFeeTreasury = _yodlFeeTreasury;
        yodlFeeBps = _yodlFeeBps;
        wrappedNativeToken = IWETH9(_wrappedNativeToken);
    }

    // Implement any abstract functions here if needed
}
