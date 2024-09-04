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
        usdtToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
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

    /* Test functions */

    /* 
    * configured to swap USDT for USDC
    */
    function test_CurveTransfer_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams();
        uint256 fee = params.amountOut * baseFeeBps / 10000;
        uint256 senderBalanceBefore = usdtToken.balanceOf(SENDER);
        uint256 receiverBalanceBefore = usdcToken.balanceOf(RECEIVER);
        uint256 contractBalanceBefore = usdcToken.balanceOf(address(harnessRouter));

        vm.startPrank(SENDER);
        usdtToken.forceApprove(address(harnessRouter), type(uint256).max); // forceApprove required for usdc (or set to 0 first)
        uint256 amountSent = harnessRouter.yodlWithCurve(params); // Call router
        vm.stopPrank();

        uint256 senderBalanceAfter = usdtToken.balanceOf(SENDER);
        uint256 receiverBalanceAfter = usdcToken.balanceOf(RECEIVER);
        uint256 contractBalanceAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 convenienceFee = amountSent - params.amountOut;

        assertEq(senderBalanceAfter, senderBalanceBefore - params.amountIn, "Incorrect sender balance");
        assertEq(receiverBalanceAfter, (receiverBalanceBefore + params.amountOut) - fee, "Incorrect receiver balance");
        assertEq(contractBalanceAfter, contractBalanceBefore + fee + convenienceFee, "Incorrect contract balance");
    }
}
