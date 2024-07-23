// SPDX-License-Identifier: BSL-1.1

// @author samthebuilder.eth
pragma solidity ^0.8.26;

import {YodlUniswapRouter} from "./YodlUniswapRouter.sol";

abstract contract YodlPancakeRouter is YodlUniswapRouter {
    constructor(address _uniswapRouter) YodlUniswapRouter(_uniswapRouter) {}

    /// @notice Handles a payment with a swap through PancakeSwap
    /// @dev This needs to have a valid Uniswap router or it will revert. Excess tokens from the swap as a result
    /// of slippage are in terms of the token in.
    /// @param params Struct that contains all the relevant parameters. See `YodlUniswapParams` for more details.
    /// @return The amount spent in terms of token in by Uniswap to complete this payment
    function yodlWithPancake(YodlUniswapParams calldata params) external payable returns (uint256) {
        return this.yodlWithUniswap(params);
    }
}
