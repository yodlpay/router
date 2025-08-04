// SPDX-License-Identifier: BSL-1.1

// This contract is not used in production. It's sole purpose it to generate an abi with all functions in one.

pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";
import "../routers/YodlUniswapRouter.sol";
import "../routers/YodlAcrossRouter.sol";
import "../routers/YodlPancakeRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlAcrossRouter, YodlCurveRouter, YodlPancakeRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlAcrossRouter(address(0))
        YodlCurveRouter(address(0))
        YodlPancakeRouter(address(0))
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = address(0);
        wrappedNativeToken = IWETH9(address(0));
    }
}
