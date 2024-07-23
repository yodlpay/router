// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../interfaces/IBeforeHook.sol";

interface ChainalysisOracle {
    function isSanctioned(address) external view returns (bool);
}

contract ChainalysisOfacExtension is IBeforeHook {
    ChainalysisOracle public chainalysisOracle;

    constructor(address _chainalysisOracle) {
        chainalysisOracle = ChainalysisOracle(_chainalysisOracle);
    }

    function beforeHook(address sender, address, uint256, address, uint256, bytes[] calldata)
        external
        view
        override
        returns (uint256)
    {
        require(chainalysisOracle.isSanctioned(sender) == false, "sender is sanctioned");
        return 0;
    }
}
