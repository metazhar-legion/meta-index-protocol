import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import { useVault } from '../../hooks/useVault'
import { useUSDC } from '../../hooks/useUSDC'
import toast from 'react-hot-toast'

interface DepositModalProps {
  isOpen: boolean
  onClose: () => void
}

export function DepositModal({ isOpen, onClose }: DepositModalProps) {
  const [amount, setAmount] = useState('')
  const [step, setStep] = useState<'input' | 'approve' | 'deposit'>('input')

  const { address } = useAccount()
  const { deposit, isPending, isConfirming, isConfirmed } = useVault()
  const {
    balance,
    needsApproval,
    approve,
    isPending: isApproving,
    isConfirming: isApprovingConfirm,
    isConfirmed: isApproved,
    refetchAllowance,
  } = useUSDC(address)

  useEffect(() => {
    if (isApproved && step === 'approve') {
      setStep('deposit')
      refetchAllowance()
    }
  }, [isApproved, step, refetchAllowance])

  useEffect(() => {
    if (isConfirmed) {
      toast.success('Deposit successful!')
      onClose()
      setAmount('')
      setStep('input')
    }
  }, [isConfirmed, onClose])

  const handleDeposit = async () => {
    if (!address || !amount) return

    try {
      if (needsApproval(amount)) {
        setStep('approve')
        await approve(amount)
      } else {
        setStep('deposit')
        await deposit(amount, address)
      }
    } catch (error) {
      console.error('Deposit error:', error)
      toast.error('Transaction failed')
      setStep('input')
    }
  }

  const isValidAmount = parseFloat(amount) > 0 && parseFloat(amount) <= parseFloat(balance)

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-dark-800 border border-dark-700 rounded-xl p-6 max-w-md w-full mx-4">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold">Deposit to Vault</h3>
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
              disabled={step !== 'input'}
              className="w-full px-4 py-3 bg-dark-700 border border-dark-600 rounded-lg focus:outline-none focus:border-primary-500"
            />
            <div className="flex justify-between mt-2 text-sm text-gray-400">
              <span>Balance: {parseFloat(balance).toFixed(2)} USDC</span>
              <button
                onClick={() => setAmount(balance)}
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
                {isApproving || isApprovingConfirm ? '⏳ Approving USDC...' : ''}
                {isApproved ? '✅ USDC Approved! Proceeding to deposit...' : ''}
              </p>
            </div>
          )}

          {step === 'deposit' && (
            <div className="bg-primary-500/10 border border-primary-500/20 rounded-lg p-4">
              <p className="text-sm">
                {isPending || isConfirming ? '⏳ Depositing to vault...' : ''}
                {isConfirmed ? '✅ Deposit successful!' : ''}
              </p>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-3">
            <button
              onClick={onClose}
              disabled={isPending || isConfirming || isApproving || isApprovingConfirm}
              className="flex-1 px-4 py-3 bg-dark-700 hover:bg-dark-600 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleDeposit}
              disabled={!isValidAmount || isPending || isConfirming || isApproving || isApprovingConfirm}
              className="flex-1 px-4 py-3 bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg font-medium transition-colors"
            >
              {step === 'input' && 'Deposit'}
              {step === 'approve' && (isApproving || isApprovingConfirm ? 'Approving...' : 'Approve')}
              {step === 'deposit' && (isPending || isConfirming ? 'Depositing...' : 'Deposit')}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
