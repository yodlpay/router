// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlCurveRouter {
    constructor()
        AbstractYodlRouter()
        YodlTransferRouter()
        YodlCurveRouter(0xE6358f6a45B502477e83CC1CDa759f540E4459ee)
    {
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x775aaf73a50C25eEBd308BBb9C34C73D081B423b;
        wrappedNativeToken = IWETH9(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d);
    }
}
