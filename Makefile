# Meta Index Protocol - Development Commands

.PHONY: help install build test test-unit test-integration test-fork deploy clean

help:
	@echo "Meta Index Protocol - Available Commands:"
	@echo "  make install          - Install dependencies"
	@echo "  make build            - Build contracts"
	@echo "  make test             - Run all tests"
	@echo "  make test-unit        - Run unit tests only"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-fork        - Run fork tests"
	@echo "  make coverage         - Generate coverage report"
	@echo "  make gas-report       - Generate gas usage report"
	@echo "  make deploy-local     - Deploy to local Anvil"
	@echo "  make deploy-testnet   - Deploy to Arbitrum Sepolia"
	@echo "  make clean            - Clean build artifacts"

install:
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.0 --no-commit
	forge install foundry-rs/forge-std --no-commit

build:
	forge build

test:
	forge test -vvv

test-unit:
	forge test --match-path "test/unit/**/*.sol" -vvv

test-integration:
	forge test --match-path "test/integration/**/*.sol" -vvv

test-fork:
	forge test --match-path "test/fork/**/*.sol" --fork-url ${ARBITRUM_RPC_URL} -vvv

coverage:
	forge coverage --report lcov
	genhtml lcov.info -o coverage

gas-report:
	forge test --gas-report

deploy-local:
	forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

deploy-testnet:
	forge script script/Deploy.s.sol --rpc-url ${ARBITRUM_SEPOLIA_RPC} --broadcast --verify

clean:
	forge clean
	rm -rf cache out coverage lcov.info
