// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlExternalFundingRouter.sol";
import "../routers/YodlCurveRouter.sol";
import "../routers/YodlUniswapRouter.sol";
import "../routers/YodlAcrossRouter.sol";

contract YodlRouter is
    YodlTransferRouter,
    YodlExternalFundingRouter,
    YodlAcrossRouter,
    YodlCurveRouter,
    YodlUniswapRouter
{
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlExternalFundingRouter()
        YodlAcrossRouter(0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A)
        YodlCurveRouter(0x2191718CD32d02B8E60BAdFFeA33E4B5DD9A0A0D)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    }
}
