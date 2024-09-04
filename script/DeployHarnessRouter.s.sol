// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "@script/HelperConfig.s.sol";
import {YodlUniswapRouterHarness} from "@test/routers/YodlUniswapRouter/shared/YodlUniswapRouterHarness.t.sol";
import {YodlCurveRouterHarness} from "@test/routers/YodlCurveRouter/shared/YodlCurveRouterHarness.t.sol";

// contract DeployYodlUniswapRouter is Script {
//     function run() external returns (YodlUniswapRouterHarness, HelperConfig) {
//         HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
//         helperConfig.setConfig(block.chainid, config); // might need if != local chainid

//         vm.startBroadcast();
//         YodlUniswapRouterHarness yodlUniswapRouter = new YodlUniswapRouterHarness(config.uniswapRouterV3);

//         vm.stopBroadcast();
//         return (yodlUniswapRouter, helperConfig);
//     }
// }

contract DeployHarnessRouter is Script {
    enum RouterType {
        Uniswap,
        Curve
    }

    function run(RouterType routerType)
        external
        returns (YodlUniswapRouterHarness, YodlCurveRouterHarness, HelperConfig)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        helperConfig.setConfig(block.chainid, config);

        vm.startBroadcast();

        YodlUniswapRouterHarness yodlUniswapRouter;
        YodlCurveRouterHarness yodlCurveRouter;

        if (routerType == RouterType.Uniswap) {
            yodlUniswapRouter = new YodlUniswapRouterHarness(config.uniswapRouterV3);
        } else if (routerType == RouterType.Curve) {
            yodlCurveRouter = new YodlCurveRouterHarness(config.curveRouterNG);
        } else {
            revert("Unsupported router type");
        }

        vm.stopBroadcast();
        return (yodlUniswapRouter, yodlCurveRouter, helperConfig);
    }
}
