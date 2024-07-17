// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

interface ChainalysisOracle {
    function isSanctioned(address) external view returns (bool);
}

abstract contract ChainalysisOfacExtension {
    // Mask to cover the length of "yp:ofac.eth:" (12 bytes)
    bytes32 private constant OFAC_MASK = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000);
    bytes32 private constant OFAC_PREFIX = bytes32("yp:ofac.eth:") << (8 * 20); // Shift left to position the prefix at the start of bytes32

    ChainalysisOracle public chainalysisOracle;

    constructor(address _chainalysisOracle) {
        chainalysisOracle = ChainalysisOracle(_chainalysisOracle);
    }

    function checkOfac(bytes32 memo) private view {
        // Check if the memo starts with "yp:ofac.eth:"
        if ((memo & OFAC_MASK) == OFAC_PREFIX) {
            // Extract the address part after "yp:ofac.eth:"
            // Assuming the address starts immediately after the prefix
            address extractedAddress = address(uint160(uint256(memo << (8 * 11)) >> (8 * 12)));
            require(chainalysisOracle.isSanctioned(extractedAddress) == false, "sender is sanctioned");
        }
    }
}
