// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlCurveRouter} from "@src/routers/YodlCurveRouter.sol";
import {HelperConfig} from "@script/HelperConfig.s.sol";
import {DeployHarnessRouter} from "@script/DeployHarnessRouter.s.sol";
import {YodlCurveRouterHarness} from "./shared/YodlCurveRouterHarness.t.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YodlCurveRouterForkTest is Test {
    using SafeERC20 for IERC20; // for usdc approval

    YodlCurveRouterHarness public harnessRouter;
    address curveRouterNG;
    HelperConfig public helperConfig;
    IERC20 usdtToken;
    IERC20 usdcToken;
    address public SENDER;
    address public RECEIVER = makeAddr("RECEIVER");

    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedNULL;
    address extraFeeAddress = address(0);
    bytes32 defaultMemo = "hi";
    uint256 constant baseFeeBps = 20;

    function setUp() external {
        DeployHarnessRouter deployer = new DeployHarnessRouter();
        (, harnessRouter, helperConfig) = deployer.run(DeployHarnessRouter.RouterType.Curve);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        curveRouterNG = config.curveRouterNG;
        SENDER = config.account;
        usdtToken = IERC20(config.usdt);
        usdcToken = IERC20(config.usdc);
    }

    /* Helper functions */

    /* 
    * ERC20 --> ERC20 (USDT --> USDC) swap
    */
    function createYodlCurveParams() internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        uint256[5][5] memory swapParams = [
            [uint256(2), uint256(1), uint256(1), uint256(1), uint256(3)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        ];

        return YodlCurveRouter.YodlCurveParams({
            sender: SENDER,
            receiver: RECEIVER,
            amountIn: 1.1e6, // usdt
            amountOut: 1e6, // usdc,
            memo: defaultMemo,
            swapParams: swapParams,
            pools: [
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000
            ],
            route: [
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // usdt
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // pool address
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // usdc
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ],
            priceFeeds: [priceFeedChainlink, priceFeedNULL],
            extraFeeReceiver: extraFeeAddress,
            extraFeeBps: 0,
            yd: 0,
            yAppList: new YodlCurveRouter.YApp[](0)
        });
    }

    /* 
    * ETH --> ERC20 (USDT) swap
    */
    function createYodlCurveParamsFromNative() internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();

        params.swapParams[0] = [uint256(2), uint256(0), uint256(1), uint256(3), uint256(3)];
        params.amountIn = 1e18; // 1 Eth
        params.amountOut = 2_000e6; // 2,000 USDT
        params.route[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // weth
        params.route[1] = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46; // triCrypto2 usdt/wbtc/weth
        params.route[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // usdt

        return params;
    }

    /* 
    ** NB: Currently this config is for USDT --> WETH, it should be USDT --> ETH.
    * This is because curve uses triCrypto2 pool for this swap and our contract does not convert the address to wrapped address.
    */
    function createYodlCurveParamsToNative() internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();

        params.swapParams[0] = [uint256(0), uint256(2), uint256(1), uint256(3), uint256(3)];
        params.amountIn = 5_000e6; // 5,000 USDT
        params.amountOut = 1e18; // 1 Eth
        params.route[0] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // usdt
        params.route[1] = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46; // triCrypto2 pool address
        // params.route[2] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // native address
        params.route[2] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        return params;
    }

    /* Test functions */

    /* 
    * Basic success
    * ERC20 --> ERC20 (USDT --> USDC) swap
    */
    function test_CurveTransferERC20_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();
        uint256 feeUSDC = params.amountOut * baseFeeBps / 10000;
        uint256 senderUSDT = usdtToken.balanceOf(SENDER);
        uint256 receiverUSDC = usdcToken.balanceOf(RECEIVER);
        uint256 contractUSDC = usdcToken.balanceOf(address(harnessRouter));

        vm.startPrank(SENDER);
        usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
        uint256 amountSpentUSDC = harnessRouter.yodlWithCurve(params); // Call router
        vm.stopPrank();

        uint256 senderUSDTAfter = usdtToken.balanceOf(SENDER);
        uint256 receiverUSDCAfter = usdcToken.balanceOf(RECEIVER);
        uint256 contractUSDCAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 convenienceFee = amountSpentUSDC - params.amountOut;

        assertEq(senderUSDTAfter, senderUSDT - params.amountIn, "Incorrect sender balance");
        assertEq(receiverUSDCAfter, (receiverUSDC + params.amountOut) - feeUSDC, "Incorrect receiver balance");
        assertEq(contractUSDCAfter, contractUSDC + feeUSDC + convenienceFee, "Incorrect contract balance");
    }

    /* 
    * Basic success
    * Native token --> ERC20 (USDT) swap
    */
    function test_CurveTransferFromNative_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParamsFromNative();
        uint256 feeUSDT = params.amountOut * baseFeeBps / 10000;
        uint256 senderNative = SENDER.balance;
        uint256 receiverUSDT = usdtToken.balanceOf(RECEIVER);
        uint256 contractUSDT = usdtToken.balanceOf(address(harnessRouter));

        vm.prank(SENDER);
        uint256 amountSentUSDT = harnessRouter.yodlWithCurve{value: params.amountIn}(params); // Call router

        uint256 senderNativeAfter = SENDER.balance;
        uint256 receiverUSDTAfter = usdtToken.balanceOf(RECEIVER);
        uint256 contractUSDTAfter = usdtToken.balanceOf(address(harnessRouter));
        uint256 convenienceFee = amountSentUSDT - params.amountOut;

        assertEq(senderNativeAfter, senderNative - params.amountIn, "Incorrect sender balance");
        assertEq(receiverUSDTAfter, (receiverUSDT + params.amountOut) - feeUSDT, "Incorrect receiver balance");
        assertEq(contractUSDTAfter, contractUSDT + feeUSDT + convenienceFee, "Incorrect contract balance");
    }

    /* 
    * Basic success
    * ERC20 (USDT) --> Native token swap
    ** NB: Currently this config is for USDT --> WETH, it should be USDT --> ETH. See createYodlCurveParamsToNative() comment.
    */
    function test_CurveTransferToNative_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParamsToNative();
        uint256 feeWETH = params.amountOut * baseFeeBps / 10000; // should be ETH

        uint256 senderUSDT = usdtToken.balanceOf(SENDER);
        uint256 contractWETH = harnessRouter.wrappedNativeToken().balanceOf(address(harnessRouter)); // shoud be ETH balance
        uint256 receiverWETH = harnessRouter.wrappedNativeToken().balanceOf(RECEIVER);

        vm.startPrank(SENDER);
        usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
        uint256 amountSentWETH = harnessRouter.yodlWithCurve(params); // Call router, shouldbe ETH
        vm.stopPrank();

        uint256 senderUSDTAfter = usdtToken.balanceOf(SENDER);
        uint256 receiverWETHAfter = harnessRouter.wrappedNativeToken().balanceOf(RECEIVER);
        uint256 contractWETHAfter = harnessRouter.wrappedNativeToken().balanceOf(address(harnessRouter)); // should be ETH balance
        uint256 convenienceFee = amountSentWETH - params.amountOut;

        assertEq(senderUSDTAfter, senderUSDT - params.amountIn, "Incorrect sender balance");
        assertEq(receiverWETHAfter, (receiverWETH + params.amountOut) - feeWETH, "Incorrect receiver balance"); // fails as we do not unwrap before transfer
        assertEq(contractWETHAfter, contractWETH + feeWETH + convenienceFee, "Incorrect contract balance");
    }

    /* 
    * Convenience fee in ERC20 token should be transfered to yodl yodlFeeTreasury
    * USDT --> USDC swap
    */
    function test_Curve_SweepERC20_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();
        address yodlFeeTreasury = harnessRouter.yodlFeeTreasury();
        uint256 treasuryUSDC = usdcToken.balanceOf(yodlFeeTreasury);

        vm.startPrank(SENDER);
        usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
        harnessRouter.yodlWithCurve(params); // Make payment USDT --> USDC
        vm.stopPrank();

        uint256 routerUSDC = usdcToken.balanceOf(address(harnessRouter)); // Router balance before sweep

        harnessRouter.sweep(address(usdcToken)); // Sweep router for USDC

        uint256 routerUSDCAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 treasuryUSDCAfter = usdcToken.balanceOf(harnessRouter.yodlFeeTreasury());

        assertGt(routerUSDC, 0, "Router Balance Before Should be > 0");
        assertEq(routerUSDCAfter, 0, "Router Balance After Should be 0");
        assertEq(treasuryUSDCAfter, treasuryUSDC + routerUSDC, "Incorrect Treasury Balance");
    }

    /* 
    * Convenience fee in native token should be transfered to yodl yodlFeeTreasury
    * Native --> USDC swap
    * ** NB: Needs much modification. Depends on ETH/WETH fix
    */
    // function test_Curve_SweepNative_Fork() public {
    //     // YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParamsNative(false);
    //     YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParamsToNative();
    //     address yodlFeeTreasury = harnessRouter.yodlFeeTreasury();
    //     uint256 treasuryNative = yodlFeeTreasury.balance;
    //     console.log(unicode"🚀  treasuryNative:", treasuryNative);

    //     console.log(unicode"🚀  harnessRouter.wrappedNativeToken():", address(harnessRouter.wrappedNativeToken()));

    //     // vm.startPrank(SENDER);
    //     // usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
    //     // harnessRouter.yodlWithCurve(params); // Make payment USDT --> USDC
    //     // vm.stopPrank();
    //     uint256 routerUSDTB = usdtToken.balanceOf(address(harnessRouter)); // Router balance before sweep
    //     console.log(unicode"🚀🐲  routerUSDTB:", routerUSDTB);

    //     vm.prank(SENDER);
    //     harnessRouter.yodlWithCurve{value: params.amountIn}(params); // Call router

    //     uint256 routerUSDT = usdtToken.balanceOf(address(harnessRouter)); // Router balance before sweep
    //     console.log(unicode"🚀🤡  routerUSDT:", routerUSDT);
    //     uint256 routerNative = address(harnessRouter).balance; // Router balance before sweep
    //     uint256 routerWETHBefore = harnessRouter.wrappedNativeToken().balanceOf(address(harnessRouter)); // chakc wrapped or ETH??
    //     console.log(unicode"🚀  routerWETHBefore:", routerWETHBefore);
    //     console.log(unicode"🚀  routerNative:", routerNative);

    //     harnessRouter.sweep(harnessRouter.NATIVE_TOKEN()); // Sweep router for Native

    //     uint256 routerWETHAfter = harnessRouter.wrappedNativeToken().balanceOf(address(harnessRouter)); // chakc wrapped or ETH??
    //     uint256 routerNativeAfter = address(harnessRouter).balance; // chakc wrapped or ETH??
    //     uint256 treasuryNativeAfter = yodlFeeTreasury.balance;

    //     console.log(unicode"🚀  routerWETHAfter:", routerWETHAfter);
    //     console.log(unicode"🚀  routerNativeAfter:", routerNativeAfter);
    //     console.log(unicode"🚀  treasuryNativeAfter:", treasuryNativeAfter);

    //     assertGt(routerNative, 0, "Router Balance Before Should be > 0");
    //     assertEq(routerNativeAfter, 0, "Router Balance After Should be 0");
    //     assertEq(treasuryNativeAfter, treasuryNative + routerNative, "Incorrect Treasury Balance");
    // }
}
