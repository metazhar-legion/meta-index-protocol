// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StrategyManager} from "../../src/StrategyManager.sol";
import {IStrategyManager} from "../../src/interfaces/IStrategyManager.sol";
import {MockStrategy} from "../../src/strategies/MockStrategy.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract StrategyManagerTest is Test {
    StrategyManager public manager;
    MockStrategy public strategy1;
    MockStrategy public strategy2;
    MockERC20 public usdc;

    address public vault = makeAddr("vault");
    address public admin;
    address public user = makeAddr("user");

    uint256 constant INITIAL_BALANCE = 100_000e6;

    function setUp() public {
        admin = address(this);

        usdc = new MockERC20("USDC", "USDC", 6);
        manager = new StrategyManager(vault, address(usdc), address(0));

        strategy1 = new MockStrategy(vault, address(manager), address(usdc));
        strategy2 = new MockStrategy(vault, address(manager), address(usdc));

        // Fund vault
        usdc.mint(vault, INITIAL_BALANCE);
    }

    // ============ CONSTRUCTOR TESTS ============

    function test_constructor_success() public view {
        assertEq(manager.vault(), vault);
        assertEq(manager.asset(), address(usdc));
        assertTrue(manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(manager.hasRole(manager.MANAGER_ROLE(), vault));
    }

    function test_constructor_revertsZeroVault() public {
        vm.expectRevert(IStrategyManager.InvalidStrategy.selector);
        new StrategyManager(address(0), address(usdc));
    }

    function test_constructor_revertsZeroAsset() public {
        vm.expectRevert(IStrategyManager.InvalidStrategy.selector);
        new StrategyManager(vault, address(0));
    }

    // ============ ADD STRATEGY TESTS ============

    function test_addStrategy_success() public {
        manager.addStrategy(address(strategy1), 10000); // 100%

        assertTrue(manager.isStrategyActive(address(strategy1)));
        assertEq(manager.getAllocation(address(strategy1)), 10000);
        assertEq(manager.getStrategyCount(), 1);
    }

    function test_addStrategy_multipleStrategies() public {
        manager.addStrategy(address(strategy1), 6000); // 60%
        manager.addStrategy(address(strategy2), 4000); // 40%

        assertEq(manager.getStrategyCount(), 2);
        assertEq(manager.getAllocation(address(strategy1)), 6000);
        assertEq(manager.getAllocation(address(strategy2)), 4000);
    }

    function test_addStrategy_revertsZeroAddress() public {
        vm.expectRevert(IStrategyManager.InvalidStrategy.selector);
        manager.addStrategy(address(0), 10000);
    }

    function test_addStrategy_revertsAlreadyExists() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.expectRevert(IStrategyManager.StrategyAlreadyExists.selector);
        manager.addStrategy(address(strategy1), 5000);
    }

    function test_addStrategy_revertsExceedsAllocation() public {
        manager.addStrategy(address(strategy1), 6000);

        vm.expectRevert(IStrategyManager.AllocationExceeds100Percent.selector);
        manager.addStrategy(address(strategy2), 5000); // Would be 110%
    }

    function test_addStrategy_revertsInvalidAllocation() public {
        vm.expectRevert(IStrategyManager.InvalidAllocation.selector);
        manager.addStrategy(address(strategy1), 10001); // > 100%
    }

    function test_addStrategy_revertsNonAdmin() public {
        vm.prank(user);
        vm.expectRevert();
        manager.addStrategy(address(strategy1), 10000);
    }

    function test_addStrategy_emitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategyAdded(address(strategy1), 10000);

        manager.addStrategy(address(strategy1), 10000);
    }

    // ============ REMOVE STRATEGY TESTS ============

    function test_removeStrategy_success() public {
        manager.addStrategy(address(strategy1), 10000);
        manager.removeStrategy(address(strategy1));

        assertFalse(manager.isStrategyActive(address(strategy1)));
        assertEq(manager.getStrategyCount(), 0);
    }

    function test_removeStrategy_revertsNotFound() public {
        vm.expectRevert(IStrategyManager.StrategyNotFound.selector);
        manager.removeStrategy(address(strategy1));
    }

    function test_removeStrategy_revertsHasFunds() public {
        manager.addStrategy(address(strategy1), 10000);

        // Allocate funds
        vm.startPrank(vault);
        usdc.approve(address(manager), 1000e6);
        manager.allocateToStrategy(address(strategy1), 1000e6);
        vm.stopPrank();

        vm.expectRevert("Strategy has funds");
        manager.removeStrategy(address(strategy1));
    }

    function test_removeStrategy_emitsEvent() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategyRemoved(address(strategy1));

        manager.removeStrategy(address(strategy1));
    }

    // ============ UPDATE ALLOCATION TESTS ============

    function test_updateAllocation_success() public {
        manager.addStrategy(address(strategy1), 6000);
        manager.updateAllocation(address(strategy1), 8000);

        assertEq(manager.getAllocation(address(strategy1)), 8000);
    }

    function test_updateAllocation_revertsNotFound() public {
        vm.expectRevert(IStrategyManager.StrategyNotFound.selector);
        manager.updateAllocation(address(strategy1), 5000);
    }

    function test_updateAllocation_revertsExceeds100() public {
        manager.addStrategy(address(strategy1), 6000);
        manager.addStrategy(address(strategy2), 3000);

        vm.expectRevert(IStrategyManager.AllocationExceeds100Percent.selector);
        manager.updateAllocation(address(strategy1), 9000); // Would be 120% total
    }

    function test_updateAllocation_emitsEvent() public {
        manager.addStrategy(address(strategy1), 6000);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.AllocationUpdated(address(strategy1), 6000, 8000);

        manager.updateAllocation(address(strategy1), 8000);
    }

    // ============ ALLOCATE TO STRATEGY TESTS ============

    function test_allocateToStrategy_success() public {
        manager.addStrategy(address(strategy1), 10000);

        uint256 allocAmount = 1000e6;

        vm.startPrank(vault);
        usdc.approve(address(manager), allocAmount);
        manager.allocateToStrategy(address(strategy1), allocAmount);
        vm.stopPrank();

        assertEq(strategy1.totalValue(), allocAmount);
    }

    function test_allocateToStrategy_revertsNotFound() public {
        vm.prank(vault);
        vm.expectRevert(IStrategyManager.StrategyNotFound.selector);
        manager.allocateToStrategy(address(strategy1), 1000e6);
    }

    function test_allocateToStrategy_revertsZeroAmount() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.prank(vault);
        vm.expectRevert(IStrategyManager.InvalidAllocation.selector);
        manager.allocateToStrategy(address(strategy1), 0);
    }

    function test_allocateToStrategy_revertsNonManager() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.prank(user);
        vm.expectRevert();
        manager.allocateToStrategy(address(strategy1), 1000e6);
    }

    function test_allocateToStrategy_revertsInactive() public {
        manager.addStrategy(address(strategy1), 10000);

        // Pause strategy
        vm.prank(address(manager));
        strategy1.pause();

        vm.startPrank(vault);
        usdc.approve(address(manager), 1000e6);
        vm.expectRevert(IStrategyManager.InvalidStrategy.selector);
        manager.allocateToStrategy(address(strategy1), 1000e6);
        vm.stopPrank();
    }

    // ============ DEALLOCATE FROM STRATEGY TESTS ============

    function test_deallocateFromStrategy_success() public {
        manager.addStrategy(address(strategy1), 10000);

        uint256 allocAmount = 1000e6;

        // First allocate
        vm.startPrank(vault);
        usdc.approve(address(manager), allocAmount);
        manager.allocateToStrategy(address(strategy1), allocAmount);

        // Then deallocate
        manager.deallocateFromStrategy(address(strategy1), 500e6, vault);
        vm.stopPrank();

        assertEq(strategy1.totalValue(), 500e6);
        assertEq(usdc.balanceOf(vault), INITIAL_BALANCE - 500e6);
    }

    function test_deallocateFromStrategy_revertsNotFound() public {
        vm.prank(vault);
        vm.expectRevert(IStrategyManager.StrategyNotFound.selector);
        manager.deallocateFromStrategy(address(strategy1), 100e6, vault);
    }

    function test_deallocateFromStrategy_revertsZeroAmount() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.prank(vault);
        vm.expectRevert(IStrategyManager.InvalidAllocation.selector);
        manager.deallocateFromStrategy(address(strategy1), 0, vault);
    }

    function test_deallocateFromStrategy_revertsZeroRecipient() public {
        manager.addStrategy(address(strategy1), 10000);

        vm.prank(vault);
        vm.expectRevert(IStrategyManager.InvalidStrategy.selector);
        manager.deallocateFromStrategy(address(strategy1), 100e6, address(0));
    }

    // ============ VIEW FUNCTIONS ============

    function test_getStrategies() public {
        manager.addStrategy(address(strategy1), 6000);
        manager.addStrategy(address(strategy2), 4000);

        address[] memory strats = manager.getStrategies();

        assertEq(strats.length, 2);
        assertEq(strats[0], address(strategy1));
        assertEq(strats[1], address(strategy2));
    }

    function test_totalValue() public {
        manager.addStrategy(address(strategy1), 6000);
        manager.addStrategy(address(strategy2), 4000);

        // Allocate to both
        vm.startPrank(vault);
        usdc.approve(address(manager), 2000e6);
        manager.allocateToStrategy(address(strategy1), 1000e6);
        manager.allocateToStrategy(address(strategy2), 500e6);
        vm.stopPrank();

        assertEq(manager.totalValue(), 1500e6);
    }

    function test_totalValue_empty() public view {
        assertEq(manager.totalValue(), 0);
    }

    // ============ EVENTS TESTS ============

    function test_allocate_emitsEvent() public {
        manager.addStrategy(address(strategy1), 10000);

        uint256 amount = 1000e6;

        vm.startPrank(vault);
        usdc.approve(address(manager), amount);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategyAllocated(address(strategy1), amount);

        manager.allocateToStrategy(address(strategy1), amount);
        vm.stopPrank();
    }

    function test_deallocate_emitsEvent() public {
        manager.addStrategy(address(strategy1), 10000);

        // Allocate first
        vm.startPrank(vault);
        usdc.approve(address(manager), 1000e6);
        manager.allocateToStrategy(address(strategy1), 1000e6);

        uint256 deallocAmount = 500e6;

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategyDeallocated(address(strategy1), deallocAmount);

        manager.deallocateFromStrategy(address(strategy1), deallocAmount, vault);
        vm.stopPrank();
    }
}
