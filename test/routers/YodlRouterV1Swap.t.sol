// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;
// pragma abicoder v2;

// import "forge-std/Test.sol";

// import "../src/YodlRouterV1.sol";
// import "../src/testnet/Tkn.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

// contract YodlRouterV1Test is Test {
//     event Payment(
//         address indexed sender,
//         address indexed receiver,
//         address token, /* the token that payee receives, use address(0) for AVAX*/
//         uint256 amount,
//         uint256 fee,
//         bytes32 memo
//     );
//     event Convert(address indexed priceFeed, int256 exchangeRate);
//     event Approval(address indexed owner, address indexed spender, uint256 value);

//     YodlRouterV1 hiroRouterV1;
//     Tkn token;
//     Tkn token2;
//     address treasuryAddress;
//     address senderAddress;
//     address extraFeeAddress;
//     uint256 baseFeeBps;
//     bytes32 defaultMemo;
//     YodlRouterV1.YodlUniswapParams singleParams;
//     YodlRouterV1.YodlUniswapParams multiParams;
//     YodlRouterV1.YodlCurveParams curveParams;
//     address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
//     address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
//     address constant HEX = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
//     address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
//     address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
//     address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
//     address constant uniswapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
//     address constant curveRouterAddress = 0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
//     address constant curve3poolAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;  // DAI/USDC/USDT pool

//     function setUp() public {
//         baseFeeBps = 25;
//         token = new Tkn("USDx", "USDX");
//         token2 = new Tkn("HEX", "HEX");
//         treasuryAddress = address(123);
//         extraFeeAddress = address(0);
//         defaultMemo = "hi";
//         hiroRouterV1 = new YodlRouterV1(treasuryAddress, baseFeeBps, "0.2", uniswapRouterAddress, curveRouterAddress, WETH);

//         singleParams = YodlRouterV1.YodlUniswapParams({
//             sender: address(1), 
//             receiver: address(1337),
//             memo: "01",
//             amountIn: 1 ether,
//             amountOut: 1_000_000,
//             path: abi.encode(USDC, 500, address(token)),
//             priceFeeds: [address(0), address(0)],
//             extraFeeReceiver: extraFeeAddress,
//             extraFeeBps: 0,
//             returnRemainder: true,
//             swapType: YodlRouterV1.SwapType.SINGLE
//         });

//         vm.mockCall(
//             uniswapRouterAddress,
//             abi.encodeWithSelector(
//                 ISwapRouter.exactOutputSingle.selector
//             ),
//             abi.encode(singleParams.amountIn)
//         );

//         multiParams = YodlRouterV1.YodlUniswapParams({
//             sender: address(1), 
//             receiver: address(1337),
//             memo: "01",
//             amountIn: 1 ether,
//             amountOut: 1 ether,
//             extraFeeReceiver: extraFeeAddress,
//             extraFeeBps: 0,
//             path: abi.encode(address(token2), uint24(500), USDC, uint24(500), address(token)),
//             priceFeeds: [address(0), address(0)],
//             returnRemainder: true,
//             swapType: YodlRouterV1.SwapType.MULTI
//         });

//         vm.mockCall(
//             uniswapRouterAddress,
//             abi.encodeWithSelector(
//                 ISwapRouter.exactOutput.selector
//             ),
//             abi.encode(singleParams.amountIn)
//         );

//         vm.mockCall(
//             address(token2),
//             abi.encodeWithSelector(
//                 ERC20.transfer.selector
//             ),
//             abi.encode(true)
//         );

//     }

//     function mintAndApprove(uint256 amount) public {
//         token.mint(singleParams.sender, amount);
//         vm.prank(singleParams.sender);
//         token.approve(address(hiroRouterV1), amount);
//     }

//     function assertBalancesForAmount(uint256 amount) public {
//         uint256 baseFee = amount * baseFeeBps / 10000;

//         assertEq(token.balanceOf(singleParams.sender), 0);
//         assertEq(
//             token.balanceOf(singleParams.receiver),
//             amount - baseFee,
//             "merchant amount not matching"
//         );
//         assertEq(token.balanceOf(treasuryAddress), baseFee);
//     }

     
//     function test_PayWithUniswapSimple() public {
//         mintAndApprove(singleParams.amountIn * 100);
//         uint256 balance = token.balanceOf(singleParams.sender);
        
//         vm.prank(singleParams.sender);
//         hiroRouterV1.payWithUniswap(singleParams);
//         assertLe(token.balanceOf(singleParams.sender), balance - singleParams.amountIn);
//     }

//     function test_PayWithUniswapGasOptimized() public {
//         mintAndApprove(singleParams.amountIn * 100);
//         uint256 balance = token.balanceOf(singleParams.sender);
//         singleParams.returnRemainder = false;
//         singleParams.amountIn = 2 ether;
//         vm.prank(singleParams.sender);
//         hiroRouterV1.payWithUniswap(singleParams);
//         assertLe(token.balanceOf(singleParams.sender), balance - singleParams.amountIn);
//     }

//     function test_PayWithUniswapMultihop() public {
//         mintAndApprove(multiParams.amountIn * 10);
        
//         uint256 balance = token.balanceOf(multiParams.sender);
//         uint256 expectedBalance = balance - multiParams.amountIn;

//         vm.prank(multiParams.sender);
//         uint256 amountSpent = hiroRouterV1.payWithUniswap(multiParams);
//         assertEq(multiParams.amountIn, amountSpent);
//         assertApproxEqRel(multiParams.amountIn, amountSpent, 0.1e18);
//         assertApproxEqRel(token.balanceOf(multiParams.sender), expectedBalance, 0.1e18);
//     }

//     function setUp_testPayWithCurve(uint256 amountSwapped) internal {
//         // Create params and mock call
//         curveParams = YodlRouterV1.YodlCurveParams({
//             sender: address(1),
//             receiver: address(1337),
//             memo: "01",
//             amountIn: 1002500,  // 1.0025 (1-to-1 swap with a 0.25% fee)
//             amountOut: 1000000,  // 1
//             // We'll pretend USDx is USDC in the pool
//             route: [address(token), curve3poolAddress, USDT, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
//             swapParams: [
//                 [uint256(1), uint256(2), uint256(1)],
//                 [uint256(0), uint256(0), uint256(0)],
//                 [uint256(0), uint256(0), uint256(0)],
//                 [uint256(0), uint256(0), uint256(0)]
//             ],
//             factoryAddresses: [ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
//             priceFeeds: [address(0), address(0)],
//             extraFeeReceiver: extraFeeAddress,
//             extraFeeBps: 0,
//             returnRemainder: false
//         });

//         vm.mockCall(
//             curveRouterAddress,
//             abi.encodeWithSelector(
//                 ICurveRouter.exchange_multiple.selector,
//                 curveParams.route,
//                 curveParams.swapParams,
//                 curveParams.amountIn,
//                 curveParams.amountOut,
//                 [ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
//                 address(hiroRouterV1)
//             ),
//             abi.encode(amountSwapped)
//         );
//     }

//     function test_PayWithCurveNoRemainder() public {
//         // Call setup function
//         setUp_testPayWithCurve(1002500);

//         mintAndApprove(curveParams.amountIn * 100);
//         uint256 balance = token.balanceOf(curveParams.sender);
//         uint256 fee = curveParams.amountOut * baseFeeBps / 10000;

//         // Catch events that should be emitted
//         vm.expectEmit(true, true, false, true);
//         emit Approval(address(hiroRouterV1), curveRouterAddress, curveParams.amountIn);

//         vm.expectEmit(true, true, false, true);
//         emit Payment(curveParams.sender, curveParams.receiver, USDT, curveParams.amountOut, fee, curveParams.memo);

//         // payWithCurve will only go through if the fee has been correctly deducted
//         vm.prank(curveParams.sender);
//         uint256 amountOut = hiroRouterV1.payWithCurve(curveParams);
//         assertEq(token.balanceOf(curveParams.sender), balance - curveParams.amountIn);
//         assertEq(amountOut, 1002500);
//     }

//     // Revert tests

//     function test_UniswapInsufficientEtherProvided() public {
//         uint256 amount = 1 ether;

//         hoax(singleParams.sender, 10 ether);
//         vm.expectRevert("insufficient ether provided");
//         hiroRouterV1.payWithUniswap{value: amount - 1}(
//             YodlRouterV1.YodlUniswapParams({
//                 sender: address(1),
//                 receiver: address(1337),
//                 memo: "01",
//                 amountIn: 1 ether,
//                 amountOut: 1_000_000,
//                 path: abi.encode(USDC, 500, NATIVE_TOKEN),
//                 priceFeeds: [address(0), address(0)],
//                 extraFeeReceiver: extraFeeAddress,
//                 extraFeeBps: 0,
//                 returnRemainder: true,
//                 swapType: YodlRouterV1.SwapType.SINGLE
//             })
//         );
//     }

//     function test_UniswapRouterNotPresent() public {
//         YodlRouterV1 hiroRouterNoUniswap = new YodlRouterV1(
//             treasuryAddress,
//             baseFeeBps,
//             "0.2",
//             address(0),
//             curveRouterAddress,
//             WETH
//         );
//         hoax(singleParams.sender, 10 ether);
//         vm.expectRevert("uniswap router not present");
//         hiroRouterNoUniswap.payWithUniswap(singleParams);
//     }

//     function test_CurveRouterNotPresent() public {
//         YodlRouterV1 hiroRouterNoCurve = new YodlRouterV1(
//             treasuryAddress,
//             baseFeeBps,
//             "0.2",
//             uniswapRouterAddress,
//             address(0),
//             WETH
//         );
//         hoax(curveParams.sender, 10 ether);
//         vm.expectRevert("curve router not present");
//         hiroRouterNoCurve.payWithCurve(curveParams);
//     }

// }
