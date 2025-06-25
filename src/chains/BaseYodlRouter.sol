// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlExternalFundingRouter.sol";
import "../routers/YodlUniswapRouter.sol";
import "../routers/YodlAcrossRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is
    YodlTransferRouter,
    YodlExternalFundingRouter,
    YodlAcrossRouter,
    YodlUniswapRouter,
    YodlCurveRouter
{
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlExternalFundingRouter()
        YodlAcrossRouter(0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64)
        YodlUniswapRouter(0x2626664c2603336E57B271c5C0b26F421741e481)
        YodlCurveRouter(0x4f37A9d177470499A2dD084621020b023fcffc1F)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x57A48f1C8734dE572094CA7fDC0ba7e3919067Cf;
        wrappedNativeToken = IWETH9(0x4200000000000000000000000000000000000006);
    }
}
