// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

contract AbstractYodlRouterHarness is AbstractYodlRouter {
    AbstractYodlRouter.PriceFeed public priceFeedChainlink;
    AbstractYodlRouter.PriceFeed public priceFeedExternal;
    bool private mockVerifyRateSignature;
    bool private mockVerifyRateSignatureResult;
    address public constant MOCK_RATE_VERIFIER = 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf; // vm.addr(1)

    constructor() AbstractYodlRouter() {
        version = "vSam";
        yodlFeeBps = 20;

        /* Values from Arbitrum miannet?*/
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        priceFeedChainlink = AbstractYodlRouter.PriceFeed({
            feedAddress: address(13480),
            feedType: 1,
            currency: "USDC",
            amount: 0,
            deadline: 0,
            signature: ""
        });

        priceFeedExternal = AbstractYodlRouter.PriceFeed({
            feedAddress: address(13481),
            feedType: 2,
            currency: "USDT",
            amount: 3,
            deadline: 0,
            signature: ""
        });
    }

    /* Add functions to get the pricefeeds as structs */

    function getPriceFeedChainlink() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return priceFeedChainlink;
    }

    function getPriceFeedExternal() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return priceFeedExternal;
    }

    /* Expose internal functions */

    function exposed_transferFee(uint256 amount, uint256 feeBps, address token, address from, address to)
        external
        returns (uint256)
    {
        return transferFee(amount, feeBps, token, from, to);
    }

    /* Helpers to mock verifyRateSignature */

    function setMockVerifyRateSignature(bool _mock, bool _result) public {
        mockVerifyRateSignature = _mock;
        mockVerifyRateSignatureResult = _result;
    }

    /* Replaced by below function. Leaving here for now in case we need to revert */
    // function verifyRateSignature(PriceFeed calldata priceFeed) public view override returns (bool) {
    //     if (mockVerifyRateSignature) {
    //         return mockVerifyRateSignatureResult;
    //     }
    //     return super.verifyRateSignature(priceFeed);
    // }

    /* Override verifyRateSignature and re-implement nested functions */
    function verifyRateSignature(PriceFeed calldata priceFeed) public view virtual override returns (bool) {
        if (mockVerifyRateSignature) {
            return mockVerifyRateSignatureResult;
        }

        bytes32 messageHash = keccak256(abi.encodePacked(priceFeed.currency, priceFeed.amount, priceFeed.deadline));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        if (priceFeed.deadline < block.timestamp) {
            return false;
        }
        return _recoverSigner(ethSignedMessageHash, priceFeed.signature) == MOCK_RATE_VERIFIER; // This is the reason we need to override/re-implement
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (r, s, v);
    }
}
