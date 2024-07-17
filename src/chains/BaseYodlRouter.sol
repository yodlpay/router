// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlUniswapRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlUniswapRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlUniswapRouter(0x2626664c2603336E57B271c5C0b26F421741e481)
    {
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x46959a8a332eca1a05Bd4F18115b8F2E1C2F2f05;
        wrappedNativeToken = IWETH9(0x4200000000000000000000000000000000000006);
    }
}
