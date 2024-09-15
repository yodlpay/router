// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ISwapRouter02} from "@uniswap/swap-router-contracts/interfaces/ISwapRouter02.sol";
import {IV3SwapRouter} from "@uniswap/swap-router-contracts/interfaces/IV3SwapRouter.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Test, console} from "forge-std/Test.sol";

import {YodlCurveRouter} from "@src/routers/YodlCurveRouter.sol";
import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlCurveRouterHarness} from "./shared/YodlCurveRouterHarness.t.sol";
import {MyMockERC20} from "@test/AbstractYodlRouter/shared/MyMockERC20.sol";

contract YodlCurveRouterTest is Test {
    YodlCurveRouterHarness public harnessRouter;
    address constant curveRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    MyMockERC20 public tokenA;
    MyMockERC20 public tokenB;
    MyMockERC20 public tokenBase;

    address extraFeeAddress;
    bytes32 defaultMemo;
    uint256 amountIn;
    uint256 amountOut;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedExternal;
    AbstractYodlRouter.PriceFeed priceFeedNULL;

    address public constant SENDER = address(1);
    address public constant RECEIVER = address(2);

    function setUp() public {
        harnessRouter = new YodlCurveRouterHarness(curveRouterAddress, address(0));
        extraFeeAddress = address(0);

        defaultMemo = "hi";
        tokenA = new MyMockERC20("Token A", "TKA", 18);
        tokenB = new MyMockERC20("Token B", "TKB", 18);
        tokenBase = new MyMockERC20("Token Base", "TBASE", 18);

        amountIn = 199 ether;
        amountOut = 90 ether;
        uint256 decimals = 8;
        int256 price = 1_0657_0000; // the contract should return an int256
        /* Fund the sender with some tokens */
        tokenA.mint(SENDER, 1000 ether);
        vm.prank(SENDER);
        tokenA.approve(address(harnessRouter), type(uint256).max);
    }

    /* Helper functions */

    function createYodlCurveParmas(bool isSingleHop) internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        address[11] memory route = [
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        uint256[5][5] memory swapParams = [
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        ];
        address[5] memory pools = [address(0), address(0), address(0), address(0), address(0)];

        return YodlCurveRouter.YodlCurveParams({
            sender: SENDER,
            receiver: RECEIVER,
            amountIn: amountIn,
            amountOut: amountOut,
            memo: defaultMemo,
            route: route,
            swapParams: swapParams,
            pools: pools,
            priceFeeds: [priceFeedNULL, priceFeedNULL],
            extraFeeReceiver: extraFeeAddress,
            extraFeeBps: 0,
            yd: 0,
            yAppList: new YodlCurveRouter.YApp[](0)
        });
    }

    /* yodlWithUniswap tests   */

    /*
     * Should revert with custom message if uniswap router is not set
     */
    function test_yodlWithCurve_NoRouter() public {
        harnessRouter.setCurveRouter(address(0));

        YodlCurveRouter.YodlCurveParams memory singleParams = createYodlCurveParmas(true);

        vm.expectRevert("curve router not present");
        harnessRouter.yodlWithCurve(singleParams);
    }

    /*
     * Single hop with 1 Chainlink price feed, USDC to tokenA, with memo
     * Tests sender balance and emissions
     * TODO: convert to fuzz - parameterize amointIn, amountOut, memo (bool + if - defautmemo else - "") , feeBps etc.
     ** This requires update to createYodlCurveParmas or deleting it and creating the struct directly in test functions.
     ** Also requires calls to exchangeRate and transferFee to get expected emit values.
     */
    // function test_yodlWithCurve_SingleHop() public {
    //     vm.mockCall(
    //         curveRouterAddress,
    //         abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector),
    //         abi.encode(amountIn)
    //     );

    //     uint256 senderBalanceBefore = tokenA.balanceOf(SENDER);
    //     YodlCurveRouter.YodlCurveParams
    //         memory yodlUniswapParams = createYodlCurveParmas(true);

    //     /*
    //      * NB: The expected values are currently hardcoded based on yodlUniswapParams values.
    //      * To make them dynamic, call exchangeRate (pricesExpected) transferFee (outAmountGrossExpected, totalFeeExpected)
    //      */
    //     int256[2] memory pricesExpected = [int256(106570000), int256(0)];
    //     uint256 outAmountGrossExpected = 95913000000000000000;
    //     uint256 totalFeeExpected = 191826000000000000;

    //     vm.expectEmit(true, true, true, true);
    //     emit AbstractYodlRouter.Convert(
    //         yodlUniswapParams.priceFeeds[0].feedAddress,
    //         yodlUniswapParams.priceFeeds[1].feedAddress,
    //         pricesExpected[0],
    //         int256(0)
    //     );

    //     vm.expectEmit(true, true, true, true);
    //     emit AbstractYodlRouter.Yodl(
    //         SENDER,
    //         RECEIVER,
    //         USDC,
    //         outAmountGrossExpected,
    //         totalFeeExpected,
    //         defaultMemo
    //     );

    //     vm.prank(SENDER, SENDER);
    //     uint256 amountSpent = harnessRouter.yodlWithUniswap(yodlUniswapParams);

    //     assertEq(
    //         senderBalanceBefore - tokenA.balanceOf(SENDER),
    //         amountIn,
    //         "Incorrect amount spent"
    //     );
    //     assertEq(amountSpent, amountIn, "Incorrect amount spent");

    //     // NB: To assert other balances we need to either mock the uniswap contract or run on forked mainnet
    // }
}
