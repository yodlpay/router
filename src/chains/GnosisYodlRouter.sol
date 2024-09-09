// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlCurveRouter {
    constructor()
        AbstractYodlRouter(AbstractYodlRouter.ChainType.L1, address(0))
        YodlTransferRouter()
        YodlCurveRouter(0x0DCDED3545D565bA3B19E683431381007245d983)
    {
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x775aaf73a50C25eEBd308BBb9C34C73D081B423b;
        wrappedNativeToken = IWETH9(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d);
    }
}
