### Script F.4.3: Deployment Helper

**File:** `scripts/deploy-with-frontend.sh`
````bash
#!/bin/bash
# Deploy contracts and update frontend automatically

set -e

NETWORK=${1:-arbitrum-sepolia}

echo "🚀 Deploying to $NETWORK..."

# Deploy contracts
cd "$(dirname "$0")/.."
forge script script/Deploy.s.sol \
  --rpc-url "$NETWORK" \
  --broadcast \
  --verify

# Wait for deployment to complete
echo "⏳ Waiting for deployment to complete..."
sleep 5

# Generate ABIs
echo "📝 Generating ABIs..."
cd frontend
npm run generate-abis

# Update addresses
echo "📝 Updating contract addresses..."
npm run update-addresses

echo "✅ Deployment complete and frontend updated!"
echo "Run 'cd frontend && npm run dev' to start the frontend"
````

---

## Phase F.5: UI Components (Week 3)

### Component F.5.1: Connect Wallet

**File:** `frontend/src/components/wallet/ConnectWallet.tsx`
````typescript
import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { Button } from '../shared/Button'

export function ConnectWallet() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()
  
  if (isConnected && address) {
    return (
      <div className="flex items-center gap-4">
        <span className="text-sm text-gray-400">
          {address.slice(0, 6)}...{address.slice(-4)}
        </span>
        <Button onClick={() => disconnect()} variant="secondary">
          Disconnect
        </Button>
      </div>
    )
  }
  
  return (
    <div className="flex gap-2">
      {connectors.map((connector) => (
        <Button
          key={connector.id}
          onClick={() => connect({ connector })}
          disabled={!connector.ready}
        >
          Connect {connector.name}
        </Button>
      ))}
    </div>
  )
}
````

### Component F.5.2: Deposit Modal

**File:** `frontend/src/components/vault/DepositModal.tsx`
````typescript
import { useState } from 'react'
import { useAccount } from 'wagmi'
import { Modal } from '../shared/Modal'
import { Button } from '../shared/Button'
import { Input } from '../shared/Input'
import { useVault } from '../../hooks/useVault'
import { useBalance } from '../../hooks/useBalance'
import { useAllowance } from '../../hooks/useAllowance'

interface DepositModalProps {
  isOpen: boolean
  onClose: () => void
}

export function DepositModal({ isOpen, onClose }: DepositModalProps) {
  const [amount, setAmount] = useState('')
  const [step, setStep] = useState<'input' | 'approve' | 'deposit'>('input')
  
  const { address } = useAccount()
  const { usdcBalance } = useBalance()
  const { deposit, isConfirming, isConfirmed } = useVault()
  const { needsApproval, approve, isConfirming: isApproving, isConfirmed: isApproved } = useAllowance()
  
  const handleDeposit = async () => {
    if (!address) return
    
    try {
      if (needsApproval(amount)) {
        setStep('approve')
        await approve(amount)
      }
      
      setStep('deposit')
      await deposit(amount, address)
      
      // Wait for confirmation
      if (isConfirmed) {
        onClose()
        setAmount('')
        setStep('input')
      }
    } catch (error) {
      console.error('Deposit error:', error)
      setStep('input')
    }
  }
  
  const isValidAmount = parseFloat(amount) > 0 && parseFloat(amount) <= parseFloat(usdcBalance)
  
  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Deposit to Vault">
      <div className="space-y-4">
        {/* Amount Input */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Amount (USDC)
          </label>
          <Input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            disabled={step !== 'input'}
          />
          <div className="flex justify-between mt-1 text-sm text-gray-400">
            <span>Balance: {parseFloat(usdcBalance).toFixed(2)} USDC</span>
            <button
              onClick={() => setAmount(usdcBalance)}
              className="text-primary-500 hover:text-primary-400"
            >
              Max
            </button>
          </div>
        </div>
        
        {/* Status Messages */}
        {step === 'approve' && (
          <div className="bg-primary-500/10 border border-primary-500/20 rounded-lg p-4">
            <p className="text-sm">
              {isApproving && '⏳ Approving USDC...'}
              {isApproved && '✅ USDC Approved! Proceeding to deposit...'}
            </p>
          </div>
        )}
        
        {step === 'deposit' && (
          <div className="bg-primary-500/10 border border-primary-500/20 rounded-lg p-4">
            <p className="text-sm">
              {isConfirming && '⏳ Depositing to vault...'}
              {isConfirmed && '✅ Deposit successful!'}
            </p>
          </div>
        )}
        
        {/* Action Buttons */}
        <div className="flex gap-3">
          <Button
            onClick={onClose}
            variant="secondary"
            className="flex-1"
            disabled={isConfirming || isApproving}
          >
            Cancel
          </Button>
          <Button
            onClick={handleDeposit}
            className="flex-1"
            disabled={!isValidAmount || isConfirming || isApproving}
          >
            {step === 'input' && 'Deposit'}
            {step === 'approve' && (isApproving ? 'Approving...' : 'Approve')}
            {step === 'deposit' && (isConfirming ? 'Depositing...' : 'Deposit')}
          </Button>
        </div>
      </div>
    </Modal>
  )
}
````

### Component F.5.3: Vault Card

**File:** `frontend/src/components/vault/VaultCard.tsx`
````typescript
import { useState } from 'react'
import { Card } from '../shared/Card'
import { Button } from '../shared/Button'
import { DepositModal } from './DepositModal'
import { WithdrawModal } from './WithdrawModal'
import { useVault } from '../../hooks/useVault'
import { useBalance } from '../../hooks/useBalance'

export function VaultCard() {
  const [showDeposit, setShowDeposit] = useState(false)
  const [showWithdraw, setShowWithdraw] = useState(false)
  
  const { totalAssets, tvlCap } = useVault()
  const { vaultValue, sharesBalance } = useBalance()
  
  const utilizationPercent = (parseFloat(totalAssets) / parseFloat(tvlCap)) * 100
  
  return (
    <>
      <Card>
        <div className="space-y-6">
          {/* Header */}
          <div>
            <h3 className="text-2xl font-bold">Balanced OnChain Portfolio</h3>
            <p className="text-gray-400 mt-1">
              Diversified exposure to Crypto, DeFi, and RWAs
            </p>
          </div>
          
          {/* Stats */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-400">Total Value Locked</p>
              <p className="text-2xl font-bold mt-1">
                ${parseFloat(totalAssets).toLocaleString()}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-400">Your Position</p>
              <p className="text-2xl font-bold mt-1">
                ${parseFloat(vaultValue).toLocaleString()}
              </p>
            </div>
          </div>
          
          {/* Utilization Bar */}
          <div>
            <div className="flex justify-between text-sm mb-2">
              <span className="text-gray-400">Vault Utilization</span>
              <span className="text-white">{utilizationPercent.toFixed(1)}%</span>
            </div>
            <div className="w-full bg-dark-700 rounded-full h-2">
              <div
                className="bg-primary-500 h-2 rounded-full transition-all"
                style={{ width: `${Math.min(utilizationPercent, 100)}%` }}
              />
            </div>
          </div>
          
          {/* Actions */}
          <div className="flex gap-3">
            <Button
              onClick={() => setShowDeposit(true)}
              className="flex-1"
            >
              Deposit
            </Button>
            <Button
              onClick={() => setShowWithdraw(true)}
              variant="secondary"
              className="flex-1"
              disabled={parseFloat(sharesBalance) === 0}
            >
              Withdraw
            </Button>
          </div>
        </div>
      </Card>
      
      <DepositModal isOpen={showDeposit} onClose={() => setShowDeposit(false)} />
      <WithdrawModal isOpen={showWithdraw} onClose={() => setShowWithdraw(false)} />
    </>
  )
}
````

### Component F.5.4: Shared Components

**File:** `frontend/src/components/shared/Button.tsx`
````typescript
import { ButtonHTMLAttributes, forwardRef } from 'react'
import { clsx } from 'clsx'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary'
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={clsx(
          'px-4 py-2 rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed',
          variant === 'primary' && 'bg-primary-600 hover:bg-primary-700 text-white',
          variant === 'secondary' && 'bg-dark-700 hover:bg-dark-600 text-white',
          className
        )}
        {...props}
      >
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'
````

**File:** `frontend/src/components/shared/Modal.tsx`
````typescript
import { Fragment } from 'react'
import { Dialog, Transition } from '@headlessui/react'
import { XMarkIcon } from '@heroicons/react/24/outline'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: React.ReactNode
}

export function Modal({ isOpen, onClose, title, children }: ModalProps) {
  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/50" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-dark-800 border border-dark-700 p-6 text-left align-middle shadow-xl transition-all">
                <div className="flex items-center justify-between mb-4">
                  <Dialog.Title className="text-lg font-medium text-white">
                    {title}
                  </Dialog.Title>
                  <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
                {children}
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  )
}
````

---

## Phase F.6: Main App Setup (Week 3-4)

### Module F.6.1: App Entry Point

**File:** `frontend/src/main.tsx`
````typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { config } from './lib/wagmi'
import App from './App'
import './styles/globals.css'

const queryClient = new QueryClient()

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>,
)
````

### Module F.6.2: Main App Component

**File:** `frontend/src/App.tsx`
````typescript
import { useAccount } from 'wagmi'
import { Layout } from './components/layout/Layout'
import { VaultCard } from './components/vault/VaultCard'
import { ConnectWallet } from './components/wallet/ConnectWallet'
import { getActiveChain } from './lib/chains'

function App() {
  const { isConnected } = useAccount()
  const chain = getActiveChain()
  
  return (
    <Layout>
      {/* Network Badge */}
      <div className="mb-8">
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-dark-800 border border-dark-700 rounded-lg">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          <span className="text-sm font-medium">{chain.name}</span>
        </div>
      </div>
      
      {/* Main Content */}
      {isConnected ? (
        <div className="max-w-2xl mx-auto">
          <VaultCard />
        </div>
      ) : (
        <div className="max-w-md mx-auto text-center">
          <h1 className="text-4xl font-bold mb-4">
            Welcome to Meta Index
          </h1>
          <p className="text-gray-400 mb-8">
            Connect your wallet to start investing in diversified onchain portfolios
          </p>
          <ConnectWallet />
        </div>
      )}
    </Layout>
  )
}

export default App
````

### Module F.6.3: Layout Component

**File:** `frontend/src/components/layout/Layout.tsx`
````typescript
import { ConnectWallet } from '../wallet/ConnectWallet'

interface LayoutProps {
  children: React.ReactNode
}

export function Layout({ children }: LayoutProps) {
  return (
    <div className="min-h-screen bg-dark-900">
      {/* Header */}
      <header className="border-b border-dark-700">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-primary-500 rounded-lg" />
              <span className="text-xl font-bold">Meta Index</span>
            </div>
            <ConnectWallet />
          </div>
        </div>
      </header>
      
      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {children}
      </main>
      
      {/* Footer */}
      <footer className="border-t border-dark-700 mt-16">
        <div className="container mx-auto px-4 py-6">
          <p className="text-center text-sm text-gray-400">
            © 2025 Meta Index Protocol. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  )
}
````

---

## Development Workflow

### Setup and Run

**File:** `frontend/README.md`
````markdown
# Meta Index Frontend

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy environment file:
```bash
cp .env.example .env.local
```

3. Generate ABIs from contracts:
```bash
npm run generate-abis
```

4. Update contract addresses:
```bash
npm run update-addresses
```

## Development

### Run on different networks:

**Local Anvil:**
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy contracts
cd .. && make deploy-local

# Terminal 3: Start frontend
npm run dev:anvil
```

**Arbitrum Sepolia:**
```bash
npm run dev:arbitrum-sepolia
```

**Arbitrum Mainnet:**
```bash
VITE_CHAIN=arbitrum npm run dev
```

**Base Sepolia:**
```bash
npm run dev:base-sepolia
```

**Base Mainnet:**
```bash
VITE_CHAIN=base npm run dev
```

## Build for Production
```bash
npm run build
npm run preview
```

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run generate-abis` - Generate ABIs from contracts
- `npm run update-addresses` - Update contract addresses from deployments
````

---

## Testing Checklist

**File:** `frontend/TESTING_CHECKLIST.md`
````markdown
# Frontend Testing Checklist

## Phase F Testing

### F.1: Setup
- [ ] Project initializes without errors
- [ ] All dependencies install correctly
- [ ] TailwindCSS styles load properly
- [ ] Development server starts

### F.2: Web3 Integration
- [ ] Wagmi config loads correct chains
- [ ] Contract addresses load from environment
- [ ] ABIs import without errors
- [ ] Can switch between networks

### F.3: Wallet Connection
- [ ] MetaMask connects successfully
- [ ] WalletConnect works
- [ ] Wallet info displays correctly
- [ ] Disconnect works
- [ ] Wrong network detection works

### F.4: Vault Interactions
- [ ] Can read vault total assets
- [ ] Can read user balance
- [ ] Can read user shares
- [ ] Deposit modal opens
- [ ] Approve USDC transaction works
- [ ] Deposit transaction works
- [ ] Withdraw modal opens
- [ ] Withdraw transaction works

### F.5: Multi-Chain Support
- [ ] Works on local Anvil
- [ ] Works on Arbitrum Sepolia
- [ ] Works on Arbitrum Mainnet
- [ ] Works on Base Sepolia
- [ ] Works on Base Mainnet
- [ ] Contract addresses correct for each chain
- [ ] Network switching works

### F.6: UI/UX
- [ ] All components render correctly
- [ ] Loading states show properly
- [ ] Error messages display
- [ ] Success confirmations work
- [ ] Responsive on mobile
- [ ] Dark mode looks good

### F.7: Scripts
- [ ] generate-abis.ts runs successfully
- [ ] update-addresses.ts updates .env.local
- [ ] deploy-with-frontend.sh works end-to-end
````

---

## Next: Phase 2 Specifications

Would you like me to continue with:

1. **Phase 2A: Real Strategy Implementation** - Crypto, DeFi, RWA, and Yield strategies
2. **Phase 2B: Advanced Rebalancing** - DEX aggregation, gas optimization, threshold rebalancing
3. **Phase 2C: Multi-Index Support** - DeFi Innovation Index, Real Yield Index
4. **Phase 2D: Governance Implementation** - DAO voting, proposal system, governance token
5. **Phase 2E: Security & Audit Prep** - Security hardening, audit preparation, bug bounty

Let me know which phase you'd like next, or if you need any clarifications on the frontend spec!# Meta Index Protocol - Frontend Development Spec
## Phase F: React UI Implementation

**Version:** 1.0  
**Stack:** React 18 + TypeScript + Viem + Wagmi + TailwindCSS  
**Timeline:** 3-4 weeks

---

## Overview

Build a production-ready frontend that allows users to interact with Meta Index vaults across multiple networks (Local Anvil, Arbitrum Sepolia/Mainnet, Base Sepolia/Mainnet).

**Phase F Goal:** Functional UI for depositing, withdrawing, and monitoring vault performance with multi-chain support.

---

## Project Structure
