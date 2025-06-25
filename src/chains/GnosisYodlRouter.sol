// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlCurveRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlCurveRouter(0x0DCDED3545D565bA3B19E683431381007245d983)
    {
        version = "v0.7";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x57A48f1C8734dE572094CA7fDC0ba7e3919067Cf;
        wrappedNativeToken = IWETH9(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d);
    }
}
