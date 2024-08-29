// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.26;

// import {Test} from "forge-std/Test.sol";
// import {YodlUniswapRouter} from "@src/routers/YodlUniswapRouter.sol";

// import {MockERC20} from "@test/AbstractYodlRouter/shared/MockERC20.sol";
// import {YodlUniswapRouterHarness} from "./shared/YodlUniswapRouterHarness.t.sol";
// // import {MockUniswapRouter} from "./mocks/MockUniswapRouter.sol";

// contract YodlUniswapRouterTest is Test {
//     YodlUniswapRouterHarness public router;
//     // MockUniswapRouter public mockUniswapRouter;
//     MockERC20 public tokenIn;
//     MockERC20 public tokenOut;
//     MockERC20 public tokenBase;

//     address public constant SENDER = address(1);
//     address public constant RECEIVER = address(2);

//     function setUp() public {
//         // mockUniswapRouter = new MockUniswapRouter();
//         // router = new YodlUniswapRouterHarness(address(mockUniswapRouter));
//         router = new YodlUniswapRouterHarness(address(0x3));

//         tokenIn = new MockERC20("Token In", "TIN", 18);
//         tokenOut = new MockERC20("Token Out", "TOUT", 18);
//         tokenBase = new MockERC20("Token Base", "TBASE", 18);

//         // Fund the sender with some tokens
//         tokenIn.mint(SENDER, 1000 ether);
//         vm.prank(SENDER);
//         tokenIn.approve(address(router), type(uint256).max);
//     }

//     function test_yodlWithUniswap_SingleHop() public {
//         YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
//             sender: SENDER,
//             receiver: RECEIVER,
//             amountIn: 100 ether,
//             amountOut: 90 ether,
//             memo: "Test payment",
//             path: abi.encodePacked(address(tokenOut), uint24(3000), address(tokenIn)),
//             priceFeeds: new YodlUniswapRouter.PriceFeed[](2),
//             extraFeeReceiver: address(0),
//             extraFeeBps: 0,
//             swapType: YodlUniswapRouter.SwapType.SINGLE,
//             yd: 0,
//             yAppList: new YodlUniswapRouter.YApp[](0)
//         });

//         // Mock the Uniswap swap
//         // mockUniswapRouter.setAmountSpent(95 ether);

//         vm.prank(SENDER);
//         uint256 amountSpent = router.yodlWithUniswap(params);

//         assertEq(amountSpent, 95 ether, "Incorrect amount spent");
//         assertEq(tokenOut.balanceOf(RECEIVER), 90 ether, "Incorrect amount received");
//     }

//     // function test_yodlWithUniswap_MultiHop() public {
//     //     YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
//     //         sender: SENDER,
//     //         receiver: RECEIVER,
//     //         amountIn: 100 ether,
//     //         amountOut: 85 ether,
//     //         memo: "Test multi-hop payment",
//     //         path: abi.encodePacked(address(tokenOut), uint24(3000), address(tokenBase), uint24(500), address(tokenIn)),
//     //         priceFeeds: new YodlUniswapRouter.PriceFeed[](2),
//     //         extraFeeReceiver: address(0),
//     //         extraFeeBps: 0,
//     //         swapType: YodlUniswapRouter.SwapType.MULTI,
//     //         yd: 0,
//     //         yAppList: new YodlUniswapRouter.YApp[](0)
//     //     });

//     //     // Mock the Uniswap swap
//     //     // mockUniswapRouter.setAmountSpent(92 ether);

//     //     vm.prank(SENDER);
//     //     uint256 amountSpent = router.yodlWithUniswap(params);

//     //     assertEq(amountSpent, 92 ether, "Incorrect amount spent");
//     //     assertEq(tokenOut.balanceOf(RECEIVER), 85 ether, "Incorrect amount received");
//     // }

//     // function test_decodeTokenOutTokenInUniswap() public {
//     //     bytes memory singleHopPath = abi.encodePacked(address(tokenOut), uint24(3000), address(tokenIn));
//     //     bytes memory multiHopPath =
//     //         abi.encodePacked(address(tokenOut), uint24(3000), address(tokenBase), uint24(500), address(tokenIn));

//     //     (address outToken, address inToken) =
//     //         router.exposed_decodeTokenOutTokenInUniswap(singleHopPath, YodlUniswapRouter.SwapType.SINGLE);
//     //     assertEq(outToken, address(tokenOut), "Incorrect tokenOut for single hop");
//     //     assertEq(inToken, address(tokenIn), "Incorrect tokenIn for single hop");

//     //     (outToken, inToken) =
//     //         router.exposed_decodeTokenOutTokenInUniswap(multiHopPath, YodlUniswapRouter.SwapType.MULTI);
//     //     assertEq(outToken, address(tokenOut), "Incorrect tokenOut for multi hop");
//     //     assertEq(inToken, address(tokenIn), "Incorrect tokenIn for multi hop");
//     // }

//     // function test_decodeSinglePoolFee() public {
//     //     bytes memory path = abi.encodePacked(address(tokenOut), uint24(3000), address(tokenIn));
//     //     uint24 fee = router.exposed_decodeSinglePoolFee(path);
//     //     assertEq(fee, 3000, "Incorrect pool fee decoded");
//     // }

//     // function test_yodlWithUniswap_WithExtraFee() public {
//     //     address extraFeeReceiver = address(0x3);
//     //     uint256 extraFeeBps = 100; // 1%

//     //     YodlUniswapRouter.YodlUniswapParams memory params = YodlUniswapRouter.YodlUniswapParams({
//     //         sender: SENDER,
//     //         receiver: RECEIVER,
//     //         amountIn: 100 ether,
//     //         amountOut: 90 ether,
//     //         memo: "Test payment with extra fee",
//     //         path: abi.encodePacked(address(tokenOut), uint24(3000), address(tokenIn)),
//     //         priceFeeds: YodlUniswapRouter.PriceFeed[](2),
//     //         extraFeeReceiver: extraFeeReceiver,
//     //         extraFeeBps: extraFeeBps,
//     //         swapType: YodlUniswapRouter.SwapType.SINGLE,
//     //         yd: 0,
//     //         yAppList: new YodlUniswapRouter.YApp[](0)
//     //     });

//     //     // Mock the Uniswap swap
//     //     // mockUniswapRouter.setAmountSpent(95 ether);

//     //     vm.prank(SENDER);
//     //     uint256 amountSpent = router.yodlWithUniswap(params);

//     //     assertEq(amountSpent, 95 ether, "Incorrect amount spent");

//     //     uint256 expectedExtraFee = (90 ether * extraFeeBps) / 10000;
//     //     assertEq(tokenOut.balanceOf(RECEIVER), 90 ether - expectedExtraFee, "Incorrect amount received by receiver");
//     //     assertEq(tokenOut.balanceOf(extraFeeReceiver), expectedExtraFee, "Incorrect extra fee received");
//     // }
// }
