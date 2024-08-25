// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {TestableAbstractYodlRouter} from "./utils/TestableAbstractYodlRouter.t.sol";

contract YodlAbstractRouterTest is Test {
    TestableAbstractYodlRouter helperContract;
    address mockWrappedNativeToken;
    address mockYodlFeeTreasury;
    uint256 constant YODL_FEE_BPS = 100; // 1%

    function setUp() public {
        mockWrappedNativeToken = address(0x1);
        mockYodlFeeTreasury = address(0x2);

        // helperContract = new TestableAbstractYodlRouter(mockWrappedNativeToken, mockYodlFeeTreasury, YODL_FEE_BPS);
    }

    // Your test functions go here
}
