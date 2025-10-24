import { useReadContract } from 'wagmi';
import { formatUnits } from 'viem';
import { contracts } from '../contracts/addresses';
import StrategyManagerABI from '../contracts/abis/StrategyManager.json';

export interface Strategy {
  address: `0x${string}`;
  allocation: number; // in basis points (10000 = 100%)
}

export function useStrategies() {
  // Get all strategy addresses
  const { data: strategyAddresses } = useReadContract({
    address: contracts.strategyManager,
    abi: StrategyManagerABI,
    functionName: 'getStrategies',
  });

  // Get total value
  const { data: totalValue } = useReadContract({
    address: contracts.strategyManager,
    abi: StrategyManagerABI,
    functionName: 'totalValue',
  });

  // Check if rebalancing is needed
  const { data: needsRebalancing } = useReadContract({
    address: contracts.strategyManager,
    abi: StrategyManagerABI,
    functionName: 'needsRebalancing',
  });

  return {
    strategies: (strategyAddresses as `0x${string}`[]) || [],
    totalValue: totalValue ? formatUnits(totalValue as bigint, 6) : '0',
    needsRebalancing: needsRebalancing as boolean || false,
  };
}

export function useStrategyAllocation(strategyAddress: `0x${string}` | undefined) {
  const { data: allocation } = useReadContract({
    address: contracts.strategyManager,
    abi: StrategyManagerABI,
    functionName: 'getAllocation',
    args: strategyAddress ? [strategyAddress] : undefined,
  });

  return {
    allocation: allocation ? Number(allocation) : 0, // Returns basis points
    percentage: allocation ? Number(allocation) / 100 : 0, // Convert to percentage
  };
}
