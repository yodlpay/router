// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {MyMockERC20} from "@test/AbstractYodlRouter/shared/MyMockERC20.sol";

abstract contract CodeConstants {
    address constant RICH_USER = 0x28C6c06298d514Db089934071355E5743bf21d60; // Binance 14
    address constant DEFAULT_ANVIL_USER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    // Add more IDs as needed
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address uniswapRouterV3;
        address curveRouterNG;
        address link;
        address usdc;
        address dai;
        address account;
    }

    // Local network state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        // Note: We skip doing the local config
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].uniswapRouterV3 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            uniswapRouterV3: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45, // SwapRouter02
            curveRouterNG: 0x16C6521Dff6baB339122a0FE25a9116693265353, // v1.1
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            dai: 0x6B175474E89094C44Da98b954EedeAC495271d0F,
            // account: DEFAULT_ANVIL_USER
            account: RICH_USER
        });
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            uniswapRouterV3: 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E, // SwapRouter02
            curveRouterNG: address(0), // Not deployed
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            usdc: 0x7fc77B5c7614E1533320EA6dDC2FF6B5b2f7F2B2,
            dai: 0x7fc77B5c7614E1533320EA6dDC2FF6B5b2f7F2B2,
            account: RICH_USER // Not sure if rich on Sepolia
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.uniswapRouterV3 != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock conract!");
        console2.log("Make sure this was intentional");
        vm.startBroadcast();
        // Deploy uniswap router v3 mock (if possible)
        address uniswapRouterV3Mock = vm.addr(0x1); // shold deply contract
        address curveRouterNGMock = vm.addr(0x1); // shold deply contract
        //  VRFCoordinatorV2_5Mock uniswapRouterV3Mock =
        //     new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        MyMockERC20 link = new MyMockERC20("Chainlink Token", "LINK", 18);
        MyMockERC20 usdc = new MyMockERC20("USD Coin", "USDC", 6);
        MyMockERC20 dai = new MyMockERC20("Dai Stablecoin", "DAI", 18);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            uniswapRouterV3: address(uniswapRouterV3Mock),
            curveRouterNG: address(curveRouterNGMock),
            link: address(link),
            usdc: address(usdc),
            dai: address(dai),
            account: DEFAULT_ANVIL_USER
        });
        vm.deal(localNetworkConfig.account, 100 ether); // redundant?
        return localNetworkConfig;
    }
}
