#!/bin/bash
### Deploy to Base and verify contract sources
forge create --rpc-url https://mainnet.base.org --verify --verifier-url https://api.basescan.org/api --interactive --etherscan-api-key 3VKX8G4B2D6SXFCBFZJT6HSZ138JXQZ4IN --chain 8453 src/chains/BaseYodlRouter.sol:YodlRouter

### Deploy to Polygon and verify contract sources
forge create --rpc-url https://polygon-rpc.com --verify --verifier-url https://api.polygonscan.com/api --interactive --etherscan-api-key K943G66H5F95GDXCA2W9YY882H5XR85FI7 --chain 137 src/chains/PolygonYodlRouter.sol:YodlRouter

### Deploy to Ethereum and verify contract sources
forge create --rpc-url https://ethereum-rpc.publicnode.com --verify --interactive --etherscan-api-key M6Y54YF9QH6KBEYHKPQGTKU47QCPT5JGM2 --chain 1 src/chains/EthereumYodlRouter.sol:YodlRouter

### Deploy to Gnosis and verify contract sources
forge create --rpc-url https://rpc.gnosischain.com --verify --verifier-url https://api.gnosisscan.io/api --interactive --etherscan-api-key Z7ADQP2JRDII511CJUD4YDRXEUS12QUNKD --chain 100 src/chains/GnosisYodlRouter.sol:YodlRouter

### Deploy to Optimism and verify contract sources
forge create --rpc-url https://mainnet.optimism.io --verify --verifier-url https://api-optimistic.etherscan.io/api --interactive --etherscan-api-key 93ITRJAAFTSIUHVSGTXZ6KI5X6JN2C2ISZ --chain 10 src/chains/OptimismYodlRouter.sol:YodlRouter

### Deploy to Arbitrum One and verify contract sources
forge create --rpc-url https://arb1.arbitrum.io/rpc --verify --verifier-url https://api.arbiscan.io/api --interactive --etherscan-api-key U516IXEMJA8QJPB8KPKYUB9RKBR88MMH31 --chain 42161 src/chains/ArbitrumOneYodlRouter.sol:YodlRouter

### Deploy to Binance Smart Chain and verify contract sources
forge create --rpc-url https://bsc-dataseed1.binance.org/ --verify --verifier-url https://api.bscscan.com/api --interactive --etherscan-api-key BIEUE31QJY51WP25C3UHKYBSCYX61KHG5R --chain 56 src/chains/BscYodlRouter.sol:YodlRouter

