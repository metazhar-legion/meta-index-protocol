# Meta Index Protocol - Phase 1

> Non-custodial, DAO-governed index fund protocol bringing institutional-grade diversification to DeFi.

## Overview

Meta Index Protocol enables users to gain diversified exposure to crypto, DeFi, and tokenized real-world assets through automated, rules-based index strategies.

**Phase 1A Status:** ✅ COMPLETED - Core vault infrastructure deployed

**Phase 1B Status:** ✅ COMPLETED - Strategy system implemented

**Phase 1C Status:** ✅ COMPLETED - Price oracle system with Chainlink support (MVP)

**Current Deployment:** Local development

## Architecture

```
MetaIndexVault (ERC-4626) ✅
    ↓
StrategyManager ✅ (with PriceOracle integration)
    ↓
Strategies (BaseStrategy, MockStrategy) ✅
    ↓
PriceOracle (Chainlink) ✅
    ↓
Future: Crypto, DeFi, RWA, Yield Strategies
```

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/meta-index-protocol
cd meta-index-protocol

# Install dependencies
make install

# Copy environment file
cp .env.example .env
```

### Build

```bash
make build
```

### Test

```bash
# Run all tests
make test

# Run specific test suites
make test-unit

# Generate gas report
make gas-report
```

## Phase 1A Implementation (COMPLETED)

### Implemented Features

- ERC-4626 compliant vault (src/MetaIndexVault.sol:1)
- Deposit/withdraw functionality with safety checks
- Access control (Admin, Manager, Guardian roles)
- Emergency pause mechanism
- TVL caps for phased rollout
- Comprehensive test suite (21 tests, all passing)

## Phase 1B Implementation (COMPLETED)

### Implemented Features

- Strategy system interfaces (src/interfaces/IStrategy.sol:1, src/interfaces/IStrategyManager.sol:1)
- BaseStrategy abstract contract (src/strategies/BaseStrategy.sol:1)
- MockStrategy for testing (src/strategies/MockStrategy.sol:1)
- StrategyManager orchestration layer (src/StrategyManager.sol:1)
- Strategy allocation and deallocation
- Multi-strategy support with percentage allocations
- Integration tests for full vault → manager → strategy flow

### Test Results (Phase 1B)

```
91 tests passed | 0 failed | 0 skipped
- Phase 1A (Vault): 21 tests passed
- Phase 1B (Strategy): 26 tests passed
- Phase 1B (Manager): 33 tests passed
- Integration tests: 11 tests passed
- Fuzz tests: 3 passed (256 runs each)
```

## Phase 1C Implementation (COMPLETED - MVP)

### Implemented Features

- IPriceOracle interface (src/interfaces/IPriceOracle.sol:1)
- PriceOracle with Chainlink integration (src/oracle/PriceOracle.sol:1)
- MockPriceOracle for testing (src/mocks/MockPriceOracle.sol:1)
- Price normalization to 8 decimals
- Staleness checks (24-hour threshold)
- USD valuation for multi-asset strategies
- StrategyManager integration with optional price oracle

### Test Results (Phase 1C)

```
105 tests passed | 0 failed | 0 skipped
- Phase 1A (Vault): 21 tests passed
- Phase 1B (Strategy): 26 tests passed
- Phase 1B (Manager): 33 tests passed
- Phase 1C (Oracle): 14 tests passed
- Integration tests: 11 tests passed
- Fuzz tests: 5 passed (256 runs each)
```

### Gas Benchmarks (Oracle Operations)

| Operation | Gas Used | Notes |
|-----------|----------|-------|
| getPrice | ~813 avg | Price lookup from mock oracle |
| getValue | ~6,525 avg | USD value calculation |
| setPrice | ~66,276 avg | One-time setup per asset |
| setPriceFeed | ~45,912 | Configure Chainlink feed |

### Gas Benchmarks (Phase 1A)

| Operation | Gas Used | Target | Status |
|-----------|----------|--------|--------|
| Deposit (first) | 119,223 | 150k | ✅ |
| Deposit (subsequent) | 117,710 | 130k | ✅ |
| Withdraw | 131,209 | 120k | ⚠️ (slightly over, will optimize) |

## Project Structure

```
src/
├── MetaIndexVault.sol          # Main vault (ERC-4626) ✅
├── StrategyManager.sol         # Strategy orchestration ✅
├── interfaces/
│   ├── IStrategy.sol           # Strategy interface ✅
│   ├── IStrategyManager.sol    # Manager interface ✅
│   └── IPriceOracle.sol        # Oracle interface ✅
├── strategies/
│   ├── BaseStrategy.sol        # Strategy base class ✅
│   └── MockStrategy.sol        # Testing strategy ✅
├── oracle/
│   └── PriceOracle.sol         # Chainlink oracle integration ✅
├── mocks/
│   ├── MockERC20.sol           # Testing token ✅
│   └── MockPriceOracle.sol     # Testing oracle ✅
└── libraries/                  # Coming in Phase 1D

test/
├── unit/
│   ├── MetaIndexVault.t.sol   # Vault tests ✅
│   ├── MockStrategy.t.sol     # Strategy tests ✅
│   ├── StrategyManager.t.sol  # Manager tests ✅
│   └── MockPriceOracle.t.sol  # Oracle tests ✅
├── integration/
│   └── FullFlow.t.sol         # End-to-end tests ✅
├── fork/                       # Coming in Phase 1E
└── helpers/
    └── TestHelpers.sol         # Test utilities ✅
```

## Development Commands

```bash
# Build contracts
make build

# Run all tests
make test

# Run only unit tests
make test-unit

# Generate coverage report
make coverage

# Generate gas report
make gas-report

# Clean build artifacts
make clean
```

## Phase 1C Completion

Phase 1C has been successfully completed with:
- ✅ Price oracle system (IPriceOracle interface)
- ✅ Chainlink adapter for real-time pricing
- ✅ Mock price feeds for testing
- ✅ Price validation and staleness checks
- ✅ Integration with StrategyManager for USD valuations

## Next Steps - Phase 1D (Week 5-6)

- [ ] Portfolio rebalancing logic
- [ ] Automated rebalancer contract
- [ ] Time-based and threshold-based triggers
- [ ] Gas-optimized batch operations
- [ ] Emergency shutdown mechanisms

## Security

⚠️ **This code is unaudited and under active development. Do not use with real funds.**

Security measures implemented:
- Comprehensive test suite with fuzz testing (105 tests)
- Access control on all admin functions (OpenZeppelin AccessControl)
- Reentrancy guards on deposit/withdraw operations
- Emergency pause mechanism
- TVL caps to limit exposure during phased rollout
- Custom errors for gas optimization
- Price staleness checks (24-hour threshold)
- Chainlink oracle validation (round ID checks)
- Optional oracle support for single-asset vaults

## Contributing

Phase 1 is currently in active development. We welcome:
- Bug reports
- Test improvements
- Documentation updates
- Code reviews

## License

MIT License - see LICENSE file for details

## Documentation

- [Technical Specification](./meta_index_spec.md)
- [Foundry Book](https://book.getfoundry.sh/)

---

Built with [Foundry](https://getfoundry.sh/) and [OpenZeppelin](https://www.openzeppelin.com/)
