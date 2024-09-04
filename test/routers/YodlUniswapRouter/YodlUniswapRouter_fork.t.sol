// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AbstractYodlRouter} from "@src/AbstractYodlRouter.sol";
import {YodlUniswapRouter} from "@src/routers/YodlUniswapRouter.sol";
import {HelperConfig} from "@script/HelperConfig.s.sol";
import {DeployHarnessRouter} from "@script/DeployHarnessRouter.s.sol";
import {YodlUniswapRouterHarness} from "./shared/YodlUniswapRouterHarness.t.sol";

contract YodlUniswapRouterForkTest is Test {
    YodlUniswapRouterHarness public harnessRouter;
    address uniswapRouter;
    HelperConfig public helperConfig;
    IERC20 usdcToken;
    IERC20 daiToken;
    IERC20 linkToken;
    address public SENDER;
    address public RECEIVER = makeAddr("RECEIVER");

    uint256 amountIn = 1.1e18; // dai
    uint256 amountOut = 1e6; // usdc
    uint24 poolFee = 3000; // 0.3%, set by Uniswap, change will result in revert
    AbstractYodlRouter.PriceFeed priceFeedChainlink;
    AbstractYodlRouter.PriceFeed priceFeedNULL;
    address extraFeeAddress = address(0);
    bytes32 defaultMemo = "hi";
    uint256 constant baseFeeBps = 20;

    function setUp() external {
        DeployHarnessRouter deployer = new DeployHarnessRouter();
        (harnessRouter,, helperConfig) = deployer.run(DeployHarnessRouter.RouterType.Uniswap);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        uniswapRouter = config.uniswapRouterV3;
        SENDER = config.account;
        usdcToken = IERC20(config.usdc);
        daiToken = IERC20(config.dai);
        linkToken = IERC20(config.link);
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
            path = abi.encode(address(usdcToken), poolFee, address(daiToken));
            swapType = YodlUniswapRouter.SwapType.SINGLE;
        } else {
            path = abi.encode(address(usdcToken), poolFee, address(daiToken), poolFee, address(linkToken));
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

    function test_Transfer_Fork() public {
        YodlUniswapRouter.YodlUniswapParams memory params = createYodlUniswapParams(true);
        uint256 fee = params.amountOut * baseFeeBps / 10000;
        uint256 senderBalanceBefore = daiToken.balanceOf(SENDER);
        uint256 contractBalanceBefore = usdcToken.balanceOf(address(harnessRouter));

        vm.startPrank(SENDER, SENDER); // sets msg.sender and tx.origin to SENDER for all subsequent calls
        daiToken.approve(address(harnessRouter), type(uint256).max);
        uint256 amountSpent = harnessRouter.yodlWithUniswap(params); // Call router
        vm.stopPrank();

        uint256 senderBalanceAfter = daiToken.balanceOf(SENDER);
        uint256 receiverBalanceAfter = usdcToken.balanceOf(RECEIVER);
        uint256 contractBalanceAfter = usdcToken.balanceOf(address(harnessRouter));
        uint256 contractBalanceAfterDAI = daiToken.balanceOf(address(harnessRouter));

        assertEq(params.amountIn, amountSpent + contractBalanceAfterDAI, "Incorrect amount spent");
        assertEq(senderBalanceAfter, senderBalanceBefore - params.amountIn, "Incorrect sender balance");
        assertEq(contractBalanceAfter, contractBalanceBefore + fee, "Incorrect contract balance");
        assertEq(receiverBalanceAfter, params.amountOut - fee, "Incorrect receiver balance");
    }
}
