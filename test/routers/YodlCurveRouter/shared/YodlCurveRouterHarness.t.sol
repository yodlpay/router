// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ICurveRouterNG} from "@src/interfaces/ICurveRouterNG.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlCurveRouter} from "@src/routers/YodlCurveRouter.sol";
import {AbstractYodlRouterHarness} from "@test/AbstractYodlRouter/shared/AbstractYodlRouterHarness.t.sol";

contract YodlCurveRouterHarness is YodlCurveRouter, AbstractYodlRouterHarness {
    constructor(AbstractYodlRouter.ChainType _chainType, address _sequencerUptimeFeed, address _curveRouter)
        YodlCurveRouter(_curveRouter)
        AbstractYodlRouterHarness(_chainType, _sequencerUptimeFeed)
    {}

    /* Override verifyRateSignature to resolve diamond inheritance */

    function verifyRateSignature(PriceFeed calldata priceFeed)
        public
        view
        override(AbstractYodlRouter, AbstractYodlRouterHarness)
        returns (bool)
    {
        return AbstractYodlRouterHarness.verifyRateSignature(priceFeed);
    }

    /* Helper functions */

    function setCurveRouter(address _newCurveRouter) external {
        curveRouter = ICurveRouterNG(_newCurveRouter);
    }
}
