import { useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { contracts } from '../contracts/addresses';
import VaultABI from '../contracts/abis/MetaIndexVault.json';

export function useVault() {
  // Read functions
  const { data: totalAssets } = useReadContract({
    address: contracts.vault,
    abi: VaultABI,
    functionName: 'totalAssets',
  });

  const { data: tvlCap } = useReadContract({
    address: contracts.vault,
    abi: VaultABI,
    functionName: 'tvlCap',
  });

  const { data: minDeposit } = useReadContract({
    address: contracts.vault,
    abi: VaultABI,
    functionName: 'minDeposit',
  });

  // Write functions
  const { data: hash, writeContract, isPending, isError, error } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  const deposit = async (amount: string, receiver: `0x${string}`) => {
    const parsedAmount = parseUnits(amount, 6); // USDC has 6 decimals
    return writeContract({
      address: contracts.vault,
      abi: VaultABI,
      functionName: 'deposit',
      args: [parsedAmount, receiver],
    });
  };

  const withdraw = async (amount: string, receiver: `0x${string}`, owner: `0x${string}`) => {
    const parsedAmount = parseUnits(amount, 6);
    return writeContract({
      address: contracts.vault,
      abi: VaultABI,
      functionName: 'withdraw',
      args: [parsedAmount, receiver, owner],
    });
  };

  return {
    // Read values
    totalAssets: totalAssets ? formatUnits(totalAssets as bigint, 6) : '0',
    tvlCap: tvlCap ? formatUnits(tvlCap as bigint, 6) : '0',
    minDeposit: minDeposit ? formatUnits(minDeposit as bigint, 6) : '0',

    // Write functions
    deposit,
    withdraw,

    // Transaction state
    hash,
    isPending,
    isConfirming,
    isConfirmed,
    isError,
    error,
  };
}

export function useVaultBalance(address: `0x${string}` | undefined) {
  const { data: shares } = useReadContract({
    address: contracts.vault,
    abi: VaultABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: assetsValue } = useReadContract({
    address: contracts.vault,
    abi: VaultABI,
    functionName: 'convertToAssets',
    args: shares ? [shares] : undefined,
  });

  return {
    shares: shares ? formatUnits(shares as bigint, 18) : '0',
    assetsValue: assetsValue ? formatUnits(assetsValue as bigint, 6) : '0',
  };
}
