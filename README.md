# YodlRouter

## Overview

The YodlRouter is an onchain payment system designed to facilitate payments with flexible token handling, leveraging multiple DeFi protocols. The system allows users to make payments using various tokens,
with the option of performing token swaps via Curve or Uniswap to settle the payment in the desired token. It supports both native tokens (such as ETH, xDAI, MATIC) and ERC20 tokens, and includes functionality for currency conversion using Chainlink price feeds.

## Code Structure

### Contracts

1. **AbstractYodlRouter.sol**

   - The base abstract contract that provides common functionality for the YodlRouter system.
   - Manages fee calculations, price feed integrations, and token transfers.
   - Contains events for logging transactions and conversions.

2. **YodlTransferRouter.sol**

   - Extends `AbstractYodlRouter`.
   - Handles payments with native tokens and ERC20 tokens without any DEX (Decentralized Exchange) interactions.

3. **YodlCurveRouter.sol**

   - Extends `AbstractYodlRouter`.
   - Integrates with Curve Finance for token swaps.
   - Handles complex swap routes and supports currency conversions using price feeds.

4. **YodlUniswapRouter.sol**

   - Extends `AbstractYodlRouter`.
   - Integrates with Uniswap V3 for token swaps.
   - Supports single-hop and multi-hop swaps, with the option to handle native tokens.

5. **YodlPancakeRouter.sol**
   - Extends `YodlUniswapRouter`.
   - Integrates with Pancake V3 for token swaps on BSC chain.
   - Supports single-hop and multi-hop swaps, with the option to handle native tokens.

6**[Polygon|Ethereum|Gnosis|Base|Optimism|ArbitrumOne|Bsc]YodlRouter.sol** - Inherits from `YodlTransferRouter`, `YodlCurveRouter`, and `YodlUniswapRouter`. - Provides a specific implementation for every supported blockchain network. - Initializes the necessary router contracts for regular, Curve, Uniswap and Pancakeswap payments.

### Deployment

Deployment to various networks is automated using the script [deploy_router.sh](./deploy_scripts/deploy_router.sh).

## yApps - Decentralized Extensions to the YodlRouter

### Overview

yApps are decentralized extensions integrated into the YodlRouter ecosystem to add an extra layer of logic before executing any operations. These extensions are designed to run a pre-check using the beforeHook method to ensure compliance with external rules or conditions before proceeding with the regular transaction flow. If the conditions are not met, the hook will revert, preventing the operation from executing.

### Chainalysis Sanctioned OFAC List Extension

One practical example of a yApp is the Chainalysis Sanctioned OFAC List Extension. This extension leverages the Chainalysis Oracle to check if the sender of a transaction is on the sanctioned list maintained by the Office of Foreign Assets Control (OFAC). The beforeHook method in this extension ensures that transactions initiated by sanctioned addresses are blocked, enhancing compliance with global sanctions regulations.

#### How It Works

##### Integration with YodlRouter:

- The beforeHook method is integrated into the yodlWithToken, yodlWithUniswap, and yodlWithCurve functions of the YodlRouter.
  Before any operation within these functions, the beforeHook method of the yApp is called.
  Chainalysis Sanctioned OFAC List Extension Logic:

- The extension contract, ChainalysisOfacExtension, implements the IBeforeHook interface.
  It uses the Chainalysis Oracle to check if the sender's address is sanctioned.
  If the sender is sanctioned, the transaction is reverted with the message "sender is sanctioned".

### Deployment

Deployment to various networks is automated using the script [deploy_ofac.sh](./deploy_scripts/deploy_ofac.sh).

### Current deployments

- [Ethereum](https://etherscan.io/address/0x5a1564F9B26493311A7bF6cCA0873E8Bb093C4f6)
- [Gnosis](https://gnosisscan.io/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)
- [Polygon](https://polygonscan.com/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)
- [Optimism](https://optimistic.etherscan.io/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)
- [Arbitrum One](https://arbiscan.io/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)
- [Base](https://basescan.org/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)
- [BNB Smart Chain](https://bscscan.com/address/0xfe59623823F45489e228BDE6912875cD9EEF143b)

## License

The YodlRouter is released under the [BSL-1.1 License](https://mariadb.com/bsl-faq-adopting/#whatis).
