// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockStrategy} from "../../src/strategies/MockStrategy.sol";
import {BaseStrategy} from "../../src/strategies/BaseStrategy.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract MockStrategyTest is Test {
    MockStrategy public strategy;
    MockERC20 public usdc;

    address public vault = makeAddr("vault");
    address public manager = makeAddr("manager");
    address public user = makeAddr("user");

    uint256 constant INITIAL_BALANCE = 100_000e6;

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        strategy = new MockStrategy(vault, manager, address(usdc));

        // Fund manager for deposits
        usdc.mint(manager, INITIAL_BALANCE);
    }

    // ============ CONSTRUCTOR TESTS ============

    function test_constructor_success() public {
        assertEq(strategy.vault(), vault);
        assertEq(strategy.strategyManager(), manager);
        assertEq(strategy.asset(), address(usdc));
        assertTrue(strategy.isActive());
    }

    function test_constructor_revertsZeroVault() public {
        vm.expectRevert(BaseStrategy.ZeroAddress.selector);
        new MockStrategy(address(0), manager, address(usdc));
    }

    function test_constructor_revertsZeroManager() public {
        vm.expectRevert(BaseStrategy.ZeroAddress.selector);
        new MockStrategy(vault, address(0), address(usdc));
    }

    function test_constructor_revertsZeroAsset() public {
        vm.expectRevert(BaseStrategy.ZeroAddress.selector);
        new MockStrategy(vault, manager, address(0));
    }

    // ============ DEPOSIT TESTS ============

    function test_deposit_success() public {
        uint256 amount = 1000e6;

        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);
        strategy.deposit(amount);
        vm.stopPrank();

        assertEq(strategy.totalValue(), amount);
        assertEq(usdc.balanceOf(address(strategy)), amount);
    }

    function test_deposit_revertsNonManager() public {
        uint256 amount = 1000e6;

        vm.prank(user);
        vm.expectRevert(BaseStrategy.OnlyManager.selector);
        strategy.deposit(amount);
    }

    function test_deposit_revertsZeroAmount() public {
        vm.prank(manager);
        vm.expectRevert(BaseStrategy.ZeroAmount.selector);
        strategy.deposit(0);
    }

    function test_deposit_revertsWhenPaused() public {
        vm.prank(manager);
        strategy.pause();

        uint256 amount = 1000e6;

        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);
        vm.expectRevert(BaseStrategy.StrategyNotActive.selector);
        strategy.deposit(amount);
        vm.stopPrank();
    }

    // ============ WITHDRAW TESTS ============

    function test_withdraw_success() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;

        // First deposit
        vm.startPrank(manager);
        usdc.approve(address(strategy), depositAmount);
        strategy.deposit(depositAmount);

        // Then withdraw
        strategy.withdraw(withdrawAmount, user);
        vm.stopPrank();

        assertEq(usdc.balanceOf(user), withdrawAmount);
        assertEq(strategy.totalValue(), depositAmount - withdrawAmount);
    }

    function test_withdraw_revertsNonManager() public {
        vm.prank(user);
        vm.expectRevert(BaseStrategy.OnlyManager.selector);
        strategy.withdraw(100e6, user);
    }

    function test_withdraw_revertsZeroAmount() public {
        vm.prank(manager);
        vm.expectRevert(BaseStrategy.ZeroAmount.selector);
        strategy.withdraw(0, user);
    }

    function test_withdraw_revertsZeroAddress() public {
        vm.prank(manager);
        vm.expectRevert(BaseStrategy.ZeroAddress.selector);
        strategy.withdraw(100e6, address(0));
    }

    function test_withdraw_worksWhenPaused() public {
        uint256 amount = 1000e6;

        // Deposit while active
        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);
        strategy.deposit(amount);

        // Pause and withdraw
        strategy.pause();
        strategy.withdraw(amount, user);
        vm.stopPrank();

        assertEq(usdc.balanceOf(user), amount);
        assertEq(strategy.totalValue(), 0);
    }

    // ============ PAUSE/UNPAUSE TESTS ============

    function test_pause_success() public {
        vm.prank(manager);
        strategy.pause();

        assertFalse(strategy.isActive());
    }

    function test_pause_revertsNonManager() public {
        vm.prank(user);
        vm.expectRevert(BaseStrategy.OnlyManager.selector);
        strategy.pause();
    }

    function test_unpause_success() public {
        vm.startPrank(manager);
        strategy.pause();
        strategy.unpause();
        vm.stopPrank();

        assertTrue(strategy.isActive());
    }

    function test_unpause_revertsNonManager() public {
        vm.prank(manager);
        strategy.pause();

        vm.prank(user);
        vm.expectRevert(BaseStrategy.OnlyManager.selector);
        strategy.unpause();
    }

    // ============ VIEW FUNCTIONS ============

    function test_name() public {
        assertEq(strategy.name(), "Mock Strategy");
    }

    function test_totalValue_empty() public {
        assertEq(strategy.totalValue(), 0);
    }

    function test_totalValue_afterDeposit() public {
        uint256 amount = 1000e6;

        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);
        strategy.deposit(amount);
        vm.stopPrank();

        assertEq(strategy.totalValue(), amount);
    }

    // ============ EVENTS TESTS ============

    function test_deposit_emitsEvent() public {
        uint256 amount = 1000e6;

        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);

        vm.expectEmit(true, true, true, true);
        emit BaseStrategy.Deposited(amount);

        strategy.deposit(amount);
        vm.stopPrank();
    }

    function test_withdraw_emitsEvent() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;

        vm.startPrank(manager);
        usdc.approve(address(strategy), depositAmount);
        strategy.deposit(depositAmount);

        vm.expectEmit(true, true, true, true);
        emit BaseStrategy.Withdrawn(withdrawAmount, user);

        strategy.withdraw(withdrawAmount, user);
        vm.stopPrank();
    }

    function test_pause_emitsEvent() public {
        vm.prank(manager);

        vm.expectEmit(true, true, true, true);
        emit BaseStrategy.StrategyPaused();

        strategy.pause();
    }

    function test_unpause_emitsEvent() public {
        vm.prank(manager);
        strategy.pause();

        vm.prank(manager);

        vm.expectEmit(true, true, true, true);
        emit BaseStrategy.StrategyUnpaused();

        strategy.unpause();
    }

    // ============ FUZZ TESTS ============

    function testFuzz_deposit(uint256 amount) public {
        amount = bound(amount, 1, INITIAL_BALANCE);

        vm.startPrank(manager);
        usdc.approve(address(strategy), amount);
        strategy.deposit(amount);
        vm.stopPrank();

        assertEq(strategy.totalValue(), amount);
    }

    function testFuzz_depositAndWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1, INITIAL_BALANCE);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        vm.startPrank(manager);
        usdc.approve(address(strategy), depositAmount);
        strategy.deposit(depositAmount);
        strategy.withdraw(withdrawAmount, user);
        vm.stopPrank();

        assertEq(strategy.totalValue(), depositAmount - withdrawAmount);
        assertEq(usdc.balanceOf(user), withdrawAmount);
    }
}
