// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title RebalanceLib
 * @notice Library for portfolio rebalancing calculations
 * @dev Phase 1D: Handles allocation calculations and deviation checks
 */
library RebalanceLib {
    // ============ CONSTANTS ============

    uint256 public constant BPS_DENOMINATOR = 10_000; // 100% = 10000 basis points
    uint256 public constant DEFAULT_DEVIATION_THRESHOLD = 500; // 5% deviation threshold

    // ============ STRUCTS ============

    /**
     * @notice Represents a strategy's allocation state
     * @param strategy Address of the strategy
     * @param targetAllocation Target allocation in basis points
     * @param currentValue Current value in strategy
     * @param currentAllocation Current allocation in basis points
     * @param deviation Deviation from target in basis points
     */
    struct AllocationState {
        address strategy;
        uint256 targetAllocation;
        uint256 currentValue;
        uint256 currentAllocation;
        int256 deviation;
    }

    /**
     * @notice Represents a rebalancing action
     * @param strategy Address of the strategy
     * @param action 0 = withdraw, 1 = deposit
     * @param amount Amount to withdraw or deposit
     */
    struct RebalanceAction {
        address strategy;
        uint8 action; // 0 = withdraw, 1 = deposit
        uint256 amount;
    }

    // ============ ERRORS ============

    error InvalidAllocation();
    error AllocationSumNotValid();
    error InsufficientTotalValue();

    // ============ PUBLIC FUNCTIONS ============

    /**
     * @notice Calculate current allocations for all strategies
     * @param strategies Array of strategy addresses
     * @param targetAllocations Array of target allocations (in BPS)
     * @param strategyValues Array of current strategy values
     * @param totalValue Total portfolio value
     * @return states Array of allocation states
     */
    function calculateAllocationStates(
        address[] memory strategies,
        uint256[] memory targetAllocations,
        uint256[] memory strategyValues,
        uint256 totalValue
    ) public pure returns (AllocationState[] memory states) {
        if (strategies.length != targetAllocations.length) revert InvalidAllocation();
        if (strategies.length != strategyValues.length) revert InvalidAllocation();
        if (totalValue == 0) revert InsufficientTotalValue();

        states = new AllocationState[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 currentAllocation = (strategyValues[i] * BPS_DENOMINATOR) / totalValue;
            int256 deviation = int256(currentAllocation) - int256(targetAllocations[i]);

            states[i] = AllocationState({
                strategy: strategies[i],
                targetAllocation: targetAllocations[i],
                currentValue: strategyValues[i],
                currentAllocation: currentAllocation,
                deviation: deviation
            });
        }

        return states;
    }

    /**
     * @notice Check if rebalancing is needed based on deviation threshold
     * @param states Array of allocation states
     * @param deviationThreshold Maximum allowed deviation in BPS (e.g., 500 = 5%)
     * @return needsRebalance True if any strategy exceeds deviation threshold
     */
    function needsRebalancing(
        AllocationState[] memory states,
        uint256 deviationThreshold
    ) public pure returns (bool needsRebalance) {
        for (uint256 i = 0; i < states.length; i++) {
            // Use absolute value of deviation
            uint256 absDeviation = states[i].deviation >= 0
                ? uint256(states[i].deviation)
                : uint256(-states[i].deviation);

            if (absDeviation > deviationThreshold) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Calculate rebalancing actions needed to reach target allocations
     * @param states Array of allocation states
     * @param totalValue Total portfolio value
     * @return actions Array of rebalancing actions
     */
    function calculateRebalanceActions(
        AllocationState[] memory states,
        uint256 totalValue
    ) public pure returns (RebalanceAction[] memory actions) {
        if (totalValue == 0) revert InsufficientTotalValue();

        actions = new RebalanceAction[](states.length);
        uint256 actionCount = 0;

        for (uint256 i = 0; i < states.length; i++) {
            uint256 targetValue = (totalValue * states[i].targetAllocation) / BPS_DENOMINATOR;

            if (targetValue > states[i].currentValue) {
                // Need to deposit
                uint256 depositAmount = targetValue - states[i].currentValue;
                actions[actionCount] = RebalanceAction({
                    strategy: states[i].strategy,
                    action: 1, // deposit
                    amount: depositAmount
                });
                actionCount++;
            } else if (targetValue < states[i].currentValue) {
                // Need to withdraw
                uint256 withdrawAmount = states[i].currentValue - targetValue;
                actions[actionCount] = RebalanceAction({
                    strategy: states[i].strategy,
                    action: 0, // withdraw
                    amount: withdrawAmount
                });
                actionCount++;
            }
        }

        // Trim array to actual size
        RebalanceAction[] memory trimmedActions = new RebalanceAction[](actionCount);
        for (uint256 i = 0; i < actionCount; i++) {
            trimmedActions[i] = actions[i];
        }

        return trimmedActions;
    }

    /**
     * @notice Validate that target allocations sum to 100%
     * @param targetAllocations Array of target allocations in BPS
     * @return valid True if sum equals 10000 (100%)
     */
    function validateAllocations(uint256[] memory targetAllocations)
        public
        pure
        returns (bool valid)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < targetAllocations.length; i++) {
            sum += targetAllocations[i];
        }
        return sum == BPS_DENOMINATOR;
    }

    /**
     * @notice Calculate total deposits and withdrawals needed
     * @param actions Array of rebalancing actions
     * @return totalDeposits Total amount to deposit across all strategies
     * @return totalWithdrawals Total amount to withdraw across all strategies
     */
    function calculateTotals(RebalanceAction[] memory actions)
        public
        pure
        returns (uint256 totalDeposits, uint256 totalWithdrawals)
    {
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].action == 1) {
                totalDeposits += actions[i].amount;
            } else {
                totalWithdrawals += actions[i].amount;
            }
        }
        return (totalDeposits, totalWithdrawals);
    }

    /**
     * @notice Get strategies that need deposits vs withdrawals
     * @param actions Array of rebalancing actions
     * @return depositStrategies Strategies that need deposits
     * @return withdrawStrategies Strategies that need withdrawals
     */
    function separateActions(RebalanceAction[] memory actions)
        public
        pure
        returns (
            RebalanceAction[] memory depositStrategies,
            RebalanceAction[] memory withdrawStrategies
        )
    {
        uint256 depositCount = 0;
        uint256 withdrawCount = 0;

        // Count actions
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].action == 1) {
                depositCount++;
            } else {
                withdrawCount++;
            }
        }

        // Create arrays
        depositStrategies = new RebalanceAction[](depositCount);
        withdrawStrategies = new RebalanceAction[](withdrawCount);

        uint256 depositIndex = 0;
        uint256 withdrawIndex = 0;

        // Populate arrays
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].action == 1) {
                depositStrategies[depositIndex] = actions[i];
                depositIndex++;
            } else {
                withdrawStrategies[withdrawIndex] = actions[i];
                withdrawIndex++;
            }
        }

        return (depositStrategies, withdrawStrategies);
    }
}
