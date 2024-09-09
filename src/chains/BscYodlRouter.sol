// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../routers/YodlTransferRouter.sol";
import "../routers/YodlPancakeRouter.sol";
import "../routers/YodlCurveRouter.sol";

contract YodlRouter is YodlTransferRouter, YodlCurveRouter, YodlPancakeRouter {
    constructor()
        AbstractYodlRouter(AbstractYodlRouter.ChainType.L1, address(0))
        YodlTransferRouter()
        YodlCurveRouter(0xA72C85C258A81761433B4e8da60505Fe3Dd551CC)
        YodlPancakeRouter(0x13f4EA83D0bd40E75C8222255bc855a974568Dd4)
    {
        version = "vSam";
        yodlFeeBps = 20;
        yodlFeeTreasury = 0x698609f1ae8E0ce7e65d3028d1f00297A6bF21e5;
        wrappedNativeToken = IWETH9(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    }
}
