// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract TestHelpers is Test {
    // Standard test addresses
    address internal constant ALICE = address(0x1);
    address internal constant BOB = address(0x2);
    address internal constant CHARLIE = address(0x3);

    // Standard amounts
    uint256 internal constant INITIAL_BALANCE = 100_000e6;
    uint256 internal constant DEPOSIT_AMOUNT = 1_000e6;

    /**
     * @notice Create and fund mock ERC20
     */
    function createMockToken(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal returns (MockERC20) {
        return new MockERC20(name, symbol, decimals);
    }

    /**
     * @notice Fund address with mock tokens
     */
    function fundAddress(
        MockERC20 token,
        address user,
        uint256 amount
    ) internal {
        token.mint(user, amount);
    }

    /**
     * @notice Approve and deposit to vault
     */
    function depositToVault(
        address vault,
        MockERC20 token,
        address user,
        uint256 amount
    ) internal {
        vm.startPrank(user);
        token.approve(vault, amount);
        // Assume vault has deposit function
        (bool success,) = vault.call(
            abi.encodeWithSignature(
                "deposit(uint256,address)",
                amount,
                user
            )
        );
        require(success, "Deposit failed");
        vm.stopPrank();
    }
}
