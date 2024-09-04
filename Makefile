-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std

# Update Dependencies
update:; forge update

build:; forge build

snapshot :; forge snapshot

format :; forge fmt

# skip forking tests
test :; forge test --no-match-test Fork

# integration tests
test-fork :; forge test --fork-url ${RPC_URL} --fork-block-number ${BLOCK_NUMBER} --match-test Fork

coverage :; forge coverage --fork-url ${RPC_URL} --fork-block-number ${BLOCK_NUMBER}

coverage-debug :; forge coverage --fork-url ${RPC_URL} --fork-block-number ${BLOCK_NUMBER} --report debug

test-all: test test-fork

start-anvil :; nohup anvil --fork-url=${RPC_URL} --fork-block-number ${BLOCK_NUMBER} &

stop-testnet :; pkill anvil

gas-report :; forge test --gas-report

slither :; slither ./src 

anvil :; anvil -m 'test test test test test test test test test test test junk'


# This is NOT READY YET but can be used as a template for future configurations.
# Will deploy the YodlUniswapHarness contract to anvil or Sepolia (if --network sepolia is passed)
# NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
# 	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# endif

# deploy:
# 	@forge script script/DeployYodlUniswapRouter.s.sol:DeployYodlUniswapRouter $(NETWORK_ARGS)
