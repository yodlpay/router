// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
    }

    /* 
    * Fuzz test prices when using external pricefeed
    */
    function testFuzz_EmitConversionEvent_ExternalPricefeed(int256 price1, int256 price2) public {
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds =
            [abstractRouter.getPriceFeedExternal(), abstractRouter.getPriceFeedChainlink()];
        int256[2] memory prices = [price1, price2];

        /* tell foundry which event event + params to expect */
        vm.expectEmit(true, true, false, true);
        emit AbstractYodlRouter.ConvertWithExternalRate(
            priceFeeds[0].currency, priceFeeds[1].feedAddress, prices[0], prices[1]
        );

        abstractRouter.emitConversionEvent(priceFeeds, prices);
    }

    /* 
    * Fuzz test prices when using chainlink pricefeed
    */
    function testFuzz_EmitConversionEvent_ChainlinkPricefeed(int256 price1, int256 price2) public {
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds =
            [abstractRouter.getPriceFeedChainlink(), abstractRouter.getPriceFeedExternal()];
        int256[2] memory prices = [price1, price2];

        /* tell foundry which event event + params to expect */
        vm.expectEmit(true, true, false, true);
        emit AbstractYodlRouter.Convert(priceFeeds[0].feedAddress, priceFeeds[1].feedAddress, prices[0], prices[1]);

        abstractRouter.emitConversionEvent(priceFeeds, prices);
    }
}
