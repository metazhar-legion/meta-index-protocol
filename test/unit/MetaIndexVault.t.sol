// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MetaIndexVault} from "../../src/MetaIndexVault.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract MetaIndexVaultTest is Test {
    MetaIndexVault public vault;
    MockERC20 public usdc;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public guardian = makeAddr("guardian");

    uint256 constant INITIAL_BALANCE = 100_000e6; // $100k

    function setUp() public {
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy vault
        vault = new MetaIndexVault(
            usdc,
            "Meta Index Balanced Portfolio",
            "miBOCP"
        );

        // Setup roles
        vault.grantRole(vault.GUARDIAN_ROLE(), guardian);

        // Fund users
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
    }

    // ============ DEPOSIT TESTS ============

    function test_deposit_success() public {
        uint256 depositAmount = 1000e6; // $1000

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);

        uint256 shares = vault.deposit(depositAmount, alice);

        assertEq(vault.balanceOf(alice), shares);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(usdc.balanceOf(alice), INITIAL_BALANCE - depositAmount);
        vm.stopPrank();
    }

    function test_deposit_revertsWhenBelowMinimum() public {
        uint256 tooSmall = 5e6; // $5 (below $10 minimum)

        vm.startPrank(alice);
        usdc.approve(address(vault), tooSmall);

        vm.expectRevert(MetaIndexVault.BelowMinimumDeposit.selector);
        vault.deposit(tooSmall, alice);
        vm.stopPrank();
    }

    function test_deposit_revertsWhenExceedsCap() public {
        uint256 overCap = 15_000e6; // $15k (cap is $10k)

        vm.startPrank(alice);
        usdc.approve(address(vault), overCap);

        vm.expectRevert(MetaIndexVault.ExceedsTVLCap.selector);
        vault.deposit(overCap, alice);
        vm.stopPrank();
    }

    function test_deposit_revertsWhenPaused() public {
        vm.prank(guardian);
        vault.pause();

        uint256 depositAmount = 1000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);

        vm.expectRevert(); // Pausable: paused
        vault.deposit(depositAmount, alice);
        vm.stopPrank();
    }

    // ============ WITHDRAW TESTS ============

    function test_withdraw_success() public {
        // First deposit
        uint256 depositAmount = 1000e6;
        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);

        // Then withdraw
        uint256 withdrawAmount = 500e6;
        vault.withdraw(withdrawAmount, alice, alice);

        assertEq(usdc.balanceOf(alice), INITIAL_BALANCE - depositAmount + withdrawAmount);
        vm.stopPrank();
    }

    function test_withdraw_revertsZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(MetaIndexVault.ZeroAmount.selector);
        vault.withdraw(0, alice, alice);
    }

    // ============ SHARES/ASSETS CONVERSION ============

    function test_convertToShares_initialDeposit() public view {
        uint256 assets = 1000e6;
        uint256 shares = vault.convertToShares(assets);

        // First deposit: 1:1 ratio
        assertEq(shares, assets);
    }

    function test_convertToAssets_afterDeposit() public {
        uint256 depositAmount = 1000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        uint256 assets = vault.convertToAssets(shares);
        assertEq(assets, depositAmount);
    }

    // ============ ADMIN FUNCTIONS ============

    function test_updateTVLCap_success() public {
        uint256 newCap = 50_000e6;
        vault.updateTVLCap(newCap);

        assertEq(vault.tvlCap(), newCap);
    }

    function test_updateTVLCap_revertsNonAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.updateTVLCap(50_000e6);
    }

    function test_pause_success() public {
        vm.prank(guardian);
        vault.pause();

        assert(vault.paused());
    }

    function test_unpause_success() public {
        vm.prank(guardian);
        vault.pause();

        vault.unpause(); // Admin can unpause

        assert(!vault.paused());
    }

    function test_setStrategyManager_success() public {
        address manager = makeAddr("manager");
        vault.setStrategyManager(manager);

        assertEq(vault.strategyManager(), manager);
    }

    function test_setStrategyManager_revertsZeroAddress() public {
        vm.expectRevert(MetaIndexVault.ZeroAddress.selector);
        vault.setStrategyManager(address(0));
    }

    // ============ FUZZ TESTS ============

    function testFuzz_deposit(uint256 amount) public {
        amount = bound(amount, vault.minDeposit(), vault.tvlCap());

        vm.startPrank(alice);
        usdc.mint(alice, amount); // Ensure enough balance
        usdc.approve(address(vault), amount);

        uint256 shares = vault.deposit(amount, alice);

        assertGe(shares, 0);
        assertEq(vault.totalAssets(), amount);
        vm.stopPrank();
    }

    function testFuzz_depositAndWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, vault.minDeposit(), vault.tvlCap());
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        vm.startPrank(alice);
        usdc.mint(alice, depositAmount);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);

        vault.withdraw(withdrawAmount, alice, alice);

        assertEq(vault.totalAssets(), depositAmount - withdrawAmount);
        vm.stopPrank();
    }

    // ============ MULTI-USER TESTS ============

    function test_multipleUsers_deposits() public {
        uint256 aliceDeposit = 1000e6;
        uint256 bobDeposit = 2000e6;

        // Alice deposits
        vm.startPrank(alice);
        usdc.approve(address(vault), aliceDeposit);
        uint256 aliceShares = vault.deposit(aliceDeposit, alice);
        vm.stopPrank();

        // Bob deposits
        vm.startPrank(bob);
        usdc.approve(address(vault), bobDeposit);
        uint256 bobShares = vault.deposit(bobDeposit, bob);
        vm.stopPrank();

        assertEq(vault.totalAssets(), aliceDeposit + bobDeposit);
        assertEq(vault.balanceOf(alice), aliceShares);
        assertEq(vault.balanceOf(bob), bobShares);
    }

    function test_multipleUsers_withdrawals() public {
        uint256 aliceDeposit = 1000e6;
        uint256 bobDeposit = 2000e6;

        // Deposits
        vm.prank(alice);
        usdc.approve(address(vault), aliceDeposit);
        vm.prank(alice);
        vault.deposit(aliceDeposit, alice);

        vm.prank(bob);
        usdc.approve(address(vault), bobDeposit);
        vm.prank(bob);
        vault.deposit(bobDeposit, bob);

        // Withdrawals
        vm.prank(alice);
        vault.withdraw(500e6, alice, alice);

        vm.prank(bob);
        vault.withdraw(1000e6, bob, bob);

        assertEq(vault.totalAssets(), aliceDeposit + bobDeposit - 500e6 - 1000e6);
    }

    // ============ EVENTS TESTS ============

    function test_deposit_emitsEvent() public {
        uint256 depositAmount = 1000e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);

        vm.expectEmit(true, true, true, true);
        emit MetaIndexVault.Deposited(alice, depositAmount, depositAmount);

        vault.deposit(depositAmount, alice);
        vm.stopPrank();
    }

    function test_withdraw_emitsEvent() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;

        vm.startPrank(alice);
        usdc.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);

        uint256 shares = vault.previewWithdraw(withdrawAmount);

        vm.expectEmit(true, true, true, true);
        emit MetaIndexVault.Withdrawn(alice, withdrawAmount, shares);

        vault.withdraw(withdrawAmount, alice, alice);
        vm.stopPrank();
    }

    function test_updateTVLCap_emitsEvent() public {
        uint256 oldCap = vault.tvlCap();
        uint256 newCap = 50_000e6;

        vm.expectEmit(true, true, true, true);
        emit MetaIndexVault.TVLCapUpdated(oldCap, newCap);

        vault.updateTVLCap(newCap);
    }
}
