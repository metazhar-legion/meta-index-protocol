# Meta Index Protocol - Phase 1

> Non-custodial, DAO-governed index fund protocol bringing institutional-grade diversification to DeFi.

## Overview

Meta Index Protocol enables users to gain diversified exposure to crypto, DeFi, and tokenized real-world assets through automated, rules-based index strategies.

**Phase 1A Status:** ✅ COMPLETED - Core vault infrastructure deployed

**Phase 1B Status:** ✅ COMPLETED - Strategy system implemented

**Current Deployment:** Local development

## Architecture

```
MetaIndexVault (ERC-4626) ✅
    ↓
StrategyManager ✅
    ↓
Strategies (BaseStrategy, MockStrategy) ✅
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

### Test Results

```
91 tests passed | 0 failed | 0 skipped
- Phase 1A (Vault): 21 tests passed
- Phase 1B (Strategy): 26 tests passed
- Phase 1B (Manager): 33 tests passed
- Integration tests: 11 tests passed
- Fuzz tests: 3 passed (256 runs each)
```

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
│   └── IStrategyManager.sol    # Manager interface ✅
├── strategies/
│   ├── BaseStrategy.sol        # Strategy base class ✅
│   └── MockStrategy.sol        # Testing strategy ✅
├── mocks/
│   └── MockERC20.sol           # Testing token ✅
├── oracle/                     # Coming in Phase 1C
└── libraries/                  # Coming in Phase 1D

test/
├── unit/
│   ├── MetaIndexVault.t.sol   # Vault tests ✅
│   ├── MockStrategy.t.sol     # Strategy tests ✅
│   └── StrategyManager.t.sol  # Manager tests ✅
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

## Next Steps - Phase 1C (Week 3-4)

- [ ] Price oracle system (IPriceOracle interface)
- [ ] Chainlink adapter for real-time pricing
- [ ] Mock price feeds for testing
- [ ] Price validation and staleness checks
- [ ] Integration with StrategyManager for TVL calculations

## Security

⚠️ **This code is unaudited and under active development. Do not use with real funds.**

Phase 1A security measures:
- Comprehensive test suite with fuzz testing
- Access control on all admin functions
- Reentrancy guards on deposit/withdraw
- Emergency pause mechanism
- TVL caps to limit exposure
- Custom errors for gas optimization

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
