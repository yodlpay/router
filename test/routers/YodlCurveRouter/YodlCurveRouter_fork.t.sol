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

    uint256 amountIn = 1.1e6; // usdt
    uint256 amountOut = 1e6; // usdc
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
            amountIn: amountIn,
            amountOut: amountOut,
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
                0xdAC17F958D2ee523a2206206994597C13D831ec7,
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
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

    function createYodlCurveParamsNative() internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        uint256[5][5] memory swapParams = [
            [uint256(2), uint256(0), uint256(1), uint256(30), uint256(3)], // eth/usdt, eth/usdc, same
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
        ];

        return YodlCurveRouter.YodlCurveParams({
            sender: SENDER,
            receiver: RECEIVER,
            // amountIn: 13000_0000000000, //
            // amountOut: 308297, // 45,1474
            amountIn: 1.9e18, // 1.9 Eth
            amountOut: 4514740000, // 4514,74 (USDT)
            memo: defaultMemo,
            swapParams: swapParams,
            pools: [
                // 0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B, //eth/usdc
                0xf5f5B97624542D72A9E06f04804Bf81baA15e2B4, // eth/usdt
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000
            ],
            route: [
                // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, //usdc
                // 0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B,
                // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // usdt
                0xf5f5B97624542D72A9E06f04804Bf81baA15e2B4,
                0xdAC17F958D2ee523a2206206994597C13D831ec7,
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ],
            priceFeeds: [priceFeedNULL, priceFeedNULL],
            extraFeeReceiver: extraFeeAddress,
            extraFeeBps: 0,
            yd: 0,
            yAppList: new YodlCurveRouter.YApp[](0)
        });
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
        uint256 amountSentUSDC = harnessRouter.yodlWithCurve(params); // Call router
        vm.stopPrank();

        uint256 senderUSDTAfter = usdtToken.balanceOf(SENDER);
        uint256 receiverUSDCAfter = usdcToken.balanceOf(RECEIVER);
        uint256 contractUSDCAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 convenienceFee = amountSentUSDC - params.amountOut;

        assertEq(senderUSDTAfter, senderUSDT - params.amountIn, "Incorrect sender balance");
        assertEq(receiverUSDCAfter, (receiverUSDC + params.amountOut) - feeUSDC, "Incorrect receiver balance");
        assertEq(contractUSDCAfter, contractUSDC + feeUSDC + convenienceFee, "Incorrect contract balance");
    }

    /* 
    * Basic success
    * Native token --> ERC20 (USDT) swap
    * NB: Getting EVM revert error. Tried multiple combinations of amounts. Copied params from real swap on curve.fi
    */
    // function test_CurveTransferNative_Fork() public {
    //     YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParamsNative();
    //     uint256 feeUSDT = params.amountOut * baseFeeBps / 10000;
    //     uint256 senderNative = SENDER.balance;
    //     uint256 receiverUSDT = usdtToken.balanceOf(RECEIVER);
    //     uint256 contractUSDT = usdtToken.balanceOf(address(harnessRouter));
    //     vm.deal(address(harnessRouter), 4.25e18); // Ruling out balance issue

    //     vm.startPrank(SENDER);
    //     // usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
    //     uint256 amountSentUSDT = harnessRouter.yodlWithCurve{value: params.amountIn}(params); // Call router
    //     vm.stopPrank();

    //     uint256 senderNativeAfter = SENDER.balance;
    //     uint256 receiverUSDTAfter = usdtToken.balanceOf(RECEIVER);
    //     uint256 contractUSDTAfter = usdtToken.balanceOf(address(harnessRouter));
    //     uint256 convenienceFee = amountSentUSDT - params.amountOut;

    //     console.log(unicode"🚀  senderNativeAfter:", senderNativeAfter);
    //     console.log(unicode"🚀  receiverUSDTAfter:", receiverUSDTAfter);
    //     console.log(unicode"🚀  contractUSDTAfter:", contractUSDTAfter);

    //     assertEq(senderNativeAfter, senderNative - params.amountIn, "Incorrect sender balance");
    //     assertEq(receiverUSDTAfter, (receiverUSDT + params.amountOut) - feeUSDT, "Incorrect receiver balance");
    //     assertEq(contractUSDTAfter, contractUSDT + feeUSDT + convenienceFee, "Incorrect contract balance");
    // }

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
    * NB: Coppied from above, not modified.
    */
    // function test_Curve_SweepNative_Fork() public {
    //     YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();
    //     address yodlFeeTreasury = harnessRouter.yodlFeeTreasury();
    //     uint256 treasuryUSDC = usdcToken.balanceOf(yodlFeeTreasury);

    //     vm.startPrank(SENDER);
    //     usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
    //     harnessRouter.yodlWithCurve(params); // Make payment USDT --> USDC
    //     vm.stopPrank();

    //     uint256 routerUSDC = usdcToken.balanceOf(address(harnessRouter)); // Router balance before sweep

    //     harnessRouter.sweep(address(usdcToken)); // Sweep router for USDC

    //     uint256 routerUSDCAfter = usdcToken.balanceOf(address(harnessRouter));
    //     uint256 treasuryUSDCAfter = usdcToken.balanceOf(harnessRouter.yodlFeeTreasury());

    //     assertGt(routerUSDC, 0, "Router Balance Before Should be > 0");
    //     assertEq(routerUSDCAfter, 0, "Router Balance After Should be 0");
    //     assertEq(treasuryUSDCAfter, treasuryUSDC + routerUSDC, "Incorrect Treasury Balance");
    // }
}
