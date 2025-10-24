import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { contracts } from '../contracts/addresses';
import ERC20ABI from '../contracts/abis/MockERC20.json';

export function useUSDC(userAddress: `0x${string}` | undefined) {
  // Read balance
  const { data: balance, refetch: refetchBalance } = useReadContract({
    address: contracts.usdc,
    abi: ERC20ABI,
    functionName: 'balanceOf',
    args: userAddress ? [userAddress] : undefined,
  });

  // Read allowance for vault
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: contracts.usdc,
    abi: ERC20ABI,
    functionName: 'allowance',
    args: userAddress ? [userAddress, contracts.vault] : undefined,
  });

  // Approve
  const { data: hash, writeContract, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const approve = async (amount: string) => {
    const parsedAmount = parseUnits(amount, 6);
    return writeContract({
      address: contracts.usdc,
      abi: ERC20ABI,
      functionName: 'approve',
      args: [contracts.vault, parsedAmount],
    });
  };

  const needsApproval = (amount: string): boolean => {
    if (!allowance) return true;
    const parsedAmount = parseUnits(amount, 6);
    return (allowance as bigint) < parsedAmount;
  };

  return {
    balance: balance ? formatUnits(balance as bigint, 6) : '0',
    allowance: allowance ? formatUnits(allowance as bigint, 6) : '0',
    approve,
    needsApproval,
    isPending,
    isConfirming,
    isConfirmed,
    refetchBalance,
    refetchAllowance,
  };
}
