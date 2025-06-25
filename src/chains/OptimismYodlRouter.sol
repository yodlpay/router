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
        YodlAcrossRouter(0x6f26Bf09B1C792e3228e5467807a900A503c0281)
        YodlCurveRouter(0x0DCDED3545D565bA3B19E683431381007245d983)
        YodlUniswapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x4200000000000000000000000000000000000006);
    }
}
