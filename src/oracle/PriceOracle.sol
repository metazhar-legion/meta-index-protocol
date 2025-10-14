// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Chainlink Aggregator V3 Interface (simplified)
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

/**
 * @title PriceOracle
 * @notice Price oracle system with Chainlink support
 * @dev Phase 1 MVP: Simple price feed management with staleness checks
 */
contract PriceOracle is IPriceOracle, AccessControl {
    // ============ STATE VARIABLES ============

    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    // Asset => Price Feed
    mapping(address => address) private priceFeeds;

    // Staleness threshold (24 hours)
    uint256 public constant STALENESS_THRESHOLD = 24 hours;

    // Price deviation tolerance (10% = 1000 basis points)
    uint256 public constant MAX_PRICE_DEVIATION = 1000;

    // ============ CONSTRUCTOR ============

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_MANAGER_ROLE, msg.sender);
    }

    // ============ EXTERNAL FUNCTIONS ============

    /**
     * @notice Get USD price for an asset
     * @param asset Address of the asset
     * @return price Price in USD with 8 decimals
     */
    function getPrice(address asset) external view returns (uint256 price) {
        address feed = priceFeeds[asset];
        if (feed == address(0)) revert PriceFeedNotFound();

        AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);

        (
            uint80 roundId,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // Validate price data
        if (answer <= 0) revert InvalidPrice();
        if (answeredInRound < roundId) revert StalePrice();
        if (block.timestamp - updatedAt > STALENESS_THRESHOLD) revert StalePrice();

        // Normalize to 8 decimals
        uint8 feedDecimals = priceFeed.decimals();
        if (feedDecimals == 8) {
            price = uint256(answer);
        } else if (feedDecimals < 8) {
            price = uint256(answer) * (10 ** (8 - feedDecimals));
        } else {
            price = uint256(answer) / (10 ** (feedDecimals - 8));
        }
    }

    /**
     * @notice Get USD value for an amount of asset
     * @param asset Address of the asset
     * @param amount Amount of asset (in asset's decimals)
     * @return value USD value with 8 decimals
     */
    function getValue(address asset, uint256 amount) external view returns (uint256 value) {
        uint256 price = this.getPrice(asset);

        // Get asset decimals
        uint8 decimals = IERC20Metadata(asset).decimals();

        // value = (amount * price) / (10 ** assetDecimals)
        // Result has 8 decimals
        value = (amount * price) / (10 ** decimals);
    }

    /**
     * @notice Check if price feed exists for asset
     * @param asset Address of the asset
     * @return exists True if price feed is configured
     */
    function hasPriceFeed(address asset) external view returns (bool exists) {
        return priceFeeds[asset] != address(0);
    }

    /**
     * @notice Add or update price feed for an asset
     * @param asset Address of the asset
     * @param priceFeed Address of the Chainlink price feed
     */
    function setPriceFeed(address asset, address priceFeed)
        external
        onlyRole(ORACLE_MANAGER_ROLE)
    {
        if (asset == address(0)) revert InvalidPriceFeed();
        if (priceFeed == address(0)) revert InvalidPriceFeed();

        address oldFeed = priceFeeds[asset];

        priceFeeds[asset] = priceFeed;

        if (oldFeed == address(0)) {
            emit PriceFeedAdded(asset, priceFeed);
        } else {
            emit PriceFeedUpdated(asset, oldFeed, priceFeed);
        }
    }

    /**
     * @notice Remove price feed for an asset
     * @param asset Address of the asset
     */
    function removePriceFeed(address asset) external onlyRole(ORACLE_MANAGER_ROLE) {
        if (priceFeeds[asset] == address(0)) revert PriceFeedNotFound();

        delete priceFeeds[asset];
        emit PriceFeedRemoved(asset);
    }

    /**
     * @notice Get price feed address for an asset
     * @param asset Address of the asset
     * @return feed Address of the price feed
     */
    function getPriceFeed(address asset) external view returns (address feed) {
        return priceFeeds[asset];
    }
}
