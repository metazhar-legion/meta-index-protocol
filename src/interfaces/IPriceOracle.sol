// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IPriceOracle
 * @notice Interface for price oracle system
 * @dev Provides USD prices for assets with 8 decimals precision (Chainlink standard)
 */
interface IPriceOracle {
    // ============ EVENTS ============

    event PriceFeedAdded(address indexed asset, address indexed priceFeed);
    event PriceFeedUpdated(address indexed asset, address indexed oldFeed, address indexed newFeed);
    event PriceFeedRemoved(address indexed asset);

    // ============ ERRORS ============

    error PriceFeedNotFound();
    error StalePrice();
    error InvalidPrice();
    error InvalidPriceFeed();

    // ============ FUNCTIONS ============

    /**
     * @notice Get USD price for an asset
     * @param asset Address of the asset
     * @return price Price in USD with 8 decimals (e.g., 1 ETH = 200000000000 = $2000.00)
     */
    function getPrice(address asset) external view returns (uint256 price);

    /**
     * @notice Get USD value for an amount of asset
     * @param asset Address of the asset
     * @param amount Amount of asset (in asset's decimals)
     * @return value USD value with 8 decimals
     */
    function getValue(address asset, uint256 amount) external view returns (uint256 value);

    /**
     * @notice Check if price feed exists for asset
     * @param asset Address of the asset
     * @return exists True if price feed is configured
     */
    function hasPriceFeed(address asset) external view returns (bool exists);

    /**
     * @notice Add or update price feed for an asset
     * @param asset Address of the asset
     * @param priceFeed Address of the Chainlink price feed
     */
    function setPriceFeed(address asset, address priceFeed) external;

    /**
     * @notice Remove price feed for an asset
     * @param asset Address of the asset
     */
    function removePriceFeed(address asset) external;
}
