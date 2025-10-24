// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MetaIndexVault} from "../src/MetaIndexVault.sol";
import {StrategyManager} from "../src/StrategyManager.sol";
import {MockStrategy} from "../src/strategies/MockStrategy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockPriceOracle} from "../src/mocks/MockPriceOracle.sol";
import {MockSwapRouter} from "../src/mocks/MockSwapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Deploy
 * @notice Deployment script for Meta Index Protocol
 * @dev Deploys all contracts and sets up initial configuration
 *
 * Usage:
 *   Local:  forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
 *   Testnet: forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
 */
contract Deploy is Script {
    // Deployment addresses (will be populated during deployment)
    address public usdc;
    address public vault;
    address public strategyManager;
    address public strategy1;
    address public strategy2;
    address public priceOracle;
    address public swapRouter;

    // Deployer
    address public deployer;

    // Configuration constants
    uint256 constant INITIAL_MINT = 1_000_000e6; // 1M USDC for testing
    uint256 constant STRATEGY1_ALLOCATION = 6000; // 60%
    uint256 constant STRATEGY2_ALLOCATION = 4000; // 40%

    function run() external {
        // Get deployer from private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy mock USDC
        console.log("\n1. Deploying MockERC20 (USDC)...");
        usdc = address(new MockERC20("USD Coin", "USDC", 6));
        console.log("   USDC deployed at:", usdc);

        // Mint initial supply to deployer
        MockERC20(usdc).mint(deployer, INITIAL_MINT);
        console.log("   Minted", INITIAL_MINT / 1e6, "USDC to deployer");

        // 2. Deploy MetaIndexVault
        console.log("\n2. Deploying MetaIndexVault...");
        vault = address(
            new MetaIndexVault(
                IERC20(usdc),
                "Meta Index Vault",
                "MIV"
            )
        );
        console.log("   Vault deployed at:", vault);

        // 3. Deploy MockPriceOracle
        console.log("\n3. Deploying MockPriceOracle...");
        priceOracle = address(new MockPriceOracle());
        console.log("   PriceOracle deployed at:", priceOracle);

        // Set initial USDC price (1 USD = 1e8 with 8 decimals)
        MockPriceOracle(priceOracle).setPrice(usdc, 1e8);
        console.log("   Set USDC price to 1.00 USD");

        // 4. Deploy MockSwapRouter
        console.log("\n4. Deploying MockSwapRouter...");
        swapRouter = address(new MockSwapRouter());
        console.log("   SwapRouter deployed at:", swapRouter);

        // 5. Deploy StrategyManager
        console.log("\n5. Deploying StrategyManager...");
        strategyManager = address(
            new StrategyManager(vault, usdc, priceOracle)
        );
        console.log("   StrategyManager deployed at:", strategyManager);

        // 6. Set strategy manager in vault
        console.log("\n6. Configuring vault...");
        MetaIndexVault(vault).setStrategyManager(strategyManager);
        console.log("   Strategy manager set in vault");

        // Grant manager role to deployer for testing
        MetaIndexVault(vault).grantRole(
            MetaIndexVault(vault).MANAGER_ROLE(),
            deployer
        );
        console.log("   Granted MANAGER_ROLE to deployer");

        // Grant guardian role to deployer
        MetaIndexVault(vault).grantRole(
            MetaIndexVault(vault).GUARDIAN_ROLE(),
            deployer
        );
        console.log("   Granted GUARDIAN_ROLE to deployer");

        // 7. Deploy mock strategies
        console.log("\n7. Deploying mock strategies...");

        strategy1 = address(
            new MockStrategy(
                vault,
                strategyManager,
                usdc
            )
        );
        console.log("   Strategy1 (DeFi) deployed at:", strategy1);

        strategy2 = address(
            new MockStrategy(
                vault,
                strategyManager,
                usdc
            )
        );
        console.log("   Strategy2 (Yield) deployed at:", strategy2);

        // 8. Add strategies to manager
        console.log("\n8. Adding strategies to manager...");
        StrategyManager(strategyManager).addStrategy(strategy1, STRATEGY1_ALLOCATION);
        console.log("   Added Strategy1 with 60% allocation");

        StrategyManager(strategyManager).addStrategy(strategy2, STRATEGY2_ALLOCATION);
        console.log("   Added Strategy2 with 40% allocation");

        vm.stopBroadcast();

        // 9. Print deployment summary
        printDeploymentSummary();

        // 10. Save deployment addresses to file
        saveDeploymentAddresses();
    }

    function printDeploymentSummary() internal view {
        console.log("\n" "========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Deployer:          ", deployer);
        console.log("USDC:              ", usdc);
        console.log("Vault:             ", vault);
        console.log("StrategyManager:   ", strategyManager);
        console.log("Strategy1 (DeFi):  ", strategy1);
        console.log("Strategy2 (Yield): ", strategy2);
        console.log("PriceOracle:       ", priceOracle);
        console.log("SwapRouter:        ", swapRouter);
        console.log("========================================\n");
    }

    function saveDeploymentAddresses() internal {
        string memory deploymentData = string.concat(
            "{\n",
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "usdc": "', vm.toString(usdc), '",\n',
            '  "vault": "', vm.toString(vault), '",\n',
            '  "strategyManager": "', vm.toString(strategyManager), '",\n',
            '  "strategy1": "', vm.toString(strategy1), '",\n',
            '  "strategy2": "', vm.toString(strategy2), '",\n',
            '  "priceOracle": "', vm.toString(priceOracle), '",\n',
            '  "swapRouter": "', vm.toString(swapRouter), '"\n',
            "}"
        );

        vm.writeFile("deployments/latest.json", deploymentData);
        console.log("Deployment addresses saved to: deployments/latest.json");
    }
}
