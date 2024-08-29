// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;
    AbstractYodlRouter.PriceFeed priceFeedExternal;
    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedZeroValues;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
        priceFeedChainlink = abstractRouter.getPriceFeedChainlink();
        priceFeedExternal = abstractRouter.getPriceFeedExternal();
    }

    /* 
    * Scenario: No PriceFeeds are passed
    * Should return: amount (as passed to it), two zero addresses for PriceFeeds and a price array of [1, 1]
    */
    function testFuzz_ExchangeRate_NoPriceFeed(uint256 amount) public view {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors

        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedZeroValues, priceFeedZeroValues];

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount, "converted not equal to amount");
        assertEq(prices[0], int256(1));
        assertEq(prices[1], int256(1));
        assertEq(priceFeedsUsed[0], address(0), "priceFeedsUsed[0] not equal to address(0)");
        assertEq(priceFeedsUsed[1], address(0));
    }

    /* 
    * Scenario: Only PriceFeed[1] is passed
    */
    function testFuzz_ExchangeRate_OnlyPriceFeedTwo(uint256 amount) public {
        vm.assume(amount < 1e68); // prevent arithmetic overflow
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedZeroValues, priceFeedChainlink];

        /* Prepare mock data */
        uint256 decimals = 8;
        int256 price = 1_0657_0000; // the contract should return an int256

        vm.mockCall(
            priceFeeds[1].feedAddress, // priceFeeds[1] bc inverted
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeeds[1].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, 0, 0)
        );

        (uint256 converted,, int256[2] memory prices) = abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, (amount * 10 ** decimals) / uint256(price), "converted not equal to expected amount");
        assertEq(prices[0], price, "prices[0] not equal to price");
        assertEq(prices[1], 0, "prices[1] != 0"); // shoud not exist
    }

    /* 
    * Scenario: Only PriceFeed[0] is passed
    */
    function testFuzz_ExchangeRate_OnlyPriceFeedOne(uint256 amount) public {
        vm.assume(amount < 1e68); // prevent arithmetic overflow
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedChainlink, priceFeedZeroValues];

        /* Prepare mock data */
        uint256 decimals = 8;
        int256 price = 1_0657_0000; // the contract should return an int256

        vm.mockCall(
            priceFeeds[0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeeds[0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, 0, 0)
        );

        (uint256 converted,, int256[2] memory prices) = abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount * uint256(price) / 10 ** decimals, "converted not equal to expected amount");
        assertEq(prices[0], price, "prices[0] not equal to price");
        assertEq(prices[1], 0, "prices[1] != 0"); // shoud not exist
    }

    /*
    * Scenario: Two priceFeeds are passed
    */
    function testFuzz_ExchangeRate_TwoPriceFeeds(uint256 amount) public {
        vm.assume(amount < 1e68); // prevent arithmetic overflow
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedChainlink, priceFeedExternal];

        /* Prepare mock data. Numbers are mostly random */
        uint256 decimals1 = 8;
        int256 price1 = 1_0657_0000;
        uint256 decimals2 = 5;
        int256 price2 = 657_0000;

        vm.mockCall(
            priceFeeds[0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals1)
        );

        vm.mockCall(
            priceFeeds[0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price1, 0, 0, 0)
        );

        vm.mockCall(
            priceFeeds[1].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals2)
        );

        vm.mockCall(
            priceFeeds[1].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price2, 0, 0, 0)
        );

        (uint256 converted,, int256[2] memory prices) = abstractRouter.exchangeRate(priceFeeds, amount);

        uint256 expectedConverted = amount * uint256(price1) / (10 ** decimals1);
        expectedConverted = expectedConverted * (10 ** decimals2) / uint256(price2);

        assertEq(converted, expectedConverted, "converted not equal to expected amount");
        assertEq(prices[0], price1, "prices[0] not equal to price");
        assertEq(prices[1], price2, "prices[1] != 0"); // shoud not exist
    }

    /* 
    * Scenario: One Pricefeed, Pricefeed is external
    * Should default to using 18 decimals and the price given
    */
    function testFuzz_ExchangeRate_ExternalPricefeed(uint256 amount) public {
        vm.assume(amount < 1e68); // prevent arithmetic overflow
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedExternal, priceFeedZeroValues];

        abstractRouter.setMockVerifyRateSignature(true, true);

        // This did not work. Revert workaround and figure out how to mock or how to use priv key to pass verifyRateSignature
        // Mock the verifyRateSignature to return true
        // vm.mockCall(
        //     address(abstractRouter),
        //     abi.encodeWithSelector(AbstractYodlRouter.verifyRateSignature.selector), // works in minimal test
        //     abi.encode(true)
        // );

        (uint256 converted,, int256[2] memory prices) = abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount * uint256(priceFeeds[0].amount) / 10 ** 18, "converted not equal to expected amount");
        assertEq(prices[0], int256(priceFeeds[0].amount), "prices[0] not equal to price");
    }

    /* 
    * NB: May be redundant if verifyRateSignature is tested elsewhere (which is likely will)
    * Scenorio: Pricefeed[0] is external, but the signature is invalid
    */
    function q() public {
        uint256 amount = 999;
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedExternal, priceFeedZeroValues];

        vm.expectRevert("Invalid signature for external price feed");
        abstractRouter.exchangeRate(priceFeeds, amount);
    }

    /* 
    * Scenario: Only PriceFeed[0] is passed, testing all pricefeed decimals between 6-18
    * Manual fuzzing as range is small.
    */
    function testFuzz_ExchangeRate_PricefeedDecimals() public {
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedChainlink, priceFeedZeroValues];
        uint256 amount = 999;

        // manually fuzzing
        for (uint8 decimals = 6; decimals <= 18; decimals++) {
            int256 price = int256(uint256(1_0657) * uint256(decimals)); // the contract should return an int256

            vm.mockCall(
                priceFeeds[0].feedAddress,
                abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
                abi.encode(decimals)
            );

            vm.mockCall(
                priceFeeds[0].feedAddress,
                abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
                abi.encode(0, price, 0, 0, 0)
            );

            (uint256 converted,, int256[2] memory prices) = abstractRouter.exchangeRate(priceFeeds, amount);

            assertEq(converted, amount * uint256(price) / 10 ** decimals, "converted not equal to expected amount");
            assertEq(prices[0], price, "prices[0] not equal to price");
            assertEq(prices[1], 0, "prices[1] != 0");
        }
    }
}
