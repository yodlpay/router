// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

contract TestableAbstractYodlRouter is AbstractYodlRouter {
    AbstractYodlRouter.PriceFeed public priceFeedChainlink;
    AbstractYodlRouter.PriceFeed public priceFeedExternal;
    bool private mockVerifyRateSignature;
    bool private mockVerifyRateSignatureResult;

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

    /* Add functions to get the pricefeeds as a structs */

    function getPriceFeedChainlink() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return priceFeedChainlink;
    }

    function getPriceFeedExternal() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return priceFeedExternal;
    }

    /* Helpers to mock verifyRateSignature */

    function setMockVerifyRateSignature(bool _mock, bool _result) public {
        mockVerifyRateSignature = _mock;
        mockVerifyRateSignatureResult = _result;
    }

    function verifyRateSignature(PriceFeed calldata priceFeed) public view override returns (bool) {
        if (mockVerifyRateSignature) {
            return mockVerifyRateSignatureResult;
        }
        return super.verifyRateSignature(priceFeed);
    }
}
