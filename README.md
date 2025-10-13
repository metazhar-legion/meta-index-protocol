# Meta Index Protocol - Phase 1

> Non-custodial, DAO-governed index fund protocol bringing institutional-grade diversification to DeFi.

## Overview

Meta Index Protocol enables users to gain diversified exposure to crypto, DeFi, and tokenized real-world assets through automated, rules-based index strategies.

**Phase 1A Status:** COMPLETED - Core vault infrastructure deployed

**Current Deployment:** Local development

## Architecture

```
MetaIndexVault (ERC-4626)
    ↓
 StrategyManager (Coming in Phase 1B)
    ↓
Strategies (Crypto, DeFi, RWA, Yield)
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

### Test Results

```
21 tests passed | 0 failed | 0 skipped
- Unit tests: 19 passed
- Fuzz tests: 2 passed (256 runs each)
- Multi-user tests: included
- Event emission tests: included
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
├── mocks/
│   └── MockERC20.sol           # Testing token ✅
├── strategies/                 # Coming in Phase 1B
├── oracle/                     # Coming in Phase 1C
├── interfaces/                 # Coming in Phase 1B
└── libraries/                  # Coming in Phase 1D

test/
├── unit/
│   └── MetaIndexVault.t.sol   # Vault tests ✅
├── integration/                # Coming in Phase 1B
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

## Next Steps - Phase 1B (Week 2-3)

- [ ] Strategy system interfaces
- [ ] BaseStrategy implementation
- [ ] MockStrategy for testing
- [ ] StrategyManager contract
- [ ] Integration with vault

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
