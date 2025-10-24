import { useStrategies } from '../../hooks/useStrategies'
import { useStrategyAllocation } from '../../hooks/useStrategies'

function StrategyCard({ address }: { address: `0x${string}` }) {
  const { allocation, percentage } = useStrategyAllocation(address)

  return (
    <div className="bg-dark-700 border border-dark-600 rounded-lg p-4">
      <div className="flex items-start justify-between mb-3">
        <div>
          <h4 className="font-medium mb-1">Strategy</h4>
          <p className="text-xs text-gray-400 font-mono">
            {address.slice(0, 10)}...{address.slice(-8)}
          </p>
        </div>
        <div className="text-right">
          <div className="text-2xl font-bold">{percentage.toFixed(1)}%</div>
          <div className="text-xs text-gray-400">Allocation</div>
        </div>
      </div>

      <div className="w-full bg-dark-600 rounded-full h-2">
        <div
          className="bg-primary-500 h-2 rounded-full"
          style={{ width: `${percentage}%` }}
        />
      </div>
    </div>
  )
}

export function StrategyList() {
  const { strategies, totalValue, needsRebalancing } = useStrategies()

  return (
    <div className="card">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-xl font-bold">Active Strategies</h3>
          <p className="text-sm text-gray-400">
            Total: ${parseFloat(totalValue).toLocaleString()}
          </p>
        </div>
        {needsRebalancing && (
          <div className="px-3 py-1 bg-yellow-500/10 border border-yellow-500/20 rounded-lg text-yellow-500 text-sm font-medium">
            ⚠️ Rebalancing needed
          </div>
        )}
      </div>

      {strategies.length === 0 ? (
        <div className="text-center py-12 text-gray-400">
          <svg
            className="w-16 h-16 mx-auto mb-4 opacity-50"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <p>No strategies deployed yet</p>
        </div>
      ) : (
        <div className="grid md:grid-cols-2 gap-4">
          {strategies.map((strategy) => (
            <StrategyCard key={strategy} address={strategy} />
          ))}
        </div>
      )}
    </div>
  )
}
