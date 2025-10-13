// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title MetaIndexVault
 * @notice ERC-4626 vault for Meta Index Protocol
 * @dev Phase 1: Basic deposit/withdraw with strategy manager integration
 */
contract MetaIndexVault is ERC4626, AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ============ STATE VARIABLES ============

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    address public strategyManager;
    uint256 public tvlCap; // Phase 1: $10k cap for testing
    uint256 public minDeposit;

    // Fee tracking (not collected in Phase 1, just tracked)
    uint256 public managementFee; // Basis points (75 = 0.75%)
    uint256 public lastFeeTimestamp;

    // ============ EVENTS ============

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event TVLCapUpdated(uint256 oldCap, uint256 newCap);
    event StrategyManagerUpdated(address oldManager, address newManager);

    // ============ ERRORS ============

    error BelowMinimumDeposit();
    error ExceedsTVLCap();
    error ZeroAddress();
    error ZeroAmount();

    // ============ CONSTRUCTOR ============

    /**
     * @notice Initialize the vault
     * @param _asset Underlying asset (e.g., USDC)
     * @param _name Vault token name
     * @param _symbol Vault token symbol
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Phase 1 defaults
        tvlCap = 10_000e6; // $10k USDC for testing
        minDeposit = 10e6; // $10 minimum
        managementFee = 75; // 0.75%
        lastFeeTimestamp = block.timestamp;
    }

    // ============ DEPOSIT/WITHDRAW ============

    /**
     * @notice Deposit assets and receive vault shares
     * @param assets Amount of underlying to deposit
     * @param receiver Address to receive shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        if (assets < minDeposit) revert BelowMinimumDeposit();
        if (totalAssets() + assets > tvlCap) revert ExceedsTVLCap();
        if (receiver == address(0)) revert ZeroAddress();

        // Standard ERC-4626 deposit
        shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        emit Deposited(receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Withdraw assets by burning shares
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive assets
     * @param owner Address that owns the shares
     * @return shares Amount of shares burned
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        emit Withdrawn(receiver, assets, shares);

        return shares;
    }

    // ============ ACCOUNTING ============

    /**
     * @notice Get total assets under management
     * @dev Phase 1: Just vault balance, no strategy calls yet
     * @return Total assets in vault
     */
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    // ============ ADMIN FUNCTIONS ============

    /**
     * @notice Update TVL cap
     * @param newCap New TVL cap
     */
    function updateTVLCap(uint256 newCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldCap = tvlCap;
        tvlCap = newCap;
        emit TVLCapUpdated(oldCap, newCap);
    }

    /**
     * @notice Set strategy manager address
     * @param _manager Strategy manager address
     */
    function setStrategyManager(address _manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_manager == address(0)) revert ZeroAddress();
        address oldManager = strategyManager;
        strategyManager = _manager;
        emit StrategyManagerUpdated(oldManager, _manager);
    }

    /**
     * @notice Emergency pause
     */
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
