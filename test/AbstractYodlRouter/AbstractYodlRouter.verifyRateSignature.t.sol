// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;
    address constant MOCK_WETH = address(0x1);
    address constant MOCK_SIGNER = address(0x2);

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness(AbstractYodlRouter.ChainType.L1, address(0));
        vm.etch(abstractRouter.RATE_VERIFIER(), hex"1234"); // Mock the RATE_VERIFIER contract
    }

    function test_VerifyRateSignature() public view {
        /* Create a valid signature */
        string memory currency = "USD";
        uint256 amount = 1000;
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 messageHash = keccak256(abi.encodePacked(currency, amount, deadline));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, ethSignedMessageHash);
        bytes memory signatureCorrect = abi.encodePacked(r, s, v);

        /* Use signature in price feed */
        AbstractYodlRouter.PriceFeed memory priceFeed = AbstractYodlRouter.PriceFeed({
            feedAddress: address(12345),
            heartbeat: 86400,
            feedType: 2, // EXTERNAL_FEED
            currency: currency,
            amount: amount,
            deadline: deadline,
            signature: signatureCorrect
        });

        bool result1 = abstractRouter.verifyRateSignature(priceFeed);
        assertTrue(result1, "Signature verification should pass");

        // test with wronmg priv key
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(2, ethSignedMessageHash); // using incorrect private key
        bytes memory signatureInCorrect = abi.encodePacked(r2, s2, v2);
        priceFeed.signature = signatureInCorrect;
        bool result2 = abstractRouter.verifyRateSignature(priceFeed);
        assertFalse(result2, "Signature verification should fail");

        /* Test with expired deadline */
        priceFeed.signature = signatureCorrect; // revert to correct priv key
        priceFeed.deadline = block.timestamp - 1; // set deadline in the past
        result1 = abstractRouter.verifyRateSignature(priceFeed);
        assertFalse(result1, "Signature verification should fail with expired deadline");
    }

    // function testRecoverSigner() public {
    //     // This function is private, so we'll test it indirectly through verifyRateSignature
    //     // The test logic is similar to testVerifyRateSignature
    // }

    // function testSplitSignature() public {
    //     // This function is private, so we'll test it indirectly through verifyRateSignature
    //     // We can test different signature lengths here

    //     string memory currency = "USD";
    //     uint256 amount = 1000;
    //     uint256 deadline = block.timestamp + 1 hours;

    //     bytes32 messageHash = keccak256(abi.encodePacked(currency, amount, deadline));
    //     bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, ethSignedMessageHash);

    //     // Valid signature length
    //     bytes memory validSignature = abi.encodePacked(r, s, v);
    //     assertTrue(validSignature.length == 65, "Valid signature should be 65 bytes long");

    //     // Invalid signature length
    //     bytes memory invalidSignature = abi.encodePacked(r, s);
    //     vm.expectRevert("invalid signature length");
    //     abstractRouter.verifyRateSignature(
    //         AbstractYodlRouter.PriceFeed({
    //             feedAddress: address(0),
    //             feedType: 2,
    //             currency: currency,
    //             amount: amount,
    //             deadline: deadline,
    //             signature: invalidSignature
    //         })
    //     );
    // }
}
