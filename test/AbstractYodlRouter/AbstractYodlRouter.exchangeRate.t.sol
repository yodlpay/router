// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./utils/TestableAbstractYodlRouter.t.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;
    address[2] priceFeedAddresses = [address(13480), address(13481)];
    AbstractYodlRouter.PriceFeed priceFeedBlank;

    AbstractYodlRouter.PriceFeed priceFeed1 = AbstractYodlRouter.PriceFeed({
        feedAddress: priceFeedAddresses[0],
        feedType: 0,
        currency: "USD",
        amount: 0,
        deadline: 0,
        signature: ""
    });

    AbstractYodlRouter.PriceFeed priceFeed2 = AbstractYodlRouter.PriceFeed({
        feedAddress: priceFeedAddresses[0],
        feedType: 0,
        currency: "USD",
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
    function test_ExchangeRateNoPriceFeed(uint256 amount) public view {
        vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors

        AbstractYodlRouter.PriceFeed[2] memory priceFeeds = [priceFeedBlank, priceFeedBlank];

        (uint256 converted, address[2] memory priceFeedsUsed, int256[2] memory prices) =
            abstractRouter.exchangeRate(priceFeeds, amount);

        assertEq(converted, amount);
        assertEq(priceFeedsUsed[0], address(0));
        assertEq(priceFeedsUsed[1], address(0));
        assertEq(prices[0], int256(1));
        assertEq(prices[1], int256(1));
    }

    // function test_ExchangeRateSinglePriceFeed(uint256 amount) public {
    //     vm.assume(amount < 1e68); // amounts greater than this will have arithmetic overflow errors
    //     uint256 decimals = 8;
    //     int256 price = 1_0657_0000; // the contract should return an int256
    //     vm.mockCall(
    //         priceFeedAddresses[0], abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(decimals)
    //     );
    //     vm.mockCall(
    //         priceFeedAddresses[0],
    //         abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
    //         abi.encode(0, price, 0, 0, 0)
    //     );

    //     uint256 converted;

    //     address[2] memory feeds = [priceFeedAddresses[0], address(0)];

    //     int256[2] memory prices;
    //     address[2] memory priceFeeds;
    //     (converted, priceFeeds, prices) = abstractRouter.exchangeRate(feeds, amount);
    //     assertEq(converted, amount * uint256(price) / 10 ** decimals);
    //     assertEq(prices[0], price);
    //     assertEq(prices[1], 0);
    //     assertEq(priceFeeds[0], priceFeedAddresses[0]);
    //     assertEq(priceFeeds[1], address(0));
    // }

    // Your test functions go here
}
