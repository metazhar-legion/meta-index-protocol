// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MetaIndexVault} from "../../src/MetaIndexVault.sol";
import {StrategyManager} from "../../src/StrategyManager.sol";
import {MockStrategy} from "../../src/strategies/MockStrategy.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {RebalanceLib} from "../../src/libraries/RebalanceLib.sol";

/**
 * @title RebalancingTest
 * @notice Integration tests for portfolio rebalancing functionality
 */
contract RebalancingTest is Test {
    MetaIndexVault public vault;
    StrategyManager public manager;
    MockStrategy public strategy1;
    MockStrategy public strategy2;
    MockERC20 public usdc;

    address public alice = makeAddr("alice");
    address public admin;

    uint256 constant INITIAL_USER_BALANCE = 100_000e6;

    function setUp() public {
        admin = address(this);

        // Deploy USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy Vault
        vault = new MetaIndexVault(usdc, "Meta Index Balanced Portfolio", "miBOCP");

        // Deploy StrategyManager
        manager = new StrategyManager(address(vault), address(usdc), address(0));

        // Deploy two strategies
        strategy1 = new MockStrategy(address(vault), address(manager), address(usdc));
        strategy2 = new MockStrategy(address(vault), address(manager), address(usdc));

        // Connect vault to manager
        vault.setStrategyManager(address(manager));

        // Grant manager role to vault
        manager.grantRole(manager.MANAGER_ROLE(), address(vault));

        // Add strategies with 50/50 allocation
        manager.addStrategy(address(strategy1), 5000); // 50%
        manager.addStrategy(address(strategy2), 5000); // 50%

        // Fund alice
        usdc.mint(alice, INITIAL_USER_BALANCE);

        // Update TVL cap
        vault.updateTVLCap(50_000e6);
    }

    // ============ BASIC REBALANCING TESTS ============

    function test_rebalancing_notNeededWhenBalanced() public {
        uint256 depositAmount = 10_000e6;

        // Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate evenly to both strategies (50/50)
        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 5000e6);
        manager.allocateToStrategy(address(strategy2), 5000e6);
        vm.stopPrank();

        // Check that rebalancing is not needed
        assertFalse(manager.needsRebalancing());
    }

    function test_rebalancing_neededWhenImbalanced() public {
        uint256 depositAmount = 10_000e6;

        // Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate unevenly (70/30 instead of 50/50)
        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 7000e6); // 70%
        manager.allocateToStrategy(address(strategy2), 3000e6); // 30%
        vm.stopPrank();

        // Check that rebalancing is needed (deviation > 5%)
        assertTrue(manager.needsRebalancing());
    }

    function test_rebalancing_executesCorrectly() public {
        uint256 depositAmount = 10_000e6;

        // Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate unevenly
        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 7000e6);
        manager.allocateToStrategy(address(strategy2), 3000e6);
        vm.stopPrank();

        assertTrue(manager.needsRebalancing());

        // Execute rebalance
        vm.prank(address(vault));
        manager.rebalance();

        // Check allocations are now balanced
        assertApproxEqAbs(strategy1.totalValue(), 5000e6, 1e6); // Allow 1 USDC tolerance
        assertApproxEqAbs(strategy2.totalValue(), 5000e6, 1e6);

        // Should not need rebalancing anymore
        assertFalse(manager.needsRebalancing());
    }

    function test_rebalancing_revertsWhenNotNeeded() public {
        uint256 depositAmount = 10_000e6;

        // Alice deposits and allocate evenly
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 5000e6);
        manager.allocateToStrategy(address(strategy2), 5000e6);

        // Try to rebalance when not needed
        vm.expectRevert("Rebalancing not needed");
        manager.rebalance();
        vm.stopPrank();
    }

    function test_rebalancing_revertsNonManager() public {
        uint256 depositAmount = 10_000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 7000e6);
        manager.allocateToStrategy(address(strategy2), 3000e6);
        vm.stopPrank();

        // Non-manager tries to rebalance
        vm.prank(alice);
        vm.expectRevert();
        manager.rebalance();
    }

    // ============ ALLOCATION STATES TESTS ============

    function test_getAllocationStates_balanced() public {
        uint256 depositAmount = 10_000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 5000e6);
        manager.allocateToStrategy(address(strategy2), 5000e6);
        vm.stopPrank();

        RebalanceLib.AllocationState[] memory states = manager.getAllocationStates();

        assertEq(states.length, 2);
        assertEq(states[0].targetAllocation, 5000);
        assertEq(states[0].currentAllocation, 5000);
        assertEq(states[0].deviation, 0);

        assertEq(states[1].targetAllocation, 5000);
        assertEq(states[1].currentAllocation, 5000);
        assertEq(states[1].deviation, 0);
    }

    function test_getAllocationStates_imbalanced() public {
        uint256 depositAmount = 10_000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 7000e6);
        manager.allocateToStrategy(address(strategy2), 3000e6);
        vm.stopPrank();

        RebalanceLib.AllocationState[] memory states = manager.getAllocationStates();

        assertEq(states.length, 2);

        // Strategy1 is overweight
        assertEq(states[0].targetAllocation, 5000); // 50% target
        assertEq(states[0].currentAllocation, 7000); // 70% actual
        assertEq(states[0].deviation, 2000); // +20%

        // Strategy2 is underweight
        assertEq(states[1].targetAllocation, 5000); // 50% target
        assertEq(states[1].currentAllocation, 3000); // 30% actual
        assertEq(states[1].deviation, -2000); // -20%
    }

    // ============ DEVIATION THRESHOLD TESTS ============

    function test_setDeviationThreshold_success() public {
        uint256 newThreshold = 1000; // 10%
        manager.setDeviationThreshold(newThreshold);
        assertEq(manager.deviationThreshold(), newThreshold);
    }

    function test_setDeviationThreshold_revertsNonAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        manager.setDeviationThreshold(1000);
    }

    function test_setDeviationThreshold_revertsTooHigh() public {
        vm.expectRevert("Threshold too high");
        manager.setDeviationThreshold(2500); // > 20%
    }

    function test_rebalancing_withCustomThreshold() public {
        // Set higher threshold (10%)
        manager.setDeviationThreshold(1000);

        uint256 depositAmount = 10_000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate with 8% deviation (below new threshold)
        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 5800e6); // 58%
        manager.allocateToStrategy(address(strategy2), 4200e6); // 42%
        vm.stopPrank();

        // Should not need rebalancing with 10% threshold
        assertFalse(manager.needsRebalancing());
    }

    // ============ MINIMUM REBALANCE AMOUNT TESTS ============

    function test_setMinRebalanceAmount_success() public {
        uint256 newMin = 1000e6; // $1000
        manager.setMinRebalanceAmount(newMin);
        assertEq(manager.minRebalanceAmount(), newMin);
    }

    function test_setMinRebalanceAmount_revertsNonAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        manager.setMinRebalanceAmount(1000e6);
    }

    function test_rebalancing_revertsBelowMinimum() public {
        // Set high minimum
        manager.setMinRebalanceAmount(20_000e6);

        uint256 depositAmount = 10_000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy1), 7000e6);
        manager.allocateToStrategy(address(strategy2), 3000e6);

        // Should revert due to total value being below minimum
        vm.expectRevert("Below minimum");
        manager.rebalance();
        vm.stopPrank();
    }

    // ============ MULTI-USER REBALANCING TESTS ============

    function test_rebalancing_withMultipleDeposits() public {
        address bob = makeAddr("bob");
        usdc.mint(bob, INITIAL_USER_BALANCE);

        // Alice deposits $10k
        vm.startPrank(alice);
        usdc.approve(address(vault), 10_000e6);
        vault.deposit(10_000e6, alice);
        vm.stopPrank();

        // Bob deposits $5k
        vm.startPrank(bob);
        usdc.approve(address(vault), 5000e6);
        vault.deposit(5000e6, bob);
        vm.stopPrank();

        // Total: $15k
        // Allocate unevenly
        vm.startPrank(address(vault));
        usdc.approve(address(manager), 15_000e6);
        manager.allocateToStrategy(address(strategy1), 10_000e6); // 66.7%
        manager.allocateToStrategy(address(strategy2), 5000e6); // 33.3%
        vm.stopPrank();

        assertTrue(manager.needsRebalancing());

        // Rebalance
        vm.prank(address(vault));
        manager.rebalance();

        // Check balanced
        assertApproxEqAbs(strategy1.totalValue(), 7500e6, 1e6); // 50%
        assertApproxEqAbs(strategy2.totalValue(), 7500e6, 1e6); // 50%
    }

    // ============ FUZZ TESTS ============

    function testFuzz_rebalancing(uint256 allocation1, uint256 allocation2) public {
        // Bound allocations
        allocation1 = bound(allocation1, 1000e6, 5000e6);
        allocation2 = bound(allocation2, 1000e6, 5000e6);

        uint256 totalDeposit = allocation1 + allocation2;

        // Ensure within TVL cap
        if (totalDeposit > 50_000e6) {
            totalDeposit = 50_000e6;
            allocation1 = totalDeposit / 2;
            allocation2 = totalDeposit - allocation1;
        }

        vm.startPrank(alice);
        usdc.approve(address(vault), totalDeposit);
        vault.deposit(totalDeposit, alice);
        vm.stopPrank();

        // Allocate with potentially imbalanced amounts
        vm.startPrank(address(vault));
        usdc.approve(address(manager), totalDeposit);
        manager.allocateToStrategy(address(strategy1), allocation1);
        manager.allocateToStrategy(address(strategy2), allocation2);
        vm.stopPrank();

        // If rebalancing is needed, execute it
        if (manager.needsRebalancing()) {
            vm.prank(address(vault));
            manager.rebalance();

            // After rebalancing, should be balanced
            uint256 targetValue = totalDeposit / 2;
            assertApproxEqAbs(strategy1.totalValue(), targetValue, totalDeposit / 100); // 1% tolerance
            assertApproxEqAbs(strategy2.totalValue(), targetValue, totalDeposit / 100);
        }
    }
}
