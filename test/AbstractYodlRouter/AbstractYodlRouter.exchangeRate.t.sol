// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./shared/TestableAbstractYodlRouter.t.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;
    address[2] priceFeedAddresses = [address(13480), address(13481)];
    AbstractYodlRouter.PriceFeed priceFeedBlank;

    /* 
    * Redundant. Only need 0 address, feedType 1 and 2. 3 total. Create them in TestableAbstractYodlRouter? 
    * serup like priceFeedBlank rename to reflect type (priceFeedType0, priceFeedType1 or priceFeedZERO).
    */
    AbstractYodlRouter.PriceFeed priceFeed1 = AbstractYodlRouter.PriceFeed({
        feedAddress: priceFeedAddresses[0],
        feedType: 1,
        currency: "USD",
        amount: 0,
        deadline: 0,
        signature: ""
    });

    AbstractYodlRouter.PriceFeed priceFeed2 = AbstractYodlRouter.PriceFeed({ // rename to reflect currency
        feedAddress: priceFeedAddresses[1],
        feedType: 1,
        currency: "uSDT",
        amount: 0,
        deadline: 0,
        signature: ""
    });

    function setUp() public {
        abstractRouter = new TestableAbstractYodlRouter();
        priceFeedBlank = abstractRouter.getBlankPriceFeed();
    }

    /* 
    * Scenario: No PriceFeeds are passed
    * Should return: amount (as passed to it), two zero addresses for PriceFeeds and a price array of [1, 1]
    */
    function testFuzz_ExchangeRate_NoPriceFeed(uint256 amount) public view {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors

        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedBlank, priceFeedBlank];

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount, "converted not equal to amount");
        assertEq(priceFeedsUsed[0], address(0), "priceFeedsUsed[0] not equal to address(0)");
        assertEq(priceFeedsUsed[1], address(0));
        assertEq(prices[0], int256(1));
        assertEq(prices[1], int256(1));
    }

    /* 
    * Scenario: Only PriceFeed[1] is passed
    */
    function testFuzz_ExchangeRate_OnlyPriceFeedTwo(uint256 amount) public {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedBlank, priceFeed1];

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

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, (amount * 10 ** decimals) / uint256(price), "converted not equal to expected amount");
        assertEq(prices[0], price, "prices[0] not equal to price");
        assertEq(prices[1], 0, "prices[1] != 0"); // shoud not exist
        assertEq(priceFeedsUsed[0], address(0), "priceFeedsUsed[0] not equal to address(0)");
        assertEq(priceFeedsUsed[1], priceFeeds[1].feedAddress, "priceFeedsUsed[1] not equal to priceFeedAddresses[0]");
    }

    /* 
    * Scenario: Only PriceFeed[0] is passed
    */
    function testFuzz_ExchangeRate_OnlyPriceFeedOne(uint256 amount) public {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeed1, priceFeedBlank];

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

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount * uint256(price) / 10 ** decimals, "converted not equal to expected amount");
        assertEq(prices[0], price, "prices[0] not equal to price");
        assertEq(prices[1], 0, "prices[1] != 0"); // shoud not exist
        assertEq(priceFeedsUsed[0], priceFeeds[0].feedAddress, "priceFeedsUsed[0] not equal to address(0)");
        assertEq(priceFeedsUsed[1], address(0), "priceFeedsUsed[1] not equal to priceFeedAddresses[0]");
    }

    /*
    * Scenario: Two priceFeeds are passed
    */
    function testFuzz_ExchangeRate_TwoPriceFeeds(uint256 amount) public {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeed1, priceFeed2];

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

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        uint256 expectedConverted = amount * uint256(price1) / (10 ** decimals1);
        expectedConverted = expectedConverted * (10 ** decimals2) / uint256(price2);

        assertEq(converted, expectedConverted, "converted not equal to expected amount");
        assertEq(prices[0], price1, "prices[0] not equal to price");
        assertEq(prices[1], price2, "prices[1] != 0"); // shoud not exist
        assertEq(priceFeedsUsed[0], priceFeeds[0].feedAddress, "priceFeedsUsed[0] not equal to address(0)");
        assertEq(priceFeedsUsed[1], priceFeeds[1].feedAddress, "priceFeedsUsed[1] not equal to priceFeedAddresses[0]");
    }

    /* 
    * Scenario: Only PriceFeed[0] is passed, testing all pricefeed decimals between 6-18
    * Manual fuzzing as range is small.
    */
    function testFuzz_ExchangeRate_PricefeedDecimals() public {
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeed1, priceFeedBlank];
        uint256 amount = 999;
        int256 price = 1_0657_0000; // the contract should return an int256

        // manually fuzzing
        for (uint8 decimals = 6; decimals <= 18; decimals++) {
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

            (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
                abstractRouter.exchangeRate(priceFeeds, amount);

            assertEq(converted, amount * uint256(price) / 10 ** decimals, "converted not equal to expected amount");
            assertEq(prices[0], price, "prices[0] not equal to price");
            assertEq(prices[1], 0, "prices[1] != 0"); // shoud not exist
            assertEq(priceFeedsUsed[0], priceFeeds[0].feedAddress, "priceFeedsUsed[0] not equal to address(0)");
            assertEq(priceFeedsUsed[1], address(0), "priceFeedsUsed[1] not equal to priceFeedAddresses[0]");
        }
    }
}
