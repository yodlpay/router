// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "@src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouterL1;
    AbstractYodlRouterHarness abstractRouterL2;
    AbstractYodlRouter.PriceFeed priceFeedExternal;
    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedZeroValues;

    function setUp() public {
        abstractRouterL1 = new AbstractYodlRouterHarness(AbstractYodlRouter.ChainType.L1, address(0)); // Change later to use real address from helper config
        abstractRouterL2 = new AbstractYodlRouterHarness(AbstractYodlRouter.ChainType.L2, address(0));
        priceFeedChainlink = abstractRouterL1.getPriceFeedChainlink();
        priceFeedExternal = abstractRouterL1.getPriceFeedExternal();
    }

    /* 
    * Scenario: No PriceFeeds are passed
    * Should return: amount (as passed to it), two zero addresses for PriceFeeds and a price array of [1, 1]
    */
    function testFuzz_ExchangeRate_NoPriceFeed(uint256 amount) public view {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors

        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedZeroValues, priceFeedZeroValues];

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouterL1.exchangeRate(priceFeeds, amount);

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

        (uint256 converted,, int256[2] memory prices) = abstractRouterL1.exchangeRate(priceFeeds, amount);

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

        (uint256 converted,, int256[2] memory prices) = abstractRouterL1.exchangeRate(priceFeeds, amount);

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

        (uint256 converted,, int256[2] memory prices) = abstractRouterL1.exchangeRate(priceFeeds, amount);

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

        abstractRouterL1.setMockVerifyRateSignature(true, true);

        // This did not work. Revert workaround and figure out how to mock or how to use priv key to pass verifyRateSignature
        // Mock the verifyRateSignature to return true
        // vm.mockCall(
        //     address(abstractRouter),
        //     abi.encodeWithSelector(AbstractYodlRouter.verifyRateSignature.selector), // works in minimal test
        //     abi.encode(true)
        // );

        (uint256 converted,, int256[2] memory prices) = abstractRouterL1.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount * uint256(priceFeeds[0].amount) / 10 ** 18, "converted not equal to expected amount");
        assertEq(prices[0], int256(priceFeeds[0].amount), "prices[0] not equal to price");
    }

    /* 
    * NB: May be redundant if verifyRateSignature is tested elsewhere (which is likely will)
    * Scenorio: Pricefeed[0] is external, but the signature is invalid
    */
    function test_ExchangeRate_Revert_SignatureInvalid() public {
        uint256 amount = 999;
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedExternal, priceFeedZeroValues]; // priceFeedExternal.signature: ""

        vm.expectRevert("Invalid signature for external price feed");
        abstractRouterL1.exchangeRate(priceFeeds, amount);
    }

    /* 
    * Scenario: Only PriceFeed[0] is passed, testing pricefeed decimals between 6-18
    */
    /// forge-config: default.fuzz.runs = 100
    function testFuzz_ExchangeRate_PricefeedDecimals(uint256 decimals) public {
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedChainlink, priceFeedZeroValues];
        decimals = bound(decimals, 6, 18);
        uint256 amount = 999;
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

        (uint256 converted,, int256[2] memory prices) = abstractRouterL1.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount * uint256(price) / 10 ** decimals, "converted not equal to expected amount");
        assertEq(prices[0], price, "prices[0] not equal to price");
        assertEq(prices[1], 0, "prices[1] != 0");
    }

    /* 
    * Scenario: Chainlink price feed data is stale
    * Checks both pricefeed[0] and pricefeed[1]
    */
    function test_ExchangeRate_Revert_ChainlinkFeedDataStale() public {
        _test_ExchangeRate_Revert_ChainlinkFeedDataStale(true);
        _test_ExchangeRate_Revert_ChainlinkFeedDataStale(false);
    }

    /**
     * Helper to fuzz boolean
     */
    function _test_ExchangeRate_Revert_ChainlinkFeedDataStale(bool invertPriceFeed) public {
        /* Prepare mock data */
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [
            invertPriceFeed ? priceFeedZeroValues : priceFeedChainlink,
            invertPriceFeed ? priceFeedChainlink : priceFeedZeroValues
        ];
        uint256 amount = 0;
        uint256 decimals = 0;
        int256 price = 0;
        vm.warp(block.timestamp + 100 days);
        uint256 updateAt = block.timestamp - 99 days; // 99 days since last update

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, updateAt, 0)
        );

        /* Expect revert and execute */
        vm.expectRevert(AbstractYodlRouter.AbstractYodlRouter__PricefeedStale.selector);
        abstractRouterL1.exchangeRate(priceFeeds, amount);
    }

    /* 
    * Scenario: Chainlink L2 Sequencer is down
    * Checks both pricefeed[0] and pricefeed[1]
    */
    function test_ExchangeRate_Revert_L2SequencerDown() public {
        _test_ExchangeRate_Revert_L2SequencerDown(true);
        _test_ExchangeRate_Revert_L2SequencerDown(false);
    }

    /**
     * Helper to fuzz boolean
     */
    function _test_ExchangeRate_Revert_L2SequencerDown(bool invertPriceFeed) public {
        /* Prepare mock data */
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [
            invertPriceFeed ? priceFeedZeroValues : priceFeedChainlink,
            invertPriceFeed ? priceFeedChainlink : priceFeedZeroValues
        ];
        uint256 amount = 0;
        uint256 decimals = 0;
        int256 price = 0;
        vm.warp(block.timestamp + 100 days); // avoid arithmetic underflow
        uint256 updateAt = 0;
        int256 sequencerStatus = 1; // 0 == up, 1 == down
        uint256 startedAt = 0;

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, updateAt, 0)
        );

        // Mock the second call (sequencerUptimeFeed)
        vm.mockCall(
            address(0), // Use sequencerUptimeFeed when set up to be chain agnostic
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, sequencerStatus, startedAt, 0, 0)
        );

        /* Expect revert and execute */
        vm.expectRevert(AbstractYodlRouter.AbstractYodlRouter__SequencerDown.selector);
        abstractRouterL2.exchangeRate(priceFeeds, amount);
    }

    /* 
    * Scenario: Chainlink L2 Sequencer has not been up longer than GRACE_PERIOD_SECONDS
    * Checks both pricefeed[0] and pricefeed[1]
    */
    function test_ExchangeRate_Revert_GracePeriodNotOver() public {
        _test_ExchangeRate_Revert_GracePeriodNotOver(true);
        _test_ExchangeRate_Revert_GracePeriodNotOver(false);
    }

    /**
     * Helper to fuzz boolean
     */
    function _test_ExchangeRate_Revert_GracePeriodNotOver(bool invertPriceFeed) public {
        /* Prepare mock data */
        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [
            invertPriceFeed ? priceFeedZeroValues : priceFeedChainlink,
            invertPriceFeed ? priceFeedChainlink : priceFeedZeroValues
        ];
        uint256 amount = 0;
        uint256 decimals = 0;
        int256 price = 0;
        vm.warp(block.timestamp + 100 days); // avoid arithmetic underflow
        uint256 updateAt = 0;
        int256 sequencerStatus = 0; // 0 == up, 1 == down
        uint256 startedAt = block.timestamp - 5 minutes; // 5 mins < GRACE_PERIOD_SECONDS

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeeds[invertPriceFeed ? 1 : 0].feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, updateAt, 0)
        );

        // Mock the second call (sequencerUptimeFeed)
        vm.mockCall(
            address(0), // Use sequencerUptimeFeed when set up to be chain agnostic
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, sequencerStatus, startedAt, 0, 0)
        );

        /* Expect revert and execute */
        vm.expectRevert(AbstractYodlRouter.AbstractYodlRouter__GracePeriodNotOver.selector);
        abstractRouterL2.exchangeRate(priceFeeds, amount);
    }
}
