// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title MockPriceOracle
 * @notice Mock oracle for testing - allows setting arbitrary prices
 * @dev Prices are stored with 8 decimals precision
 */
contract MockPriceOracle is IPriceOracle {
    // Asset => Price (8 decimals)
    mapping(address => uint256) private prices;
    mapping(address => bool) private hasFeed;

    /**
     * @notice Set price for an asset
     * @param asset Address of the asset
     * @param price Price in USD with 8 decimals
     */
    function setPrice(address asset, uint256 price) external {
        prices[asset] = price;
        hasFeed[asset] = true;
    }

    /**
     * @notice Get USD price for an asset
     * @param asset Address of the asset
     * @return price Price in USD with 8 decimals
     */
    function getPrice(address asset) external view returns (uint256 price) {
        if (!hasFeed[asset]) revert PriceFeedNotFound();
        price = prices[asset];
        if (price == 0) revert InvalidPrice();
    }

    /**
     * @notice Get USD value for an amount of asset
     * @param asset Address of the asset
     * @param amount Amount of asset (in asset's decimals)
     * @return value USD value with 8 decimals
     */
    function getValue(address asset, uint256 amount) external view returns (uint256 value) {
        if (!hasFeed[asset]) revert PriceFeedNotFound();
        uint256 price = prices[asset];
        if (price == 0) revert InvalidPrice();

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
        return hasFeed[asset];
    }

    /**
     * @notice Add or update price feed for an asset
     * @param asset Address of the asset
     * @param priceFeed Ignored in mock (kept for interface compatibility)
     */
    function setPriceFeed(address asset, address priceFeed) external {
        priceFeed; // Silence unused warning
        hasFeed[asset] = true;
        emit PriceFeedAdded(asset, address(this));
    }

    /**
     * @notice Remove price feed for an asset
     * @param asset Address of the asset
     */
    function removePriceFeed(address asset) external {
        hasFeed[asset] = false;
        prices[asset] = 0;
        emit PriceFeedRemoved(asset);
    }
}
