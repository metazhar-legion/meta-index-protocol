import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, '../..');
const DEPLOYMENTS_FILE = path.join(ROOT_DIR, 'deployments/latest.json');
const ENV_FILE = path.join(__dirname, '../.env.local');

async function updateAddresses() {
  console.log('📝 Updating contract addresses...');

  // Read deployment addresses
  if (!fs.existsSync(DEPLOYMENTS_FILE)) {
    console.error('❌ Deployment file not found. Run deployment script first.');
    process.exit(1);
  }

  const deployment = JSON.parse(fs.readFileSync(DEPLOYMENTS_FILE, 'utf-8'));

  // Create or update .env.local
  const envContent = `# Auto-generated from deployments/latest.json
# Chain Configuration
VITE_CHAIN_ID=31337

# Contract Addresses
VITE_VAULT_ADDRESS=${deployment.vault}
VITE_STRATEGY_MANAGER_ADDRESS=${deployment.strategyManager}
VITE_USDC_ADDRESS=${deployment.usdc}
VITE_PRICE_ORACLE_ADDRESS=${deployment.priceOracle}
VITE_SWAP_ROUTER_ADDRESS=${deployment.swapRouter}

# Strategy Addresses
VITE_STRATEGY1_ADDRESS=${deployment.strategy1}
VITE_STRATEGY2_ADDRESS=${deployment.strategy2}

# WalletConnect Project ID (get from https://cloud.walletconnect.com)
VITE_WALLETCONNECT_PROJECT_ID=your_project_id_here
`;

  fs.writeFileSync(ENV_FILE, envContent);

  console.log('✅ Contract addresses updated in .env.local');
  console.log('\nDeployed addresses:');
  console.log(`   Vault:            ${deployment.vault}`);
  console.log(`   Strategy Manager: ${deployment.strategyManager}`);
  console.log(`   USDC:             ${deployment.usdc}`);
  console.log(`   Price Oracle:     ${deployment.priceOracle}`);
  console.log(`   Swap Router:      ${deployment.swapRouter}`);
}

updateAddresses().catch(console.error);
