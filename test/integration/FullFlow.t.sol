// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MetaIndexVault} from "../../src/MetaIndexVault.sol";
import {StrategyManager} from "../../src/StrategyManager.sol";
import {MockStrategy} from "../../src/strategies/MockStrategy.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

/**
 * @title FullFlowTest
 * @notice Integration tests for the complete flow: User → Vault → StrategyManager → Strategy
 */
contract FullFlowTest is Test {
    MetaIndexVault public vault;
    StrategyManager public manager;
    MockStrategy public strategy;
    MockERC20 public usdc;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public admin;

    uint256 constant INITIAL_USER_BALANCE = 100_000e6;

    function setUp() public {
        admin = address(this);

        // Deploy USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy Vault
        vault = new MetaIndexVault(
            usdc,
            "Meta Index Balanced Portfolio",
            "miBOCP"
        );

        // Deploy StrategyManager
        manager = new StrategyManager(address(vault), address(usdc), address(0));

        // Deploy Strategy
        strategy = new MockStrategy(
            address(vault),
            address(manager),
            address(usdc)
        );

        // Connect vault to manager
        vault.setStrategyManager(address(manager));

        // Grant manager role to vault in the strategy manager
        manager.grantRole(manager.MANAGER_ROLE(), address(vault));

        // Add strategy to manager (100% allocation)
        manager.addStrategy(address(strategy), 10000);

        // Fund users
        usdc.mint(alice, INITIAL_USER_BALANCE);
        usdc.mint(bob, INITIAL_USER_BALANCE);
    }

    // ============ BASIC FLOW TESTS ============

    function test_fullFlow_depositOnly() public {
        uint256 depositAmount = 1000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), shares);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(usdc.balanceOf(address(vault)), depositAmount);
    }

    function test_fullFlow_depositAndWithdraw() public {
        uint256 depositAmount = 1000e6;

        // Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Alice withdraws
        vm.prank(alice);
        vault.withdraw(500e6, alice, alice);

        assertEq(vault.totalAssets(), 500e6);
        assertEq(usdc.balanceOf(alice), INITIAL_USER_BALANCE - 500e6);
    }

    // ============ VAULT + STRATEGY INTEGRATION ============

    function test_fullFlow_depositAllocateWithdraw() public {
        uint256 depositAmount = 5000e6;
        uint256 allocAmount = 3000e6;

        // 1. Alice deposits to vault
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.totalAssets(), depositAmount);

        // 2. Vault allocates to strategy (through manager)
        vm.startPrank(address(vault));
        usdc.approve(address(manager), allocAmount);
        manager.allocateToStrategy(address(strategy), allocAmount);
        vm.stopPrank();

        assertEq(strategy.totalValue(), allocAmount);
        assertEq(vault.totalAssets(), depositAmount - allocAmount);

        // 3. Alice withdraws (vault should pull from strategy if needed)
        // For now, vault has enough idle funds
        vm.prank(alice);
        vault.withdraw(1000e6, alice, alice);

        assertEq(usdc.balanceOf(alice), INITIAL_USER_BALANCE - 4000e6);
    }

    function test_fullFlow_multipleUsersWithAllocation() public {
        uint256 aliceDeposit = 5000e6;
        uint256 bobDeposit = 3000e6;

        // Both users deposit
        vm.startPrank(alice);
        usdc.approve(address(vault), aliceDeposit);
        uint256 aliceShares = vault.deposit(aliceDeposit, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(vault), bobDeposit);
        uint256 bobShares = vault.deposit(bobDeposit, bob);
        vm.stopPrank();

        assertEq(vault.totalAssets(), aliceDeposit + bobDeposit);

        // Allocate 50% to strategy
        uint256 allocAmount = 4000e6;
        vm.startPrank(address(vault));
        usdc.approve(address(manager), allocAmount);
        manager.allocateToStrategy(address(strategy), allocAmount);
        vm.stopPrank();

        assertEq(strategy.totalValue(), allocAmount);
        assertEq(manager.totalValue(), allocAmount);

        // Verify share balances
        assertEq(vault.balanceOf(alice), aliceShares);
        assertEq(vault.balanceOf(bob), bobShares);
    }

    function test_fullFlow_deallocateAndWithdraw() public {
        uint256 depositAmount = 5000e6;
        uint256 allocAmount = 4000e6;

        // Deposit and allocate
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), allocAmount);
        manager.allocateToStrategy(address(strategy), allocAmount);
        vm.stopPrank();

        // Deallocate from strategy back to vault
        vm.prank(address(vault));
        manager.deallocateFromStrategy(address(strategy), 2000e6, address(vault));

        assertEq(strategy.totalValue(), 2000e6);
        assertEq(vault.totalAssets(), 3000e6); // 1000 idle + 2000 returned

        // Now Alice can withdraw more
        vm.prank(alice);
        vault.withdraw(2500e6, alice, alice);

        assertEq(usdc.balanceOf(alice), INITIAL_USER_BALANCE - 2500e6);
    }

    // ============ EDGE CASES ============

    function test_fullFlow_smallDeposits() public {
        // Test with minimum deposit amounts
        uint256 minDeposit = vault.minDeposit();

        vm.startPrank(alice);
        usdc.approve(address(vault), minDeposit);
        vault.deposit(minDeposit, alice);
        vm.stopPrank();

        assertEq(vault.totalAssets(), minDeposit);
    }

    function test_fullFlow_maxTVLCap() public {
        uint256 tvlCap = vault.tvlCap();

        // Deposit up to cap
        vm.startPrank(alice);
        usdc.approve(address(vault), tvlCap);
        vault.deposit(tvlCap, alice);
        vm.stopPrank();

        // Try to exceed cap
        vm.startPrank(bob);
        usdc.approve(address(vault), 100e6);
        vm.expectRevert(MetaIndexVault.ExceedsTVLCap.selector);
        vault.deposit(100e6, bob);
        vm.stopPrank();
    }

    function test_fullFlow_multipleStrategies() public {
        // Deploy second strategy
        MockStrategy strategy2 = new MockStrategy(
            address(vault),
            address(manager),
            address(usdc)
        );

        // Update allocations
        manager.updateAllocation(address(strategy), 6000); // 60%
        manager.addStrategy(address(strategy2), 4000); // 40%

        uint256 depositAmount = 10_000e6;

        // Update TVL cap
        vault.updateTVLCap(depositAmount);

        // Deposit
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate to both strategies
        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy), 6000e6);
        manager.allocateToStrategy(address(strategy2), 4000e6);
        vm.stopPrank();

        assertEq(strategy.totalValue(), 6000e6);
        assertEq(strategy2.totalValue(), 4000e6);
        assertEq(manager.totalValue(), 10_000e6);
    }

    // ============ MANAGER FUNCTIONALITY ============

    function test_fullFlow_updateStrategyAllocation() public {
        // Start with one strategy
        assertEq(manager.getAllocation(address(strategy)), 10000);

        // Deploy second strategy
        MockStrategy strategy2 = new MockStrategy(
            address(vault),
            address(manager),
            address(usdc)
        );

        // Update allocations
        manager.updateAllocation(address(strategy), 7000); // 70%
        manager.addStrategy(address(strategy2), 3000); // 30%

        assertEq(manager.getAllocation(address(strategy)), 7000);
        assertEq(manager.getAllocation(address(strategy2)), 3000);
        assertEq(manager.getStrategyCount(), 2);
    }

    function test_fullFlow_removeStrategyAfterDeallocation() public {
        uint256 depositAmount = 5000e6;

        // Deposit and allocate
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.startPrank(address(vault));
        usdc.approve(address(manager), depositAmount);
        manager.allocateToStrategy(address(strategy), depositAmount);
        vm.stopPrank();

        // Deallocate everything
        vm.prank(address(vault));
        manager.deallocateFromStrategy(address(strategy), depositAmount, address(vault));

        assertEq(strategy.totalValue(), 0);

        // Now can remove strategy
        manager.removeStrategy(address(strategy));

        assertFalse(manager.isStrategyActive(address(strategy)));
        assertEq(manager.getStrategyCount(), 0);
    }

    // ============ FUZZ TESTS ============

    function testFuzz_fullFlow_depositAllocateWithdraw(
        uint256 depositAmount,
        uint256 allocPercent,
        uint256 withdrawPercent
    ) public {
        // Bound inputs
        depositAmount = bound(depositAmount, vault.minDeposit(), vault.tvlCap());
        allocPercent = bound(allocPercent, 0, 100);
        withdrawPercent = bound(withdrawPercent, 1, 100);

        uint256 allocAmount = (depositAmount * allocPercent) / 100;
        uint256 withdrawAmount = (depositAmount * withdrawPercent) / 100;

        if (withdrawAmount == 0) withdrawAmount = 1;

        // Deposit
        vm.startPrank(alice);
        usdc.mint(alice, depositAmount);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Allocate if non-zero
        if (allocAmount > 0) {
            vm.startPrank(address(vault));
            usdc.approve(address(manager), allocAmount);
            manager.allocateToStrategy(address(strategy), allocAmount);
            vm.stopPrank();
        }

        // Withdraw (only if vault has enough idle funds)
        uint256 vaultIdle = vault.totalAssets();
        if (withdrawAmount <= vaultIdle) {
            vm.prank(alice);
            vault.withdraw(withdrawAmount, alice, alice);

            assertEq(vault.totalAssets(), depositAmount - allocAmount - withdrawAmount);
        }
    }
}
