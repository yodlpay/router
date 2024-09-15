// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlUniswapRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlUniswapRouter, YodlCurveRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlUniswapRouter(0x2626664c2603336E57B271c5C0b26F421741e481)
        YodlCurveRouter(0x4f37A9d177470499A2dD084621020b023fcffc1F)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x46959a8a332eca1a05Bd4F18115b8F2E1C2F2f05;
        wrappedNativeToken = IWETH9(0x4200000000000000000000000000000000000006);
        sequencerUptimeFeed = 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433;
    }
}
