# Meta Index Protocol - Development Commands

.PHONY: help install build test test-unit test-integration test-fork deploy clean format snapshot

help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║         Meta Index Protocol - Available Commands          ║"
	@echo "╠════════════════════════════════════════════════════════════╣"
	@echo "║ SETUP                                                      ║"
	@echo "║  make install          - Install dependencies              ║"
	@echo "║  make build            - Build contracts                   ║"
	@echo "║                                                            ║"
	@echo "║ TESTING                                                    ║"
	@echo "║  make test             - Run all tests (135 tests)         ║"
	@echo "║  make test-unit        - Run unit tests only               ║"
	@echo "║  make test-integration - Run integration tests             ║"
	@echo "║  make test-fork        - Run fork tests (Phase 1E)         ║"
	@echo "║  make coverage         - Generate coverage report          ║"
	@echo "║  make gas-report       - Generate gas usage report         ║"
	@echo "║                                                            ║"
	@echo "║ CODE QUALITY                                               ║"
	@echo "║  make format           - Format Solidity files             ║"
	@echo "║  make snapshot         - Create gas snapshot               ║"
	@echo "║  make snapshot-diff    - Compare with previous snapshot    ║"
	@echo "║                                                            ║"
	@echo "║ DEPLOYMENT (Phase 1E)                                      ║"
	@echo "║  make deploy-local     - Deploy to local Anvil             ║"
	@echo "║  make deploy-testnet   - Deploy to Arbitrum Sepolia        ║"
	@echo "║                                                            ║"
	@echo "║ UTILITIES                                                  ║"
	@echo "║  make clean            - Clean build artifacts             ║"
	@echo "║  make sizes            - Show contract sizes               ║"
	@echo "╚════════════════════════════════════════════════════════════╝"

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

format:
	forge fmt

snapshot:
	forge snapshot

snapshot-diff:
	forge snapshot --diff

sizes:
	forge build --sizes
