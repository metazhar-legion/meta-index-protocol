#!/bin/bash
# Meta Index Protocol - Complete Development Setup
# This script sets up the entire development environment

set -e

echo "🚀 Meta Index Protocol - Development Setup"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Anvil is running
check_anvil() {
  if ! nc -z localhost 8545 2>/dev/null; then
    echo "❌ Anvil is not running on port 8545"
    echo "Please start Anvil in a separate terminal:"
    echo "  anvil"
    exit 1
  fi
  echo "✅ Anvil is running"
}

# Deploy contracts
deploy_contracts() {
  echo ""
  echo "${BLUE}📝 Deploying contracts...${NC}"
  forge script script/Deploy.s.sol \
    --rpc-url http://localhost:8545 \
    --broadcast \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

  echo "${GREEN}✅ Contracts deployed${NC}"
}

# Generate ABIs
generate_abis() {
  echo ""
  echo "${BLUE}📦 Generating ABIs...${NC}"
  cd frontend
  npm run generate-abis
  echo "${GREEN}✅ ABIs generated${NC}"
  cd ..
}

# Update addresses
update_addresses() {
  echo ""
  echo "${BLUE}🔄 Updating contract addresses...${NC}"
  cd frontend
  npm run update-addresses
  echo "${GREEN}✅ Addresses updated${NC}"
  cd ..
}

# Main execution
main() {
  check_anvil
  deploy_contracts
  generate_abis
  update_addresses

  echo ""
  echo "${GREEN}=========================================="
  echo "✨ Setup complete! ✨"
  echo "==========================================${NC}"
  echo ""
  echo "To start the frontend:"
  echo "  cd frontend"
  echo "  npm run dev:anvil"
  echo ""
  echo "Then visit: http://localhost:5173"
  echo ""
  echo "MetaMask Setup:"
  echo "  Network: Anvil Local"
  echo "  RPC URL: http://127.0.0.1:8545"
  echo "  Chain ID: 31337"
  echo "  Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
}

main
