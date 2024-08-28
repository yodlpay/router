// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {AbstractYodlRouter} from "../../src/AbstractYodlRouter.sol";
import {ISwapRouter02} from "../../src/routers/YodlUniswapRouter.sol";
import {AbstractYodlRouterHarness} from "./shared/AbstractYodlRouterHarness.t.sol";

contract YodlAbstractRouterTest is Test {
    AbstractYodlRouterHarness abstractRouter;

    function setUp() public {
        abstractRouter = new AbstractYodlRouterHarness();
    }

    /* 
    * Scenario: 
    */
    function test_SplitSignature(uint256 amount, uint256 feeBps) public view {}

    // wtite test functions for each of ythe three below functions

    
}

// function verifyRateSignature(PriceFeed calldata priceFeed) public view virtual returns (bool) {
//     bytes32 messageHash = keccak256(abi.encodePacked(priceFeed.currency, priceFeed.amount, priceFeed.deadline));
//     bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

//     if (priceFeed.deadline < block.timestamp) {
//         return false;
//     }
//     return recoverSigner(ethSignedMessageHash, priceFeed.signature) == RATE_VERIFIER;
// }

// function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
//     (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

//     return ecrecover(_ethSignedMessageHash, v, r, s);
// }

// function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
//     require(sig.length == 65, "invalid signature length");

//     assembly {
//         r := mload(add(sig, 32))
//         s := mload(add(sig, 64))
//         v := byte(0, mload(add(sig, 96)))
//     }

//     return (r, s, v);
// }
