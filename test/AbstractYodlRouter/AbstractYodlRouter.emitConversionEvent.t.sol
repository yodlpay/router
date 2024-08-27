// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./shared/TestableAbstractYodlRouter.t.sol";
import {IERC20} from "@openzeppelin/contracts//token/ERC20/IERC20.sol";
import {MockERC20} from "./shared/MockUSDC.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter abstractRouter;

    function setUp() public {
        abstractRouter = new TestableAbstractYodlRouter();
    }

    /* 
    * Scenario: Emits ConvertWithExternalRate with External Feed 
    */
    // function testFuzz_Sweep_Native(int256[2] memory prices) public {
    // function testFuzz_EmitConversionEvent_ExternalPricefeed(int256[2] memory prices) public {
    // function test_EmitConversionEvent_ExternalPricefeed() public {
    //     AbstractYodlRouter.PriceFeed[2] memory priceFeeds;
    //     int256[2] memory prices;

    //     // uint256 treasuryETHBalanceBefore = abstractRouter.yodlFeeTreasury().balance; // Get the treasury balance
    //     // vm.deal(address(abstractRouter), amount); // Give the YodlRouter some eth

    //     // abstractRouter.sweep(abstractRouter.NATIVE_TOKEN()); // Sweep YodlRouter
    //     // uint256 treasuryETHBalanceAfter = abstractRouter.yodlFeeTreasury().balance; // Get the new treasury balance

    //     // assertEq(treasuryETHBalanceAfter - treasuryETHBalanceBefore, amount); // Ensure that they have successfully been transferred
    // }
}

//   function emitConversionEvent(PriceFeed[2] memory priceFeeds, int256[2] memory prices) public {
//         if (priceFeeds[0].feedType == EXTERNAL_FEED) {
//             emit ConvertWithExternalRate(priceFeeds[0].currency, priceFeeds[1].feedAddress, prices[0], prices[1]);
//         } else {
//             emit Convert(priceFeeds[0].feedAddress, priceFeeds[1].feedAddress, prices[0], prices[1]);
//         }
//     }
