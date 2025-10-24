import { useAccount } from 'wagmi'
import { ConnectWallet } from './components/wallet/ConnectWallet'
import { VaultDashboard } from './components/vault/VaultDashboard'
import { getActiveChain } from './lib/wagmi'

function App() {
  const { isConnected } = useAccount()
  const chain = getActiveChain()

  return (
    <div className="min-h-screen bg-dark-900">
      {/* Header */}
      <header className="border-b border-dark-700">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-700 rounded-lg flex items-center justify-center">
                <span className="text-xl font-bold">MI</span>
              </div>
              <div>
                <h1 className="text-xl font-bold">Meta Index Protocol</h1>
                <p className="text-xs text-gray-400">Diversified DeFi Portfolios</p>
              </div>
            </div>
            <ConnectWallet />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {/* Network Badge */}
        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-dark-800 border border-dark-700 rounded-lg">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
            <span className="text-sm font-medium">{chain.name}</span>
          </div>
        </div>

        {isConnected ? (
          <VaultDashboard />
        ) : (
          <div className="max-w-md mx-auto text-center">
            <div className="w-20 h-20 bg-primary-500/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <svg className="w-10 h-10 text-primary-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h2 className="text-3xl font-bold mb-4">Welcome to Meta Index</h2>
            <p className="text-gray-400 mb-8">
              Connect your wallet to start investing in diversified onchain portfolios
            </p>
            <ConnectWallet />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-dark-700 mt-16">
        <div className="container mx-auto px-4 py-6">
          <p className="text-center text-sm text-gray-400">
            © 2025 Meta Index Protocol. Built with ❤️ on Ethereum
          </p>
        </div>
      </footer>
    </div>
  )
}

export default App
