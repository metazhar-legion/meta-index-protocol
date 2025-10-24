import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, '../..');
const OUT_DIR = path.join(ROOT_DIR, 'out');
const ABIS_DIR = path.join(__dirname, '../src/contracts/abis');

// Contracts to export ABIs for
const CONTRACTS = [
  'MetaIndexVault',
  'StrategyManager',
  'MockERC20',
  'MockPriceOracle',
  'MockSwapRouter',
  'MockStrategy',
];

async function generateABIs() {
  console.log('🔨 Generating ABIs...');
  console.log(`   Reading from: ${OUT_DIR}`);
  console.log(`   Writing to: ${ABIS_DIR}`);

  // Ensure output directory exists
  if (!fs.existsSync(ABIS_DIR)) {
    fs.mkdirSync(ABIS_DIR, { recursive: true });
  }

  for (const contractName of CONTRACTS) {
    try {
      // Read the compiled contract artifact
      const artifactPath = path.join(
        OUT_DIR,
        `${contractName}.sol`,
        `${contractName}.json`
      );

      if (!fs.existsSync(artifactPath)) {
        console.warn(`   ⚠️  ${contractName}: Artifact not found at ${artifactPath}`);
        continue;
      }

      const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf-8'));

      // Extract the ABI
      const abi = artifact.abi;

      // Write ABI to file
      const abiPath = path.join(ABIS_DIR, `${contractName}.json`);
      fs.writeFileSync(abiPath, JSON.stringify(abi, null, 2));

      console.log(`   ✅ ${contractName}`);
    } catch (error) {
      console.error(`   ❌ ${contractName}:`, error);
    }
  }

  console.log('✨ Done!');
}

generateABIs().catch(console.error);
