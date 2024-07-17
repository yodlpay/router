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

5. **[Polygon|Ethereum|Gnosis|Base|Optimism|ArbitrumOne]YodlRouter.sol**
    - Inherits from `YodlTransferRouter`, `YodlCurveRouter`, and `YodlUniswapRouter`.
    - Provides a specific implementation for every supported blockchain network.
    - Initializes the necessary router contracts for regular, Curve, and Uniswap payments.

### Deployment

Deployment to various networks is automated using the following scripts:

### Deploy to Base and verify contract sources
```bash
forge create --rpc-url https://mainnet.base.org --verify --verifier-url https://api.basescan.org/api --interactive --etherscan-api-key 3VKX8G4B2D6SXFCBFZJT6HSZ138JXQZ4IN --chain 8453 src/chains/BaseYodlRouter.sol:YodlRouter
```

### Deploy to Polygon and verify contract sources
```bash
forge create --rpc-url https://polygon-rpc.com --verify --verifier-url https://api.polygonscan.com/api --interactive --etherscan-api-key K943G66H5F95GDXCA2W9YY882H5XR85FI7 --chain 137 src/chains/PolygonYodlRouter.sol:YodlRouter
```

### Deploy to Ethereum and verify contract sources
```bash
forge create --rpc-url https://ethereum-rpc.publicnode.com --verify --interactive --etherscan-api-key M6Y54YF9QH6KBEYHKPQGTKU47QCPT5JGM2 --chain 1 src/chains/EthereumYodlRouter.sol:YodlRouter
```

### Deploy to Gnosis and verify contract sources
```bash
forge create --rpc-url https://rpc.gnosischain.com --verify --verifier-url https://api.gnosisscan.io/api --interactive --etherscan-api-key Z7ADQP2JRDII511CJUD4YDRXEUS12QUNKD --chain 100 src/chains/GnosisYodlRouter.sol:YodlRouter
```

### Deploy to Optimism and verify contract sources
```bash
forge create --rpc-url https://mainnet.optimism.io --verify --verifier-url https://api-optimistic.etherscan.io/api --interactive --etherscan-api-key 93ITRJAAFTSIUHVSGTXZ6KI5X6JN2C2ISZ --chain 10 src/chains/OptimismYodlRouter.sol:YodlRouter
```

### Deploy to Arbitrum One and verify contract sources
```bash
forge create --rpc-url https://arb1.arbitrum.io/rpc --verify --verifier-url https://api.arbiscan.io/api --interactive --etherscan-api-key U516IXEMJA8QJPB8KPKYUB9RKBR88MMH31 --chain 42161 src/chains/ArbitrumOneYodlRouter.sol:YodlRouter
```

## License
The YodlRouter is released under the [BSL-1.1 License](https://mariadb.com/bsl-faq-adopting/#whatis).