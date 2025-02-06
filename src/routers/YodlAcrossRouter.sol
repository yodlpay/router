// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import "../AbstractYodlRouter.sol";
import "../interfaces/IBeforeHook.sol";
import "../interfaces/V3SpokePoolInterface.sol";

abstract contract YodlAcrossRouter is AbstractYodlRouter {
    struct YodlAcrossParams {
        // The message attached to the payment. If present, the router will take a fee.
        bytes32 memo;
        // The amount to pay before any price feeds are applied. This amount will be converted by the price feeds and then the sender will pay the converted amount in the given token.
        uint256 amount;
        // Array of Chainlink price feeds. See `exchangeRate` method for more details.
        PriceFeed[2] priceFeeds;
        // Token address to be used for the payment. Either an ERC20 token or the native token address.
        address token;
        // Address to receive the payment
        address receiver;
        // Address to receive an extra fee that is taken from the payment amount
        address extraFeeReceiver;
        // Size of the extra fee in terms of basis points (or 0 for none)
        uint256 extraFeeBps;
        // Metadata tracker for the payment
        uint256 yd;
        // List of guards and webhooks
        Guard[] guards;
        Webhook[] webhooks;
        address outputToken; // <--- from frontend
        uint256 outputAmount; // <--- from frontend
        uint256 destinationChainId; // <--- from frontend
        address exclusiveRelayer; // <--- from frontend
        uint32 quoteTimestamp; // <--- from frontend
        uint32 fillDeadline; // <--- from frontend
        uint32 exclusivityDeadline; // <--- from frontend
        bytes message; // <--- from frontend
        uint256 relayerFee; // <-- Total Across fee. This helps us index properly.
    }

    V3SpokePoolInterface public acrossSpokePool;
    bytes private constant ACROSS_IDENTIFIER = hex"1dc0de004d";

    constructor(address _acrossSpokePool) {
        acrossSpokePool = V3SpokePoolInterface(_acrossSpokePool);
    }

    function yodlWithAcross(YodlAcrossParams calldata params) external payable returns (uint256) {
        require(params.amount != 0, "invalid amount");
        require(params.token != NATIVE_TOKEN, "only ERC20 supported");

        uint256 outAmountGross = params.amount;

        // transform amount with priceFeeds
        if (params.priceFeeds[0].feedType != NULL_FEED || params.priceFeeds[1].feedType != NULL_FEED) {
            {
                int256[2] memory prices;
                address[2] memory priceFeedsUsed;
                (outAmountGross, priceFeedsUsed, prices) = exchangeRate(params.priceFeeds, params.amount);
                emitConversionEvent(params.priceFeeds, prices);
            }
        }

        outAmountGross = outAmountGross + params.relayerFee;

        if (params.guards.length > 0) {
            for (uint256 i = 0; i < params.guards.length; i++) {
                IBeforeHook(params.guards[i].guardAddress).beforeHook(
                    msg.sender, params.receiver, outAmountGross, params.token, params.guards[i].payload
                );
            }
        }

        if (params.token != NATIVE_TOKEN) {
            // ERC20 token
            require(
                IERC20(params.token).allowance(msg.sender, address(this)) >= outAmountGross, "insufficient allowance"
            );
        }

        uint256 totalFee = 0;
        uint256 outAmountNet = outAmountGross - totalFee;

        TransferHelper.safeTransferFrom(params.token, msg.sender, address(this), outAmountGross);
        depositToAcross(outAmountGross, params);

        emit Yodl(msg.sender, params.receiver, params.token, outAmountGross, totalFee, params.memo);

        return outAmountNet;
    }

    function depositToAcross(uint256 outAmountGross, YodlAcrossParams calldata params) internal {
        // Transfer to receiver
        TransferHelper.safeApprove(params.token, address(acrossSpokePool), outAmountGross);

        // Across api provides exclusivityDeadline as number of seconds for a single relayer to fill the deposit, e.g. 10.
        // The SC, expects it to be a unix timestamp in seconds.
        uint32 exclusivityDeadline = params.exclusivityDeadline;
        if (exclusivityDeadline != 0) {
            // Prevent overflow when adding to block.timestamp
            require(exclusivityDeadline <= type(uint32).max - block.timestamp, "exclusivity deadline overflow");
            exclusivityDeadline += uint32(block.timestamp);
        }

        // Construct the calldata for depositV3
        bytes memory depositCalldata = abi.encodeWithSelector(
            V3SpokePoolInterface.depositV3.selector,
            msg.sender, // address depositor,
            params.receiver, // address recipient,
            params.token, // address inputToken,
            params.outputToken, // address outputToken,
            outAmountGross, // uint256 inputAmount,
            params.outputAmount, // uint256 outputAmount,
            params.destinationChainId, // uint256 destinationChainId,
            params.exclusiveRelayer, // address exclusiveRelayer,
            params.quoteTimestamp, // uint32 quoteTimestamp,
            params.fillDeadline, // uint32 fillDeadline,
            exclusivityDeadline, // uint32 exclusivityDeadline,
            params.message // bytes calldata message
        );

        // append yodl-across identifier
        bytes memory finalCalldata = bytes.concat(depositCalldata, ACROSS_IDENTIFIER);

        (bool success,) = address(acrossSpokePool).call(finalCalldata);
        require(success, "Across deposit failed");
    }
}
