// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";
import "../routers/YodlUniswapRouter.sol";
import "../routers/YodlAcrossRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlAcrossRouter, YodlCurveRouter, YodlUniswapRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlAcrossRouter(0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5)
        YodlCurveRouter(0x16C6521Dff6baB339122a0FE25a9116693265353)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x57A48f1C8734dE572094CA7fDC0ba7e3919067Cf; // fees.yodl.eth
        wrappedNativeToken = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }
}
