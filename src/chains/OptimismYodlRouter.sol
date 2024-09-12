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
        YodlCurveRouter(0x0DCDED3545D565bA3B19E683431381007245d983)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x4200000000000000000000000000000000000006);
    }
}
