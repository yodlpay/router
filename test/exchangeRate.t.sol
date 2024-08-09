// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
pragma abicoder v2;

import "forge-std/Test.sol";

import "../src/AbstractYodlRouter.sol";
import "../src/chains/EthereumYodlRouter.sol";

contract YodlRouterV1Test is Test {
    event Payment(
        address indexed sender,
        address indexed receiver,
        address token /* the token that payee receives, use address(0) for AVAX*/,
        uint256 amount,
        uint256 fee,
        bytes32 memo
    );

    event Convert(address indexed priceFeed, int256 exchangeRate);

    YodlRouter ethRouter;
    address merchantAddress;
    address treasuryAddress;
    address senderAddress;
    address extraFeeAddress;
    uint256 baseFeeBps;
    bytes32 defaultMemo;
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WRAPPED_NATIVE_TOKEN =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Amounts over this are liable to overflow - lets assume no one will transact this much
    uint256 constant APPROX_MAX_AMOUNT = 1e68;

    function setUp() public {
        baseFeeBps = 25;
        treasuryAddress = address(123);
        extraFeeAddress = address(1338);
        defaultMemo = "hi";

        ethRouter = new YodlRouter();
    }

    // test..Scenarios are useful for --gas-reports

    function test_PaymentWithSmallAmount() public {
        // Ensure fee calculation does not trip over if amount is too small.
        (
            uint256 converted,
            address[2] memory priceFeedsUsed,
            int256[2] memory prices
        ) = ethRouter.exchangeRate();

        assertEq(token.balanceOf(senderAddress), 0);
    }
}
