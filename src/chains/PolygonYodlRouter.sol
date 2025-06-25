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
        YodlAcrossRouter(0x9295ee1d8C5b022Be115A2AD3c30C72E34e7F096)
        YodlCurveRouter(0x0DCDED3545D565bA3B19E683431381007245d983)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x57A48f1C8734dE572094CA7fDC0ba7e3919067Cf;
        wrappedNativeToken = IWETH9(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    }
}
