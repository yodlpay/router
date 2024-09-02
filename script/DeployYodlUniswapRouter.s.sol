// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "@script/HelperConfig.s.sol";
import {YodlUniswapRouterHarness} from "@test/routers/YodlUniswapRouter/shared/YodlUniswapRouterHarness.t.sol";

contract DeployYodlUniswapRouter is Script {
    address constant RICH_USER = 0x28C6c06298d514Db089934071355E5743bf21d60; // Binance 14

    function run() external returns (YodlUniswapRouterHarness, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        helperConfig.setConfig(block.chainid, config); // might need if != local chainid

        vm.startBroadcast();
        YodlUniswapRouterHarness yodlUniswapRouter = new YodlUniswapRouterHarness(config.uniswapRouterV3);

        vm.stopBroadcast();
        return (yodlUniswapRouter, helperConfig);
    }
}
