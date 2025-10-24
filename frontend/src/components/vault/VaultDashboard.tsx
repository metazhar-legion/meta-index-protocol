import { useState } from 'react'
import { useAccount } from 'wagmi'
import { useVault, useVaultBalance } from '../../hooks/useVault'
import { useStrategies } from '../../hooks/useStrategies'
import { DepositModal } from './DepositModal'
import { WithdrawModal } from './WithdrawModal'
import { StrategyList } from '../strategies/StrategyList'

export function VaultDashboard() {
  const [showDeposit, setShowDeposit] = useState(false)
  const [showWithdraw, setShowWithdraw] = useState(false)

  const { address } = useAccount()
  const { totalAssets, tvlCap } = useVault()
  const { shares, assetsValue } = useVaultBalance(address)
  const { strategies, totalValue, needsRebalancing } = useStrategies()

  const utilizationPercent = (parseFloat(totalAssets) / parseFloat(tvlCap)) * 100

  return (
    <>
      <div className="max-w-6xl mx-auto space-y-8">
        {/* Vault Stats */}
        <div className="card">
          <h2 className="text-2xl font-bold mb-6">Meta Index Vault</h2>

          <div className="grid md:grid-cols-3 gap-6 mb-6">
            <div>
              <p className="text-sm text-gray-400 mb-1">Total Value Locked</p>
              <p className="text-3xl font-bold">${parseFloat(totalAssets).toLocaleString()}</p>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">Your Position</p>
              <p className="text-3xl font-bold">${parseFloat(assetsValue).toLocaleString()}</p>
              <p className="text-sm text-gray-400">{parseFloat(shares).toFixed(4)} shares</p>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">Strategies Active</p>
              <p className="text-3xl font-bold">{strategies.length}</p>
              {needsRebalancing && (
                <p className="text-sm text-yellow-500">⚠️ Rebalancing needed</p>
              )}
            </div>
          </div>

          {/* Utilization Bar */}
          <div className="mb-6">
            <div className="flex justify-between text-sm mb-2">
              <span className="text-gray-400">Vault Utilization</span>
              <span>{utilizationPercent.toFixed(1)}%</span>
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
            <button
              onClick={() => setShowDeposit(true)}
              className="flex-1 px-6 py-3 bg-primary-600 hover:bg-primary-700 rounded-lg font-medium transition-colors"
            >
              Deposit
            </button>
            <button
              onClick={() => setShowWithdraw(true)}
              disabled={parseFloat(shares) === 0}
              className="flex-1 px-6 py-3 bg-dark-700 hover:bg-dark-600 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              Withdraw
            </button>
          </div>
        </div>

        {/* Strategies */}
        <StrategyList />
      </div>

      <DepositModal isOpen={showDeposit} onClose={() => setShowDeposit(false)} />
      <WithdrawModal isOpen={showWithdraw} onClose={() => setShowWithdraw(false)} />
    </>
  )
}
