// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";
import "../routers/YodlUniswapRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlCurveRouter, YodlUniswapRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlCurveRouter(0x2a426b3Bb4fa87488387545f15D01d81352732F9)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    }
}
