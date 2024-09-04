// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlCurveRouter} from "@src/routers/YodlCurveRouter.sol";
import {HelperConfig} from "@script/HelperConfig.s.sol";
import {DeployHarnessRouter} from "@script/DeployHarnessRouter.s.sol";
import {YodlCurveRouterHarness} from "./shared/YodlCurveRouterHarness.t.sol";

contract YodlCurveRouterForkTest is Test {
    YodlCurveRouterHarness public harnessRouter;
    address curveRouterNG;
    HelperConfig public helperConfig;
    IERC20 usdcToken;
    IERC20 daiToken;
    IERC20 linkToken;
    address public SENDER;
    address public RECEIVER = makeAddr("RECEIVER");

    uint256 amountIn = 1.1e18; // dai
    uint256 amountOut = 1e6; // usdc
    uint24 poolFee = 3000; // 0.3%, set by Curve, change will result in revert
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
        usdcToken = IERC20(config.usdc);
        daiToken = IERC20(config.dai);
        linkToken = IERC20(config.link);
    }

    /* Helper functions */

    function createYodlCurveParams(bool isSingleHop) internal view returns (YodlCurveRouter.YodlCurveParams memory) {
        return YodlCurveRouter.YodlCurveParams({
            sender: SENDER,
            receiver: RECEIVER,
            amountIn: amountIn,
            amountOut: amountOut,
            memo: defaultMemo,
            swapParams: [
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)]
            ],
            pools: [address(0), address(0), address(0), address(0), address(0)],
            route: [
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
            ],
            priceFeeds: [priceFeedChainlink, priceFeedNULL],
            extraFeeReceiver: extraFeeAddress,
            extraFeeBps: 0,
            yd: 0,
            yAppList: new YodlCurveRouter.YApp[](0)
        });
    }

    /* Test functions */

    function test_Transfer_Fork() public {
        YodlCurveRouter.YodlCurveParams memory params = createYodlCurveParams(true);
        uint256 fee = params.amountOut * baseFeeBps / 10000;
        uint256 senderBalanceBefore = daiToken.balanceOf(SENDER);
        uint256 contractBalanceBefore = usdcToken.balanceOf(address(harnessRouter));

        vm.startPrank(SENDER, SENDER); // sets msg.sender and tx.origin to SENDER for all subsequent calls
        daiToken.approve(address(harnessRouter), type(uint256).max);
        uint256 amountSpent = harnessRouter.yodlWithCurve(params); // Call router
        vm.stopPrank();

        uint256 senderBalanceAfter = daiToken.balanceOf(SENDER);
        uint256 receiverBalanceAfter = usdcToken.balanceOf(RECEIVER);
        uint256 contractBalanceAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 contractBalanceAfterDAI = daiToken.balanceOf(address(harnessRouter));

        /* Pass */
        assertEq(params.amountIn, amountSpent + contractBalanceAfterDAI, "Incorrect amount spent");
        assertEq(senderBalanceAfter, senderBalanceBefore - params.amountIn, "Incorrect sender balance");
        assertEq(contractBalanceAfter, contractBalanceBefore + fee, "Incorrect contract balance");
        assertEq(receiverBalanceAfter, params.amountOut - fee, "Incorrect receiver balance");
    }
}
