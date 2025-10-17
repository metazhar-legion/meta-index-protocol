# Meta Index Protocol - Setup Guide

> Complete setup instructions for developers working on the Meta Index Protocol

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Development Workflow](#development-workflow)
- [Common Commands](#common-commands)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

1. **Foundry** (Solidity development framework)
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Git** (version control)
   ```bash
   git --version
   ```

3. **Node.js** (v18 or higher) - Optional, for formatting
   ```bash
   node --version
   npm --version
   ```

### Verify Installation

```bash
# Check Foundry tools
forge --version
cast --version
anvil --version

# You should see versions like:
# forge 0.2.0
# cast 0.2.0
# anvil 0.2.0
```

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/meta-index-protocol.git
cd meta-index-protocol
```

### 2. Install Dependencies

```bash
# Install Forge dependencies (OpenZeppelin, forge-std)
forge install

# Alternative: Use make
make install
```

This will install:
- `OpenZeppelin/openzeppelin-contracts@v5.0.0`
- `foundry-rs/forge-std`

### 3. Build the Project

```bash
# Compile all contracts
forge build

# Or using make
make build
```

Expected output:
```
[⠊] Compiling...
[⠒] Compiling X files with Solc 0.8.24
[⠢] Solc 0.8.24 finished in XXXms
Compiler run successful!
```

### 4. Run Tests

```bash
# Run full test suite
forge test

# Or using make
make test
```

Expected output:
```
Ran 7 test suites: 135 tests passed, 0 failed, 0 skipped
```

---

## Project Structure

```
meta-index-protocol/
├── foundry.toml              # Foundry configuration
├── Makefile                  # Build automation
├── .env.example              # Environment template
├── .gitignore                # Git ignore rules
│
├── src/                      # Smart contracts
│   ├── MetaIndexVault.sol         # Main vault (ERC-4626)
│   ├── StrategyManager.sol        # Strategy orchestration
│   │
│   ├── interfaces/
│   │   ├── IStrategy.sol
│   │   ├── IStrategyManager.sol
│   │   ├── IPriceOracle.sol
│   │   └── ISwapRouter.sol
│   │
│   ├── strategies/
│   │   ├── BaseStrategy.sol       # Abstract base
│   │   └── MockStrategy.sol       # Testing strategy
│   │
│   ├── oracle/
│   │   └── PriceOracle.sol        # Chainlink integration
│   │
│   ├── libraries/
│   │   └── RebalanceLib.sol       # Rebalancing logic
│   │
│   └── mocks/                     # Testing mocks
│       ├── MockERC20.sol
│       ├── MockPriceOracle.sol
│       └── MockSwapRouter.sol
│
├── test/                     # Test files
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests
│   ├── fork/                      # Fork tests (Phase 1E)
│   └── helpers/                   # Test utilities
│
├── script/                   # Deployment scripts (Phase 1E)
│
└── docs/                     # Documentation
    ├── SETUP.md                   # This file
    ├── TESTING.md                 # Testing guide
    └── meta_index_spec.md         # Technical specification
```

---

## Configuration

### Environment Setup

1. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

2. **Edit .env file**
   ```bash
   # Open in your editor
   vim .env
   # or
   code .env
   ```

3. **Set required variables**
   ```bash
   # RPC URLs (for testnet deployment - Phase 1E)
   ARBITRUM_SEPOLIA_RPC=https://sepolia-rollup.arbitrum.io/rpc
   ARBITRUM_MAINNET_RPC=https://arb1.arbitrum.io/rpc

   # API Keys
   ARBISCAN_API_KEY=your_api_key_here

   # Private Keys (NEVER commit real keys!)
   DEPLOYER_PRIVATE_KEY=0x...

   # Addresses (will be set after deployment)
   USDC_ARBITRUM_SEPOLIA=0x...
   ```

### Foundry Configuration

The `foundry.toml` file contains project configuration:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 1000000
via_ir = false

# Testing
verbosity = 3
fuzz_runs = 256
ffi = false

# Formatting
line_length = 100
tab_width = 4
bracket_spacing = false
```

You can modify these settings as needed for your development environment.

---

## Development Workflow

### Standard Development Cycle

1. **Create a new branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Write/modify contracts**
   ```bash
   # Edit files in src/
   vim src/YourContract.sol
   ```

3. **Write tests**
   ```bash
   # Create test file
   vim test/unit/YourContract.t.sol
   ```

4. **Build and test**
   ```bash
   # Compile contracts
   forge build

   # Run tests
   forge test

   # Check test coverage
   forge coverage
   ```

5. **Fix any issues**
   ```bash
   # Run specific test for debugging
   forge test --match-test test_yourFunction -vvvv
   ```

6. **Check gas usage**
   ```bash
   forge test --gas-report
   ```

7. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add your feature"
   ```

8. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Formatting

```bash
# Format Solidity files
forge fmt

# Check formatting without modifying
forge fmt --check
```

### Local Development Server

```bash
# Start local Ethereum node (Anvil)
anvil

# In another terminal, run tests against local node
forge test --rpc-url http://localhost:8545
```

---

## Common Commands

### Makefile Commands

We provide a Makefile for convenience:

```bash
# Show available commands
make help

# Install dependencies
make install

# Build contracts
make build

# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests only
make test-integration

# Generate coverage report
make coverage

# Generate gas report
make gas-report

# Clean build artifacts
make clean

# Deploy to local node (Phase 1E)
make deploy-local

# Deploy to testnet (Phase 1E)
make deploy-testnet
```

### Forge Commands

#### Building

```bash
# Compile all contracts
forge build

# Force recompilation
forge build --force

# Show contract sizes
forge build --sizes
```

#### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test
forge test --match-test test_deposit_success

# Run specific contract
forge test --match-contract MetaIndexVaultTest

# Run specific path
forge test --match-path test/unit/MetaIndexVault.t.sol

# Run with gas report
forge test --gas-report

# Generate coverage
forge coverage
```

#### Inspection

```bash
# Show contract interface
forge inspect MetaIndexVault abi

# Show storage layout
forge inspect MetaIndexVault storage-layout

# Show compiled bytecode
forge inspect MetaIndexVault bytecode
```

#### Utilities

```bash
# Format all Solidity files
forge fmt

# Create snapshot of current gas usage
forge snapshot

# Compare with previous snapshot
forge snapshot --diff

# Clean build artifacts
forge clean
```

### Cast Commands (Blockchain Interaction)

```bash
# Get balance
cast balance 0x... --rpc-url $RPC_URL

# Call view function
cast call CONTRACT_ADDRESS "balanceOf(address)" ADDRESS --rpc-url $RPC_URL

# Send transaction
cast send CONTRACT_ADDRESS "deposit(uint256)" 1000000 --rpc-url $RPC_URL --private-key $KEY

# Convert units
cast to-wei 1 ether
cast from-wei 1000000000000000000

# Get block number
cast block-number --rpc-url $RPC_URL
```

---

## IDE Setup

### Visual Studio Code

**Recommended Extensions:**
- Solidity (Juan Blanco)
- Solidity Visual Developer
- Prettier - Code formatter
- GitLens

**Settings (.vscode/settings.json):**
```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.24",
  "solidity.formatter": "forge",
  "editor.formatOnSave": true,
  "[solidity]": {
    "editor.defaultFormatter": "JuanBlanco.solidity"
  }
}
```

### Vim/Neovim

Install vim-solidity plugin:
```vim
Plug 'tomlion/vim-solidity'
```

---

## Troubleshooting

### Common Issues

#### 1. "Library not found" error

**Problem:**
```
Error: Library not found: @openzeppelin/contracts/...
```

**Solution:**
```bash
# Reinstall dependencies
rm -rf lib/
forge install

# Or use remappings
forge remappings > remappings.txt
```

#### 2. "Out of stack" error

**Problem:**
```
CompilerError: Stack too deep
```

**Solution:**
- Reduce local variables
- Use structs to group related data
- Enable via-ir in foundry.toml:
  ```toml
  via_ir = true
  ```

#### 3. Tests failing after dependency update

**Solution:**
```bash
# Clean and rebuild
forge clean
forge build

# Update dependencies to specific versions
forge update lib/openzeppelin-contracts --tag v5.0.0
```

#### 4. "Transaction reverted" without reason

**Solution:**
```bash
# Run test with maximum verbosity
forge test --match-test test_name -vvvvv
```

#### 5. Gas limit exceeded in tests

**Solution:**
```bash
# Increase gas limit
forge test --gas-limit 30000000
```

### Getting Help

1. **Check Documentation**
   - [TESTING.md](./TESTING.md) - Testing guide
   - [README.md](./README.md) - Project overview
   - [meta_index_spec.md](./meta_index_spec.md) - Technical spec

2. **Foundry Resources**
   - [Foundry Book](https://book.getfoundry.sh/)
   - [Foundry GitHub](https://github.com/foundry-rs/foundry)

3. **Community Support**
   - Open a GitHub issue
   - Ask in Discord (coming soon)

---

## Next Steps

Now that you're set up:

1. **Explore the codebase**
   ```bash
   # Read the main vault contract
   cat src/MetaIndexVault.sol

   # Review test examples
   cat test/unit/MetaIndexVault.t.sol
   ```

2. **Run the test suite**
   ```bash
   forge test -vv
   ```

3. **Check out the testing guide**
   ```bash
   cat TESTING.md
   ```

4. **Start building!**
   - Phase 1A-D are complete
   - Phase 1E (deployment) is next
   - See [meta_index_spec.md](./meta_index_spec.md) for details

---

## Quick Reference Card

```bash
# Most common commands
forge build              # Compile contracts
forge test              # Run tests
forge test -vv          # Run with logs
forge fmt               # Format code
forge coverage          # Coverage report
forge clean             # Clean artifacts

# Testing
forge test --match-test test_name    # Specific test
forge test --match-contract Contract # Specific contract
forge test --gas-report             # Gas usage

# Utilities
make help               # Show all commands
forge --help           # Forge help
cast --help            # Cast help
```

---

**Ready to build! 🚀**
