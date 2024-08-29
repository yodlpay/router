// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

// import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import {ISwapRouter02, IV3SwapRouter} from "@uniswap/swap-router-contracts//interfaces/ISwapRouter02.sol";
import {IV3SwapRouter} from "@uniswap/swap-router-contracts//interfaces/ISwapRouter02.sol";
import "@uniswap/swap-router-contracts//interfaces/ISwapRouter02.sol";
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
    address treasuryAddress;
    address senderAddress;
    address extraFeeAddress;
    uint256 baseFeeBps;
    bytes32 defaultMemo;
    uint24 poolFee;
    uint256 amountIn;
    uint256 amountOut;
    // YodlUniswapRouter.YodlUniswapParams singleParams;
    YodlUniswapRouter.YodlUniswapParams multiParams;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedExternal;
    AbstractYodlRouter.PriceFeed priceFeedNULL;

    address public constant SENDER = address(1);
    address public constant RECEIVER = address(2);

    function setUp() public {
        harnessRouter = new YodlUniswapRouterHarness(uniswapRouterAddress);
        baseFeeBps = 25;
        treasuryAddress = address(123);
        extraFeeAddress = address(0);
        defaultMemo = "hi";
        tokenA = new MockERC20("Token A", "TKA", 18);
        tokenB = new MockERC20("Token B", "TKB", 18);
        tokenBase = new MockERC20("Token Base", "TBASE", 18);
        poolFee = uint24(3000); // 3%
        amountIn = 199 ether;
        amountOut = 90 ether;

        priceFeedChainlink = harnessRouter.getPriceFeedChainlink();
        priceFeedExternal = harnessRouter.getPriceFeedExternal();

        // Fund the sender with some tokens
        tokenA.mint(SENDER, 1000 ether);
        vm.prank(SENDER);
        tokenA.approve(address(harnessRouter), type(uint256).max);

        vm.mockCall(
            uniswapRouterAddress, abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector), abi.encode(amountIn)
        );
    }

    function createParams(bool isSingleHop) internal view returns (YodlUniswapRouter.YodlUniswapParams memory) {
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

    function test_yodlWithUniswap_SingleHop() public {
        console.log("address(this)", address(this));
        console.log("priceFeedChainlink: %s", priceFeedChainlink.feedType);
        console.log("priceFeedChainlink: %s", priceFeedChainlink.feedAddress);

        // assertEq(address(harnessRouter.uniswapRouter()), uniswapRouterAddress, "Uniswap router address mismatch");

        // YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
        //     sender: SENDER,
        //     receiver: RECEIVER,
        //     amountIn: amountIn,
        //     amountOut: amountOut,
        //     // memo: "Test payment",
        //     memo: "",
        //     path: abi.encode(address(tokenB), poolFee, address(tokenA)),
        //     priceFeeds: [priceFeedChainlink, priceFeedNULL],
        //     extraFeeReceiver: address(0),
        //     extraFeeBps: 0,
        //     swapType: YodlUniswapRouter.SwapType.SINGLE,
        //     yd: 0,
        //     yAppList: new YodlUniswapRouter.YApp[](0)
        // });

        // Mock the Uniswap swap
        // mockUniswapRouter.setAmountSpent(95 ether);

        uint256 decimals = 8;
        int256 price = 1_0657_0000; // the contract should return an int256

        vm.mockCall(
            uniswapRouterAddress, abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector), abi.encode(amountIn)
        );

        // vm.mockCall(
        //     uniswapRouterAddress,
        //     abi.encodeWithSelector(
        //         IV3SwapRouter.exactOutputSingle.selector,
        //         IV3SwapRouter.ExactOutputSingleParams({
        //             tokenIn: address(tokenA),
        //             tokenOut: USDC,
        //             fee: poolFee,
        //             recipient: address(harnessRouter),
        //             amountOut: amountOut,
        //             amountInMaximum: amountIn,
        //             sqrtPriceLimitX96: 0
        //         })
        //     ),
        //     abi.encode(amountIn) // This is the amount spent, which should be less than or equal to amountInMaximum
        // );

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

        YodlUniswapRouter.YodlUniswapParams memory singleParams = createParams(true);
        // singleParams = createParams(true);

        uint256 amountSpent;

        vm.prank(SENDER, SENDER);
        // uint256 amountSpent = harnessRouter.yodlWithUniswap(singleParams);
        try harnessRouter.yodlWithUniswap(singleParams) returns (uint256 _amountSpent) {
            amountSpent = _amountSpent;
            console.log("yodlWithUniswap succeeded, amountSpent:", _amountSpent);
        } catch Error(string memory reason) {
            console.log("yodlWithUniswap failed with reason:", reason);
            // fail("yodlWithUniswap should not revert");
            fail();
        } catch (bytes memory lowLevelData) {
            console.log("yodlWithUniswap failed with low-level error");
            console.logBytes(lowLevelData);
            fail();
        }

        assertEq(amountSpent, 95 ether, "Incorrect amount spent");
        assertEq(tokenB.balanceOf(RECEIVER), 90 ether, "Incorrect amount received");
    }

    // function test_yodlWithUniswap_MultiHop() public {
    //     YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
    //         sender: SENDER,
    //         receiver: RECEIVER,
    //         amountIn: 100 ether,
    //         amountOut: 85 ether,
    //         memo: "Test multi-hop payment",
    //         path: abi.encodePacked(address(tokenOut), uint24(3000), address(tokenBase), uint24(500), address(tokenIn)),
    //         priceFeeds: new YodlUniswapRouter.PriceFeed[](2),
    //         extraFeeReceiver: address(0),
    //         extraFeeBps: 0,
    //         swapType: YodlUniswapRouter.SwapType.MULTI,
    //         yd: 0,
    //         yAppList: new YodlUniswapRouter.YApp[](0)
    //     });

    //     // Mock the Uniswap swap
    //     // mockUniswapRouter.setAmountSpent(92 ether);

    //     vm.prank(SENDER);
    //     uint256 amountSpent = harnessRouter.yodlWithUniswap(params);

    //     assertEq(amountSpent, 92 ether, "Incorrect amount spent");
    //     assertEq(tokenOut.balanceOf(RECEIVER), 85 ether, "Incorrect amount received");
    // }

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

    // function test_yodlWithUniswap_WithExtraFee() public {
    //     address extraFeeReceiver = address(0x3);
    //     uint256 extraFeeBps = 100; // 1%

    //     YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
    //         sender: SENDER,
    //         receiver: RECEIVER,
    //         amountIn: 100 ether,
    //         amountOut: 90 ether,
    //         memo: "Test payment with extra fee",
    //         path: abi.encodePacked(address(tokenOut), uint24(3000), address(tokenIn)),
    //         priceFeeds: YodlUniswapRouter.PriceFeed[](2),
    //         extraFeeReceiver: extraFeeReceiver,
    //         extraFeeBps: extraFeeBps,
    //         swapType: YodlUniswapRouter.SwapType.SINGLE,
    //         yd: 0,
    //         yAppList: new YodlUniswapRouter.YApp[](0)
    //     });

    //     // Mock the Uniswap swap
    //     // mockUniswapRouter.setAmountSpent(95 ether);

    //     vm.prank(SENDER);
    //     uint256 amountSpent = router.yodlWithUniswap(params);

    //     assertEq(amountSpent, 95 ether, "Incorrect amount spent");

    //     uint256 expectedExtraFee = (90 ether * extraFeeBps) / 10000;
    //     assertEq(tokenOut.balanceOf(RECEIVER), 90 ether - expectedExtraFee, "Incorrect amount received by receiver");
    //     assertEq(tokenOut.balanceOf(extraFeeReceiver), expectedExtraFee, "Incorrect extra fee received");
    // }
}
