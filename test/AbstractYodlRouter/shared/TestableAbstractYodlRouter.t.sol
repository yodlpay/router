// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

import {AbstractYodlRouter} from "../../../src/AbstractYodlRouter.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

contract TestableAbstractYodlRouter is AbstractYodlRouter {
    address[2] priceFeedAddresses = [address(13480), address(13481)];
    AbstractYodlRouter.PriceFeed public priceFeedChainlink;
    AbstractYodlRouter.PriceFeed public priceFeedExternal;
    AbstractYodlRouter.PriceFeed public priceFeedZeroValues; // Represents no pricefeed passed
    bool private mockVerifyRateSignature;
    bool private mockVerifyRateSignatureResult;

    constructor() AbstractYodlRouter() {
        version = "vSam";
        yodlFeeBps = 20;

        /* Values from Arbitrum miannet?*/
        yodlFeeTreasury = 0x5f0947253a8218894af13438ac2e2E0CeD30d234;
        wrappedNativeToken = IWETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

        priceFeedChainlink = AbstractYodlRouter.PriceFeed({
            feedAddress: priceFeedAddresses[0],
            feedType: 1,
            currency: "USDC",
            amount: 0,
            deadline: 0,
            signature: ""
        });

        priceFeedExternal = AbstractYodlRouter.PriceFeed({
            feedAddress: priceFeedAddresses[1],
            feedType: 2,
            currency: "USDT",
            amount: 3,
            deadline: 0,
            signature: ""
        });

        priceFeedZeroValues = AbstractYodlRouter.PriceFeed({
            feedAddress: address(0),
            feedType: 0,
            currency: "",
            amount: 0,
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

    function getPriceFeedZeroValues() public view returns (AbstractYodlRouter.PriceFeed memory) {
        return priceFeedZeroValues;
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

    // function createUSDPriceFeed(
    //     address feedAddress,
    //     int8 feedType,
    //     string memory currency,
    //     uint256 amount,
    //     uint256 deadline,
    //     bytes memory signature
    // ) public pure returns (AbstractYodlRouter.PriceFeed memory) {
    //     return AbstractYodlRouter.PriceFeed({
    //         feedAddress: feedAddress,
    //         feedType: feedType,
    //         currency: currency,
    //         amount: amount,
    //         deadline: deadline,
    //         signature: signature
    //     });
    // }
}
