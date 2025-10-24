import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useVault, useVaultBalance } from '../../hooks/useVault'
import toast from 'react-hot-toast'

interface WithdrawModalProps {
  isOpen: boolean
  onClose: () => void
}

export function WithdrawModal({ isOpen, onClose }: WithdrawModalProps) {
  const [amount, setAmount] = useState('')

  const { address } = useAccount()
  const { withdraw, isPending, isConfirming, isConfirmed } = useVault()
  const { assetsValue } = useVaultBalance(address)

  useEffect(() => {
    if (isConfirmed) {
      toast.success('Withdrawal successful!')
      onClose()
      setAmount('')
    }
  }, [isConfirmed, onClose])

  const handleWithdraw = async () => {
    if (!address || !amount) return

    try {
      await withdraw(amount, address, address)
    } catch (error) {
      console.error('Withdrawal error:', error)
      toast.error('Transaction failed')
    }
  }

  const isValidAmount = parseFloat(amount) > 0 && parseFloat(amount) <= parseFloat(assetsValue)

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-dark-800 border border-dark-700 rounded-xl p-6 max-w-md w-full mx-4">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold">Withdraw from Vault</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="space-y-4">
          {/* Amount Input */}
          <div>
            <label className="block text-sm font-medium mb-2">Amount (USDC)</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              disabled={isPending || isConfirming}
              className="w-full px-4 py-3 bg-dark-700 border border-dark-600 rounded-lg focus:outline-none focus:border-primary-500"
            />
            <div className="flex justify-between mt-2 text-sm text-gray-400">
              <span>Available: {parseFloat(assetsValue).toFixed(2)} USDC</span>
              <button
                onClick={() => setAmount(assetsValue)}
                className="text-primary-500 hover:text-primary-400"
              >
                Max
              </button>
            </div>
          </div>

          {/* Status Messages */}
          {(isPending || isConfirming) && (
            <div className="bg-primary-500/10 border border-primary-500/20 rounded-lg p-4">
              <p className="text-sm">⏳ Processing withdrawal...</p>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-3">
            <button
              onClick={onClose}
              disabled={isPending || isConfirming}
              className="flex-1 px-4 py-3 bg-dark-700 hover:bg-dark-600 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleWithdraw}
              disabled={!isValidAmount || isPending || isConfirming}
              className="flex-1 px-4 py-3 bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              {isPending || isConfirming ? 'Withdrawing...' : 'Withdraw'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
