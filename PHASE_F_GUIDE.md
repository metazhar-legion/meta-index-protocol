# Phase F: Frontend Integration Guide

## Overview

Phase F delivers a complete React frontend for the Meta Index Protocol, enabling users to interact with vaults, deposit/withdraw funds, and view strategy allocations.

## What's Been Built

### Smart Contract Infrastructure
- ✅ **Deployment Script** (`script/Deploy.s.sol`): Deploys all contracts to local Anvil or testnet
- ✅ **Complete Contract Suite**: Vault, StrategyManager, Strategies, Oracles, and Mocks

### Frontend Application
- ✅ **React + TypeScript + Vite**: Modern, fast development experience
- ✅ **Web3 Integration**: Wagmi v2 + Viem for blockchain interactions
- ✅ **Wallet Connection**: MetaMask and WalletConnect support
- ✅ **Vault Dashboard**: Deposit, withdraw, view positions
- ✅ **Strategy Management**: View active strategies and allocations
- ✅ **Real-time Updates**: Live TVL, balances, and transaction status

### Developer Tools
- ✅ **ABI Generation**: Automatic ABI extraction from compiled contracts
- ✅ **Address Management**: Auto-update frontend with deployed addresses
- ✅ **Development Scripts**: One-command setup for local development
- ✅ **Multi-chain Support**: Easy configuration for different networks

## Quick Start (5 Minutes)

### Prerequisites

- Node.js 18+ and npm
- Foundry (forge, anvil)
- MetaMask browser extension

### Step 1: Start Local Blockchain

```bash
# Terminal 1: Start Anvil
anvil
```

Keep this terminal running. Anvil provides:
- Local Ethereum node on `http://127.0.0.1:8545`
- 10 funded test accounts
- Instant block times
- Deterministic addresses

### Step 2: Deploy Contracts

```bash
# Terminal 2: In project root
forge script script/Deploy.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

This deploys:
- MockERC20 (USDC)
- MetaIndexVault
- StrategyManager
- 2 MockStrategies
- PriceOracle
- SwapRouter

Deployment addresses are saved to `deployments/latest.json`.

### Step 3: Setup Frontend

```bash
cd frontend

# Install dependencies (first time only)
npm install

# Generate ABIs from compiled contracts
npm run generate-abis

# Update contract addresses from deployment
npm run update-addresses
```

### Step 4: Start Frontend

```bash
npm run dev:anvil
```

Visit **http://localhost:5173** 🎉

### Step 5: Connect MetaMask

1. **Add Anvil Network**:
   - Network Name: `Anvil Local`
   - RPC URL: `http://127.0.0.1:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **Import Test Account**:
   - Click "Import Account" in MetaMask
   - Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
   - This account has 10,000 ETH and 1,000,000 USDC (from deployment)

3. **Connect to App**:
   - Click "Connect Wallet" button
   - Approve connection in MetaMask
   - You're ready to test!

## Testing the Application

### 1. Check Your Balances

After connecting, you should see:
- **USDC Balance**: 1,000,000 USDC
- **Vault Shares**: 0 (you haven't deposited yet)
- **Vault TVL**: ~0 USDC

### 2. Make a Deposit

1. Click "Deposit" button
2. Enter amount (e.g., 1000 USDC)
3. Click "Deposit"
4. Approve USDC spending in MetaMask (first time only)
5. Confirm deposit transaction
6. Wait for confirmation (instant on Anvil)
7. See your vault shares update!

### 3. View Strategies

Scroll down to see:
- 2 active strategies
- Strategy 1: 60% allocation
- Strategy 2: 40% allocation
- Total value across strategies

### 4. Make a Withdrawal

1. Click "Withdraw" button
2. Enter amount to withdraw
3. Confirm transaction
4. Receive USDC back to your wallet

## Architecture

### Frontend Structure

```
frontend/src/
├── components/
│   ├── wallet/
│   │   └── ConnectWallet.tsx      # Wallet connection UI
│   ├── vault/
│   │   ├── VaultDashboard.tsx     # Main dashboard
│   │   ├── DepositModal.tsx       # Deposit flow
│   │   └── WithdrawModal.tsx      # Withdraw flow
│   └── strategies/
│       └── StrategyList.tsx       # Strategy cards
├── hooks/
│   ├── useVault.ts                # Vault read/write functions
│   ├── useUSDC.ts                 # Token approvals and balance
│   └── useStrategies.ts           # Strategy data
├── contracts/
│   ├── abis/                      # Contract ABIs
│   └── addresses.ts               # Contract addresses
├── lib/
│   └── wagmi.ts                   # Web3 configuration
└── App.tsx                        # Main app
```

### Key Technologies

**Wagmi v2** - React hooks for Ethereum
- `useAccount()` - Get connected wallet address
- `useReadContract()` - Call view functions
- `useWriteContract()` - Send transactions
- `useWaitForTransactionReceipt()` - Wait for confirmations

**Viem** - TypeScript Ethereum library
- Type-safe contract interactions
- Parsing and formatting utilities
- Modern alternative to ethers.js

**TanStack Query** - State management
- Automatic refetching
- Caching and optimistic updates
- Error handling

## Contract Interaction Patterns

### Reading Data

```typescript
const { data: totalAssets } = useReadContract({
  address: contracts.vault,
  abi: VaultABI,
  functionName: 'totalAssets',
})
```

### Writing Data

```typescript
const { writeContract } = useWriteContract()

await writeContract({
  address: contracts.vault,
  abi: VaultABI,
  functionName: 'deposit',
  args: [parseUnits(amount, 6), receiverAddress],
})
```

### Transaction Flow

1. User clicks "Deposit"
2. Check if USDC approval needed
3. If yes: Request approval → Wait for confirmation
4. Send deposit transaction
5. Wait for confirmation
6. Show success message
7. Data automatically refetches

## Development Workflow

### Making Changes

#### Smart Contract Changes

```bash
# 1. Edit contracts in src/
# 2. Rebuild
forge build

# 3. Run tests
forge test

# 4. Redeploy
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 5. Update frontend
cd frontend
npm run generate-abis
npm run update-addresses
```

#### Frontend Changes

```bash
# Just edit files - Vite hot-reloads automatically!
# Changes appear instantly in browser
```

### Adding a New Contract Function

1. **Add function to contract** (e.g., `src/MetaIndexVault.sol`)
2. **Rebuild**: `forge build`
3. **Redeploy**: Re-run deployment script
4. **Update ABIs**: `npm run generate-abis`
5. **Use in hook**:
   ```typescript
   const { data } = useReadContract({
     address: contracts.vault,
     abi: VaultABI,
     functionName: 'yourNewFunction',
   })
   ```

## Multi-Chain Support

The frontend supports multiple networks:

### Local Development (Anvil)
```bash
VITE_CHAIN_ID=31337
npm run dev:anvil
```

### Arbitrum Sepolia (Testnet)
```bash
VITE_CHAIN_ID=421614
VITE_VAULT_ADDRESS=<deployed_address>
# ... update other addresses
npm run dev
```

### Arbitrum Mainnet
```bash
VITE_CHAIN_ID=42161
# ... update addresses
npm run dev
```

## Troubleshooting

### "Contract address not found"

**Solution**: Run `npm run update-addresses` to sync addresses from deployment.

### "Cannot find module 'MetaIndexVault.json'"

**Solution**: Run `npm run generate-abis` to extract ABIs from compiled contracts.

### Transactions failing

**Checklist**:
- [ ] Connected to correct network (Chain ID 31337 for Anvil)
- [ ] Have sufficient ETH for gas
- [ ] Have sufficient USDC balance
- [ ] Approved USDC spending (for deposits)
- [ ] Anvil is still running

### MetaMask shows wrong network

**Solution**:
1. Open MetaMask
2. Click network dropdown
3. Select "Anvil Local" (or add it if not present)

### Balance not updating

**Solution**:
- Wait a few seconds (automatic refetch)
- Or refresh the page
- Check MetaMask to verify transaction confirmed

## Testing Scenarios

### Happy Path Testing

1. ✅ Connect wallet
2. ✅ Check initial balances (1M USDC)
3. ✅ Deposit 100 USDC
4. ✅ Verify vault shares received
5. ✅ Check strategies show allocations
6. ✅ Withdraw 50 USDC
7. ✅ Verify USDC received back

### Edge Case Testing

1. ✅ Try depositing 0 USDC (should fail)
2. ✅ Try withdrawing more than you have (should fail)
3. ✅ Cancel transaction in MetaMask
4. ✅ Disconnect and reconnect wallet
5. ✅ Refresh page during transaction
6. ✅ Multiple deposits in sequence

## Next Steps (Future Phases)

### DAO Governance (Phase G)
- On-chain proposal creation
- Voting mechanism with governance tokens
- Timelock execution
- Role-based permissions

### Real Strategies (Phase H)
- Integrate actual DeFi protocols (Aave, Compound, Uniswap)
- Real yield generation
- Automated rebalancing triggers
- Risk management

### Production Deployment (Phase I)
- Mainnet deployment
- Security audit
- Gas optimization
- Subgraph for historical data
- Mobile responsiveness
- Analytics dashboard

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `npm run dev` | Start dev server (default network) |
| `npm run dev:anvil` | Start dev server for Anvil (31337) |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run generate-abis` | Extract ABIs from Foundry artifacts |
| `npm run update-addresses` | Sync deployed addresses to .env.local |

| Foundry | Purpose |
|---------|---------|
| `anvil` | Start local Ethereum node |
| `forge build` | Compile contracts |
| `forge test` | Run contract tests |
| `forge script script/Deploy.s.sol` | Deploy contracts |

## File Locations

- **Contract Addresses**: `deployments/latest.json`
- **Frontend Config**: `frontend/.env.local`
- **ABIs**: `frontend/src/contracts/abis/`
- **Deployment Script**: `script/Deploy.s.sol`
- **Main App**: `frontend/src/App.tsx`

## Support

Having issues? Check:

1. **Foundry is installed**: `forge --version`
2. **Node.js is recent**: `node --version` (should be 18+)
3. **Anvil is running**: `curl http://localhost:8545`
4. **Contracts are built**: Check `out/` directory exists
5. **Contracts are deployed**: Check `deployments/latest.json` exists

## Conclusion

Phase F delivers a **production-ready frontend** that:
- ✅ Connects to wallets seamlessly
- ✅ Enables deposits and withdrawals
- ✅ Displays real-time vault and strategy data
- ✅ Provides excellent developer experience
- ✅ Works on local, testnet, and mainnet

**You can now fully interact with and test the Meta Index Protocol!** 🎉

---

Built with ❤️ using React, TypeScript, Wagmi, and Foundry
