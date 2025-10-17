# Meta Index Protocol - Testing Guide

> Comprehensive guide for testing the Meta Index Protocol smart contracts

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)
- [Writing New Tests](#writing-new-tests)
- [CI/CD Integration](#cicd-integration)

---

## Overview

The Meta Index Protocol uses **Foundry** as its testing framework. Our test suite includes:

- **Unit Tests**: Test individual contract functions in isolation
- **Integration Tests**: Test interactions between multiple contracts
- **Fuzz Tests**: Property-based testing with random inputs
- **Gas Benchmarking**: Track gas usage for operations

### Current Test Stats

```
Total Tests: 135
- Unit Tests: 108
- Integration Tests: 27
- Fuzz Tests: 7
Success Rate: 100%
```

---

## Test Structure

```
test/
├── unit/                           # Unit tests
│   ├── MetaIndexVault.t.sol       # Vault tests (21 tests)
│   ├── MockStrategy.t.sol         # Strategy tests (26 tests)
│   ├── StrategyManager.t.sol      # Manager tests (33 tests)
│   ├── MockPriceOracle.t.sol      # Oracle tests (14 tests)
│   └── RebalanceLib.t.sol         # Rebalancing library (14 tests)
│
├── integration/                    # Integration tests
│   ├── FullFlow.t.sol             # End-to-end flows (11 tests)
│   └── Rebalancing.t.sol          # Rebalancing integration (16 tests)
│
├── fork/                           # Fork tests (Phase 1E)
│   └── (Coming soon)
│
└── helpers/                        # Test utilities
    └── TestHelpers.sol
```

---

## Running Tests

### Prerequisites

```bash
# Ensure Foundry is installed
forge --version

# If not installed:
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Basic Commands

#### Run All Tests

```bash
forge test
```

#### Run with Verbosity

```bash
# -v: Show test names
forge test -v

# -vv: Show test names + logs
forge test -vv

# -vvv: Show test names + logs + stack traces
forge test -vvv

# -vvvv: Show test names + logs + stack traces + setup traces
forge test -vvvv

# -vvvvv: Maximum verbosity (includes internal calls)
forge test -vvvvv
```

#### Run Specific Test Suites

```bash
# Run only unit tests
forge test --match-path "test/unit/**/*.sol"

# Run only integration tests
forge test --match-path "test/integration/**/*.sol"

# Run specific test file
forge test --match-path test/unit/MetaIndexVault.t.sol

# Run specific test contract
forge test --match-contract MetaIndexVaultTest
```

#### Run Specific Tests

```bash
# Run tests matching a pattern
forge test --match-test test_deposit

# Run a specific test function
forge test --match-test test_deposit_success

# Run multiple patterns
forge test --match-test "test_deposit|test_withdraw"
```

### Advanced Testing

#### Gas Reporting

```bash
# Generate gas report for all tests
forge test --gas-report

# Gas report for specific contract
forge test --gas-report --match-contract MetaIndexVault

# Save gas report to file
forge test --gas-report > gas-report.txt
```

#### Fuzz Testing

```bash
# Run with custom fuzz runs (default: 256)
forge test --fuzz-runs 1000

# Run specific fuzz test
forge test --match-test testFuzz
```

#### Coverage

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage with lcov
forge coverage --report lcov

# Generate HTML coverage report
forge coverage --report lcov && genhtml lcov.info -o coverage

# Open coverage report in browser
open coverage/index.html
```

#### Watch Mode

```bash
# Automatically re-run tests on file changes
forge test --watch

# Watch specific path
forge test --watch test/unit/
```

---

## Test Coverage

### Phase 1A: MetaIndexVault (21 tests)

| Feature | Coverage | Tests |
|---------|----------|-------|
| Deposit | ✅ 100% | 5 tests + 1 fuzz |
| Withdraw | ✅ 100% | 3 tests + 1 fuzz |
| Share Conversion | ✅ 100% | 2 tests |
| Admin Functions | ✅ 100% | 5 tests |
| Access Control | ✅ 100% | 3 tests |
| Pause Mechanism | ✅ 100% | 2 tests |

### Phase 1B: Strategy System (59 tests)

| Component | Coverage | Tests |
|-----------|----------|-------|
| MockStrategy | ✅ 100% | 26 tests + 2 fuzz |
| StrategyManager | ✅ 100% | 33 tests |
| Strategy Lifecycle | ✅ 100% | Add, remove, update |
| Allocations | ✅ 100% | Deposit, withdraw |
| Access Control | ✅ 100% | Role-based checks |

### Phase 1C: Price Oracle (14 tests)

| Feature | Coverage | Tests |
|---------|----------|-------|
| Price Setting | ✅ 100% | 3 tests + 1 fuzz |
| Price Retrieval | ✅ 100% | 4 tests |
| Value Calculation | ✅ 100% | 4 tests + 1 fuzz |
| Price Feed Management | ✅ 100% | 2 tests |

### Phase 1D: Rebalancing (30 tests)

| Feature | Coverage | Tests |
|---------|----------|-------|
| RebalanceLib | ✅ 100% | 14 tests + 1 fuzz |
| Rebalancing Execution | ✅ 100% | 16 tests + 1 fuzz |
| Deviation Detection | ✅ 100% | Threshold-based |
| Multi-Strategy | ✅ 100% | 2+ strategies |

### Integration Tests (11 tests)

| Flow | Coverage | Tests |
|------|----------|-------|
| Deposit → Allocate → Withdraw | ✅ 100% | 3 tests + 1 fuzz |
| Multi-User Scenarios | ✅ 100% | 2 tests |
| Multi-Strategy | ✅ 100% | 2 tests |
| Edge Cases | ✅ 100% | 3 tests |

---

## Writing New Tests

### Test Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {YourContract} from "../../src/YourContract.sol";

contract YourContractTest is Test {
    YourContract public contract;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        // Deploy contracts
        contract = new YourContract();

        // Setup initial state
        // ...
    }

    // ============ FEATURE TESTS ============

    function test_featureName_success() public {
        // Arrange
        uint256 amount = 1000e6;

        // Act
        vm.prank(alice);
        contract.someFunction(amount);

        // Assert
        assertEq(contract.getValue(), amount);
    }

    function test_featureName_revertsOnError() public {
        // Arrange
        uint256 invalidAmount = 0;

        // Act & Assert
        vm.expectRevert(YourContract.SomeError.selector);
        contract.someFunction(invalidAmount);
    }

    // ============ FUZZ TESTS ============

    function testFuzz_featureName(uint256 amount) public {
        // Bound inputs
        amount = bound(amount, 1, 1_000_000e6);

        // Test logic
        contract.someFunction(amount);

        // Assert invariants
        assertGe(contract.getValue(), 0);
    }
}
```

### Best Practices

#### 1. Test Organization

```solidity
// Group tests by feature
// ============ FEATURE NAME ============

// Test happy path first
function test_feature_success() public { }

// Then test error cases
function test_feature_revertsOnError() public { }

// Test edge cases
function test_feature_edgeCase() public { }

// Fuzz tests last
function testFuzz_feature(uint256 input) public { }
```

#### 2. Naming Conventions

```solidity
// Unit tests: test_functionName_scenario
function test_deposit_success() public { }
function test_deposit_revertsWhenPaused() public { }

// Integration tests: test_flow_scenario
function test_fullFlow_depositAndWithdraw() public { }

// Fuzz tests: testFuzz_functionName
function testFuzz_deposit(uint256 amount) public { }
```

#### 3. Use Cheatcodes Effectively

```solidity
// Prank (single call)
vm.prank(alice);
contract.deposit(amount);

// StartPrank (multiple calls)
vm.startPrank(alice);
contract.deposit(amount);
contract.withdraw(amount);
vm.stopPrank();

// Expect revert
vm.expectRevert(Contract.CustomError.selector);
contract.failingFunction();

// Expect emit
vm.expectEmit(true, true, true, true);
emit Contract.SomeEvent(alice, amount);
contract.emittingFunction(amount);

// Warp time
vm.warp(block.timestamp + 1 days);

// Deal tokens
deal(address(token), alice, 1000e6);
```

#### 4. Arrange-Act-Assert Pattern

```solidity
function test_feature() public {
    // Arrange: Setup test conditions
    uint256 amount = 1000e6;
    usdc.mint(alice, amount);

    // Act: Execute the function being tested
    vm.startPrank(alice);
    usdc.approve(address(vault), amount);
    uint256 shares = vault.deposit(amount, alice);
    vm.stopPrank();

    // Assert: Verify expected outcomes
    assertEq(vault.balanceOf(alice), shares);
    assertEq(vault.totalAssets(), amount);
}
```

#### 5. Test State Transitions

```solidity
function test_stateTransition() public {
    // Initial state
    assertEq(contract.state(), State.Initial);

    // Transition
    contract.transition();

    // New state
    assertEq(contract.state(), State.Active);
}
```

### Assertion Helpers

```solidity
// Equality
assertEq(a, b);
assertEq(a, b, "custom error message");

// Inequality
assertTrue(condition);
assertFalse(condition);

// Greater/Less than
assertGt(a, b);  // a > b
assertGe(a, b);  // a >= b
assertLt(a, b);  // a < b
assertLe(a, b);  // a <= b

// Approximate equality (for rounding)
assertApproxEqAbs(a, b, maxDelta);
assertApproxEqRel(a, b, maxPercentDelta);

// Bound fuzz inputs
amount = bound(amount, min, max);
```

---

## Gas Benchmarking

### Current Gas Benchmarks

| Operation | Gas Used | Target | Status |
|-----------|----------|--------|--------|
| **Vault Operations** |
| Deposit (first) | 119,223 | 150k | ✅ |
| Deposit (subsequent) | 117,710 | 130k | ✅ |
| Withdraw | 131,209 | 120k | ⚠️ |
| **Strategy Operations** |
| Allocate to strategy | 190,638 | 200k | ✅ |
| Deallocate from strategy | 202,093 | 250k | ✅ |
| **Rebalancing** |
| Check if rebalancing needed | ~6,500 | 10k | ✅ |
| Execute rebalance (2 strategies) | 421,114 | 500k | ✅ |
| **Oracle Operations** |
| Get price | ~813 | 1k | ✅ |
| Get USD value | ~6,525 | 10k | ✅ |

### Tracking Gas

```bash
# Basic gas report
forge test --gas-report

# Detailed gas report
forge test --gas-report --json > gas-report.json

# Compare gas between branches
forge snapshot
forge snapshot --diff
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Run tests
        run: forge test -vvv

      - name: Generate coverage
        run: forge coverage

      - name: Check gas snapshots
        run: forge snapshot --check
```

---

## Troubleshooting

### Common Issues

#### 1. "Stack too deep" error

**Solution**: Reduce local variables, use structs, or split into multiple functions

```solidity
// Instead of many variables:
function test_complex() public {
    uint256 a = 1;
    uint256 b = 2;
    // ... many more variables
}

// Use a struct:
struct TestData {
    uint256 a;
    uint256 b;
}

function test_complex() public {
    TestData memory data = TestData(1, 2);
}
```

#### 2. "Out of gas" error

**Solution**: Increase gas limit or optimize loops

```bash
# Run with more gas
forge test --gas-limit 30000000
```

#### 3. Fuzz test failures

**Solution**: Add proper bounds to fuzz inputs

```solidity
function testFuzz_deposit(uint256 amount) public {
    // Bound between reasonable values
    amount = bound(amount, vault.minDeposit(), vault.tvlCap());
    // ... rest of test
}
```

---

## Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Foundry Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)
- [Solidity Testing Best Practices](https://ethereum.org/en/developers/docs/smart-contracts/testing/)

---

## Support

For questions or issues:
1. Check this guide
2. Review existing tests for patterns
3. Open a GitHub issue
4. Ask in Discord (coming soon)

---

**Happy Testing! 🧪**
