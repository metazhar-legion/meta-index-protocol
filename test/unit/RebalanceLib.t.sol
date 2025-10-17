// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {RebalanceLib} from "../../src/libraries/RebalanceLib.sol";

contract RebalanceLibTest is Test {
    using RebalanceLib for *;

    address constant STRATEGY1 = address(0x1);
    address constant STRATEGY2 = address(0x2);
    address constant STRATEGY3 = address(0x3);

    // ============ calculateAllocationStates TESTS ============

    function test_calculateAllocationStates_balanced() public pure {
        address[] memory strategies = new address[](2);
        strategies[0] = STRATEGY1;
        strategies[1] = STRATEGY2;

        uint256[] memory targetAllocations = new uint256[](2);
        targetAllocations[0] = 6000; // 60%
        targetAllocations[1] = 4000; // 40%

        uint256[] memory strategyValues = new uint256[](2);
        strategyValues[0] = 6000e6; // $6000
        strategyValues[1] = 4000e6; // $4000

        uint256 totalValue = 10_000e6; // $10000

        RebalanceLib.AllocationState[] memory states = RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalValue
        );

        assertEq(states.length, 2);
        assertEq(states[0].strategy, STRATEGY1);
        assertEq(states[0].targetAllocation, 6000);
        assertEq(states[0].currentValue, 6000e6);
        assertEq(states[0].currentAllocation, 6000);
        assertEq(states[0].deviation, 0);

        assertEq(states[1].strategy, STRATEGY2);
        assertEq(states[1].targetAllocation, 4000);
        assertEq(states[1].currentValue, 4000e6);
        assertEq(states[1].currentAllocation, 4000);
        assertEq(states[1].deviation, 0);
    }

    function test_calculateAllocationStates_imbalanced() public pure {
        address[] memory strategies = new address[](2);
        strategies[0] = STRATEGY1;
        strategies[1] = STRATEGY2;

        uint256[] memory targetAllocations = new uint256[](2);
        targetAllocations[0] = 5000; // 50% target
        targetAllocations[1] = 5000; // 50% target

        uint256[] memory strategyValues = new uint256[](2);
        strategyValues[0] = 7000e6; // $7000 (70% actual)
        strategyValues[1] = 3000e6; // $3000 (30% actual)

        uint256 totalValue = 10_000e6;

        RebalanceLib.AllocationState[] memory states = RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalValue
        );

        assertEq(states[0].currentAllocation, 7000); // 70%
        assertEq(states[0].deviation, 2000); // +20%

        assertEq(states[1].currentAllocation, 3000); // 30%
        assertEq(states[1].deviation, -2000); // -20%
    }

    function test_calculateAllocationStates_revertsInvalidLength() public {
        address[] memory strategies = new address[](2);
        uint256[] memory targetAllocations = new uint256[](1); // Mismatched length
        uint256[] memory strategyValues = new uint256[](2);

        vm.expectRevert(RebalanceLib.InvalidAllocation.selector);
        RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            1000e6
        );
    }

    function test_calculateAllocationStates_revertsZeroTotal() public {
        address[] memory strategies = new address[](2);
        uint256[] memory targetAllocations = new uint256[](2);
        uint256[] memory strategyValues = new uint256[](2);

        vm.expectRevert(RebalanceLib.InsufficientTotalValue.selector);
        RebalanceLib.calculateAllocationStates(strategies, targetAllocations, strategyValues, 0);
    }

    // ============ needsRebalancing TESTS ============

    function test_needsRebalancing_false_whenBalanced() public pure {
        RebalanceLib.AllocationState[] memory states = new RebalanceLib.AllocationState[](2);

        states[0] = RebalanceLib.AllocationState({
            strategy: STRATEGY1,
            targetAllocation: 5000,
            currentValue: 5000e6,
            currentAllocation: 5000,
            deviation: 0
        });

        states[1] = RebalanceLib.AllocationState({
            strategy: STRATEGY2,
            targetAllocation: 5000,
            currentValue: 5000e6,
            currentAllocation: 5000,
            deviation: 0
        });

        bool needs = RebalanceLib.needsRebalancing(states, 500); // 5% threshold
        assertFalse(needs);
    }

    function test_needsRebalancing_true_whenExceedsThreshold() public pure {
        RebalanceLib.AllocationState[] memory states = new RebalanceLib.AllocationState[](2);

        states[0] = RebalanceLib.AllocationState({
            strategy: STRATEGY1,
            targetAllocation: 5000,
            currentValue: 6000e6,
            currentAllocation: 6000,
            deviation: 1000 // 10% deviation
        });

        states[1] = RebalanceLib.AllocationState({
            strategy: STRATEGY2,
            targetAllocation: 5000,
            currentValue: 4000e6,
            currentAllocation: 4000,
            deviation: -1000
        });

        bool needs = RebalanceLib.needsRebalancing(states, 500); // 5% threshold
        assertTrue(needs);
    }

    function test_needsRebalancing_false_withinThreshold() public pure {
        RebalanceLib.AllocationState[] memory states = new RebalanceLib.AllocationState[](2);

        // 3% deviation, threshold is 5%
        states[0] = RebalanceLib.AllocationState({
            strategy: STRATEGY1,
            targetAllocation: 5000,
            currentValue: 5300e6,
            currentAllocation: 5300,
            deviation: 300
        });

        states[1] = RebalanceLib.AllocationState({
            strategy: STRATEGY2,
            targetAllocation: 5000,
            currentValue: 4700e6,
            currentAllocation: 4700,
            deviation: -300
        });

        bool needs = RebalanceLib.needsRebalancing(states, 500);
        assertFalse(needs);
    }

    // ============ calculateRebalanceActions TESTS ============

    function test_calculateRebalanceActions_twoStrategies() public pure {
        RebalanceLib.AllocationState[] memory states = new RebalanceLib.AllocationState[](2);

        states[0] = RebalanceLib.AllocationState({
            strategy: STRATEGY1,
            targetAllocation: 5000, // 50% target
            currentValue: 7000e6, // 70% actual
            currentAllocation: 7000,
            deviation: 2000
        });

        states[1] = RebalanceLib.AllocationState({
            strategy: STRATEGY2,
            targetAllocation: 5000, // 50% target
            currentValue: 3000e6, // 30% actual
            currentAllocation: 3000,
            deviation: -2000
        });

        uint256 totalValue = 10_000e6;

        RebalanceLib.RebalanceAction[] memory actions = RebalanceLib.calculateRebalanceActions(
            states,
            totalValue
        );

        assertEq(actions.length, 2);

        // Should withdraw from STRATEGY1
        assertEq(actions[0].strategy, STRATEGY1);
        assertEq(actions[0].action, 0); // withdraw
        assertEq(actions[0].amount, 2000e6); // Withdraw $2000

        // Should deposit to STRATEGY2
        assertEq(actions[1].strategy, STRATEGY2);
        assertEq(actions[1].action, 1); // deposit
        assertEq(actions[1].amount, 2000e6); // Deposit $2000
    }

    function test_calculateRebalanceActions_threeStrategies() public pure {
        RebalanceLib.AllocationState[] memory states = new RebalanceLib.AllocationState[](3);

        states[0] = RebalanceLib.AllocationState({
            strategy: STRATEGY1,
            targetAllocation: 5000, // 50% target
            currentValue: 7000e6, // Overweight
            currentAllocation: 7000,
            deviation: 2000
        });

        states[1] = RebalanceLib.AllocationState({
            strategy: STRATEGY2,
            targetAllocation: 3000, // 30% target
            currentValue: 2000e6, // Underweight
            currentAllocation: 2000,
            deviation: -1000
        });

        states[2] = RebalanceLib.AllocationState({
            strategy: STRATEGY3,
            targetAllocation: 2000, // 20% target
            currentValue: 1000e6, // Underweight
            currentAllocation: 1000,
            deviation: -1000
        });

        uint256 totalValue = 10_000e6;

        RebalanceLib.RebalanceAction[] memory actions = RebalanceLib.calculateRebalanceActions(
            states,
            totalValue
        );

        assertEq(actions.length, 3);
    }

    // ============ validateAllocations TESTS ============

    function test_validateAllocations_valid() public pure {
        uint256[] memory allocations = new uint256[](3);
        allocations[0] = 5000; // 50%
        allocations[1] = 3000; // 30%
        allocations[2] = 2000; // 20%

        bool valid = RebalanceLib.validateAllocations(allocations);
        assertTrue(valid);
    }

    function test_validateAllocations_invalid() public pure {
        uint256[] memory allocations = new uint256[](2);
        allocations[0] = 6000; // 60%
        allocations[1] = 5000; // 50% (total = 110%)

        bool valid = RebalanceLib.validateAllocations(allocations);
        assertFalse(valid);
    }

    // ============ calculateTotals TESTS ============

    function test_calculateTotals() public pure {
        RebalanceLib.RebalanceAction[] memory actions = new RebalanceLib.RebalanceAction[](3);

        actions[0] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY1,
            action: 0, // withdraw
            amount: 1000e6
        });

        actions[1] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY2,
            action: 1, // deposit
            amount: 500e6
        });

        actions[2] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY3,
            action: 1, // deposit
            amount: 500e6
        });

        (uint256 totalDeposits, uint256 totalWithdrawals) = RebalanceLib.calculateTotals(actions);

        assertEq(totalDeposits, 1000e6);
        assertEq(totalWithdrawals, 1000e6);
    }

    // ============ separateActions TESTS ============

    function test_separateActions() public pure {
        RebalanceLib.RebalanceAction[] memory actions = new RebalanceLib.RebalanceAction[](4);

        actions[0] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY1,
            action: 0, // withdraw
            amount: 1000e6
        });

        actions[1] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY2,
            action: 1, // deposit
            amount: 500e6
        });

        actions[2] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY3,
            action: 1, // deposit
            amount: 300e6
        });

        actions[3] = RebalanceLib.RebalanceAction({
            strategy: STRATEGY1,
            action: 0, // withdraw
            amount: 200e6
        });

        (
            RebalanceLib.RebalanceAction[] memory deposits,
            RebalanceLib.RebalanceAction[] memory withdrawals
        ) = RebalanceLib.separateActions(actions);

        assertEq(deposits.length, 2);
        assertEq(withdrawals.length, 2);

        assertEq(deposits[0].strategy, STRATEGY2);
        assertEq(deposits[0].amount, 500e6);

        assertEq(withdrawals[0].strategy, STRATEGY1);
        assertEq(withdrawals[0].amount, 1000e6);
    }

    // ============ FUZZ TESTS ============

    function testFuzz_calculateAllocationStates(
        uint256 value1,
        uint256 value2,
        uint256 target1,
        uint256 target2
    ) public pure {
        // Bound inputs
        value1 = bound(value1, 1e6, 1_000_000e6);
        value2 = bound(value2, 1e6, 1_000_000e6);
        target1 = bound(target1, 1000, 9000);
        target2 = 10000 - target1;

        address[] memory strategies = new address[](2);
        strategies[0] = STRATEGY1;
        strategies[1] = STRATEGY2;

        uint256[] memory targetAllocations = new uint256[](2);
        targetAllocations[0] = target1;
        targetAllocations[1] = target2;

        uint256[] memory strategyValues = new uint256[](2);
        strategyValues[0] = value1;
        strategyValues[1] = value2;

        uint256 totalValue = value1 + value2;

        RebalanceLib.AllocationState[] memory states = RebalanceLib.calculateAllocationStates(
            strategies,
            targetAllocations,
            strategyValues,
            totalValue
        );

        // Verify allocations sum to 100%
        uint256 sumAllocations = states[0].currentAllocation + states[1].currentAllocation;
        assertApproxEqAbs(sumAllocations, 10000, 1); // Allow 1 basis point rounding error
    }
}
