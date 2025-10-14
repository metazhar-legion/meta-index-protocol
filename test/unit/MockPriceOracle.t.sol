// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockPriceOracle} from "../../src/mocks/MockPriceOracle.sol";
import {IPriceOracle} from "../../src/interfaces/IPriceOracle.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";

contract MockPriceOracleTest is Test {
    MockPriceOracle public oracle;
    MockERC20 public usdc;
    MockERC20 public weth;

    uint256 constant USDC_PRICE = 1_00000000; // $1.00 (8 decimals)
    uint256 constant WETH_PRICE = 2000_00000000; // $2000.00 (8 decimals)

    function setUp() public {
        oracle = new MockPriceOracle();
        usdc = new MockERC20("USDC", "USDC", 6);
        weth = new MockERC20("WETH", "WETH", 18);
    }

    // ============ SET PRICE TESTS ============

    function test_setPrice_success() public {
        oracle.setPrice(address(usdc), USDC_PRICE);

        assertTrue(oracle.hasPriceFeed(address(usdc)));
        assertEq(oracle.getPrice(address(usdc)), USDC_PRICE);
    }

    function test_setPrice_multipleAssets() public {
        oracle.setPrice(address(usdc), USDC_PRICE);
        oracle.setPrice(address(weth), WETH_PRICE);

        assertEq(oracle.getPrice(address(usdc)), USDC_PRICE);
        assertEq(oracle.getPrice(address(weth)), WETH_PRICE);
    }

    // ============ GET PRICE TESTS ============

    function test_getPrice_revertsNoPriceFeed() public {
        vm.expectRevert(IPriceOracle.PriceFeedNotFound.selector);
        oracle.getPrice(address(usdc));
    }

    function test_getPrice_revertsZeroPrice() public {
        oracle.setPrice(address(usdc), 0);

        vm.expectRevert(IPriceOracle.InvalidPrice.selector);
        oracle.getPrice(address(usdc));
    }

    // ============ GET VALUE TESTS ============

    function test_getValue_usdc() public {
        oracle.setPrice(address(usdc), USDC_PRICE);

        // 1000 USDC (6 decimals) = $1000 (8 decimals)
        uint256 value = oracle.getValue(address(usdc), 1000e6);
        assertEq(value, 1000_00000000);
    }

    function test_getValue_weth() public {
        oracle.setPrice(address(weth), WETH_PRICE);

        // 1 WETH (18 decimals) = $2000 (8 decimals)
        uint256 value = oracle.getValue(address(weth), 1e18);
        assertEq(value, WETH_PRICE);
    }

    function test_getValue_partialAmount() public {
        oracle.setPrice(address(weth), WETH_PRICE);

        // 0.5 WETH = $1000
        uint256 value = oracle.getValue(address(weth), 0.5e18);
        assertEq(value, 1000_00000000);
    }

    function test_getValue_revertsNoPriceFeed() public {
        vm.expectRevert(IPriceOracle.PriceFeedNotFound.selector);
        oracle.getValue(address(usdc), 1000e6);
    }

    // ============ HAS PRICE FEED TESTS ============

    function test_hasPriceFeed_false() public view {
        assertFalse(oracle.hasPriceFeed(address(usdc)));
    }

    function test_hasPriceFeed_true() public {
        oracle.setPrice(address(usdc), USDC_PRICE);
        assertTrue(oracle.hasPriceFeed(address(usdc)));
    }

    // ============ SET PRICE FEED TESTS ============

    function test_setPriceFeed_success() public {
        address fakeFeed = makeAddr("fakeFeed");

        vm.expectEmit(true, true, true, true);
        emit IPriceOracle.PriceFeedAdded(address(usdc), address(oracle));

        oracle.setPriceFeed(address(usdc), fakeFeed);

        assertTrue(oracle.hasPriceFeed(address(usdc)));
    }

    // ============ REMOVE PRICE FEED TESTS ============

    function test_removePriceFeed_success() public {
        oracle.setPrice(address(usdc), USDC_PRICE);

        vm.expectEmit(true, true, true, true);
        emit IPriceOracle.PriceFeedRemoved(address(usdc));

        oracle.removePriceFeed(address(usdc));

        assertFalse(oracle.hasPriceFeed(address(usdc)));
    }

    // ============ FUZZ TESTS ============

    function testFuzz_setPrice(uint256 price) public {
        price = bound(price, 1, type(uint128).max); // Reasonable price range

        oracle.setPrice(address(usdc), price);

        assertEq(oracle.getPrice(address(usdc)), price);
    }

    function testFuzz_getValue(uint256 amount, uint256 price) public {
        amount = bound(amount, 1, type(uint64).max); // Reasonable amount
        price = bound(price, 1, type(uint64).max); // Reasonable price

        oracle.setPrice(address(usdc), price);

        uint256 value = oracle.getValue(address(usdc), amount);

        // value = (amount * price) / 10^6 (USDC decimals)
        uint256 expected = (amount * price) / 1e6;
        assertEq(value, expected);
    }
}
