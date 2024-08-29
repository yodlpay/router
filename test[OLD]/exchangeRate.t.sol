// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../src/AbstractYodlRouter.sol";
import "../src/chains/EthereumYodlRouter.sol";

contract YodlRouterV1Test is Test {
    YodlRouter yodlRouter;
    YodlRouter.PriceFeed nullFeed;

    function setUp() public {
        nullFeed = AbstractYodlRouter.PriceFeed({
            feedAddress: address(0),
            feedType: 0,
            currency: "",
            amount: 0,
            deadline: 0,
            signature: ""
        });
        yodlRouter = new YodlRouter();
    }

    // test..Scenarios are useful for --gas-reports

    function test_ExchangeRateWithNullFeeds() public {
        (uint256 converted, int256[2] memory prices) = yodlRouter.exchangeRate(
            [nullFeed, nullFeed],
            1000000
        );

        assertEq(converted, 1000000);
    }

    function test_ExchangeRateWithPriceFeeds() public {
        address priceFeedAddress = address(12345);
        address[2] memory feeds = [priceFeedAddress, address(0)];

        vm.mockCall(
            priceFeedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(8)
        );
        vm.mockCall(
            priceFeedAddress,
            abi.encodeWithSelector(
                AggregatorV3Interface.latestRoundData.selector
            ),
            abi.encode(0, 1_06_570_000, 0, 0, 0)
        );

        uint256 amount = 20000000;
        AbstractYodlRouter.PriceFeed memory pf0 = AbstractYodlRouter.PriceFeed({
            feedAddress: address(12345),
            feedType: 1,
            currency: "",
            amount: 0,
            deadline: 0,
            signature: ""
        });
        (uint256 converted, int256[2] memory prices) = yodlRouter.exchangeRate(
            [pf0, nullFeed],
            20000000
        );

        assertEq(converted, 2 * 10657000);
    }

    function test_ExchangeRateWithPriceFeedsInverse() public {
        address priceFeedAddress = address(12345);
        address[2] memory feeds = [priceFeedAddress, address(0)];

        vm.mockCall(
            priceFeedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(8)
        );
        vm.mockCall(
            priceFeedAddress,
            abi.encodeWithSelector(
                AggregatorV3Interface.latestRoundData.selector
            ),
            abi.encode(0, 1_06570000, 0, 0, 0)
        );

        uint256 amount = 20000000;
        AbstractYodlRouter.PriceFeed memory pf = AbstractYodlRouter.PriceFeed({
            feedAddress: address(12345),
            feedType: 1,
            currency: "",
            amount: 0,
            deadline: 0,
            signature: ""
        });
        (uint256 converted, int256[2] memory prices) = yodlRouter.exchangeRate(
            [nullFeed, pf],
            20000000
        );

        assertEq(converted, 18767007);
    }
}
