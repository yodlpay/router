// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ISwapRouter02} from "@uniswap/swap-router-contracts/interfaces/ISwapRouter02.sol";
import {IV3SwapRouter} from "@uniswap/swap-router-contracts/interfaces/IV3SwapRouter.sol";
import {AggregatorV3Interface} from "chainlink/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Test, console} from "forge-std/Test.sol";

import {YodlUniswapRouter} from "@src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {MockERC20} from "@test/AbstractYodlRouter/shared/MockERC20.sol";
import {YodlUniswapRouterHarness} from "./shared/YodlUniswapRouterHarness.t.sol";

contract YodlUniswapRouterTest is Test {
    YodlUniswapRouterHarness public harnessRouter;
    address constant uniswapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockERC20 public tokenBase;
    address extraFeeAddress;
    bytes32 defaultMemo;
    uint24 poolFee;
    uint256 amountIn;
    uint256 amountOut;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedExternal;
    AbstractYodlRouter.PriceFeed priceFeedNULL;

    address public constant SENDER = address(1);
    address public constant RECEIVER = address(2);

    function setUp() public {
        harnessRouter = new YodlUniswapRouterHarness(uniswapRouterAddress);
        extraFeeAddress = address(0);
        defaultMemo = "hi";
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);
        tokenBase = new MockERC20("Token Base", "TBASE", 18);
        poolFee = uint24(3000); // 3%
        amountIn = 199 ether;
        amountOut = 90 ether;
        uint256 decimals = 8;
        int256 price = 1_0657_0000; // the contract should return an int256

        priceFeedChainlink = harnessRouter.getPriceFeedChainlink();
        priceFeedExternal = harnessRouter.getPriceFeedExternal();

        /* Fund the sender with some tokens */
        tokenA.mint(SENDER, 1000 ether);
        vm.prank(SENDER);
        tokenA.approve(address(harnessRouter), type(uint256).max);

        /* Mocks for calling yodlWithUniswap */

        vm.mockCall(
            priceFeedChainlink.feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.decimals.selector),
            abi.encode(decimals)
        );

        vm.mockCall(
            priceFeedChainlink.feedAddress,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, price, 0, 0, 0)
        );
    }

    /* Helper functions */

    function createYodlUniswapParams(bool isSingleHop)
        internal
        view
        returns (YodlUniswapRouter.YodlUniswapParams memory)
    {
        bytes memory path;
        YodlUniswapRouter.SwapType swapType;

        if (isSingleHop) {
            path = abi.encode(USDC, poolFee, address(tokenA));
            swapType = YodlUniswapRouter.SwapType.SINGLE;
        } else {
            path = abi.encode(USDC, poolFee, address(tokenBase), poolFee, address(tokenA));
            swapType = YodlUniswapRouter.SwapType.MULTI;
        }

        return YodlUniswapRouter.YodlUniswapParams({
            sender: SENDER,
            receiver: RECEIVER,
            amountIn: amountIn,
            amountOut: amountOut,
            memo: defaultMemo,
            path: path,
            priceFeeds: [priceFeedChainlink, priceFeedNULL],
            extraFeeReceiver: extraFeeAddress,
            extraFeeBps: 0,
            swapType: swapType,
            yd: 0,
            yAppList: new YodlUniswapRouter.YApp[](0)
        });
    }

    /* Test functions */

    /* 
    * Should revert with custom message if uniswap router is not set
    */
    function test_NoUniswapRouter() public {
        harnessRouter.setUniswapRouter(address(0));

        YodlUniswapRouter.YodlUniswapParams memory singleParams = createYodlUniswapParams(true);

        vm.expectRevert("uniswap router not present");
        harnessRouter.yodlWithUniswap(singleParams);
    }

    /* 
    * Single hop with 1 Chainlink price feed, USDC to tokenA
    */
    function test_yodlWithUniswap_SingleHop() public {
        vm.mockCall(
            uniswapRouterAddress, abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector), abi.encode(amountIn)
        );

        uint256 senderBalanceBefore = tokenA.balanceOf(SENDER);

        YodlUniswapRouter.YodlUniswapParams memory singleParams = createYodlUniswapParams(true);

        /* 
        * NB: The expected values are currently hardcoded based on singleParams values.
        * To make them dynamic, call exchangeRate (pricesExpected) transferFee (outAmountGrossExpected, totalFeeExpected)
        */
        int256[2] memory pricesExpected = [int256(106570000), int256(0)];
        uint256 outAmountGrossExpected = 95913000000000000000;
        uint256 totalFeeExpected = 191826000000000000;

        vm.expectEmit(true, true, true, true);
        emit AbstractYodlRouter.Convert(
            singleParams.priceFeeds[0].feedAddress, singleParams.priceFeeds[1].feedAddress, pricesExpected[0], int256(0)
        );

        vm.expectEmit(true, true, true, true);
        emit AbstractYodlRouter.Yodl(SENDER, RECEIVER, USDC, outAmountGrossExpected, totalFeeExpected, defaultMemo);

        vm.prank(SENDER, SENDER);
        uint256 amountSpent = harnessRouter.yodlWithUniswap(singleParams);

        assertEq(senderBalanceBefore - tokenA.balanceOf(SENDER), amountIn, "Incorrect amount spent");
        assertEq(amountSpent, amountIn, "Incorrect amount spent");

        // NB: To assert other balances we need to either mock the uniswap contract or run on forked mainnet
    }

    function test_decodeTokenOutTokenInUniswap() public view {
        /* Test single hop */
        bytes memory singleHopPath = abi.encode(address(tokenB), uint24(3000), address(tokenA));

        (address outToken, address inToken) =
            harnessRouter.exposed_decodeTokenOutTokenInUniswap(singleHopPath, YodlUniswapRouter.SwapType.SINGLE);

        assertEq(outToken, address(tokenB), "Incorrect tokenOut for single hop");
        assertEq(inToken, address(tokenA), "Incorrect tokenIn for single hop");

        /* Test multihop */
        bytes memory multiHopPath =
            abi.encode(address(tokenB), uint24(3000), address(tokenBase), uint24(500), address(tokenA));

        (outToken, inToken) =
            harnessRouter.exposed_decodeTokenOutTokenInUniswap(multiHopPath, YodlUniswapRouter.SwapType.MULTI);

        assertEq(outToken, address(tokenB), "Incorrect tokenOut for multi hop");
        assertEq(inToken, address(tokenA), "Incorrect tokenIn for multi hop");
    }

    function test_decodeSinglePoolFee() public view {
        bytes memory path = abi.encode(address(tokenB), uint24(3000), address(tokenA));
        uint24 fee = harnessRouter.exposed_decodeSinglePoolFee(path);

        assertEq(fee, 3000, "Incorrect pool fee decoded");
    }
}
