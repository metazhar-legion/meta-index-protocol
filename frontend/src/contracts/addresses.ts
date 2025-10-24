export const contracts = {
  vault: import.meta.env.VITE_VAULT_ADDRESS as `0x${string}`,
  strategyManager: import.meta.env.VITE_STRATEGY_MANAGER_ADDRESS as `0x${string}`,
  usdc: import.meta.env.VITE_USDC_ADDRESS as `0x${string}`,
  priceOracle: import.meta.env.VITE_PRICE_ORACLE_ADDRESS as `0x${string}`,
  swapRouter: import.meta.env.VITE_SWAP_ROUTER_ADDRESS as `0x${string}`,
  strategy1: import.meta.env.VITE_STRATEGY1_ADDRESS as `0x${string}`,
  strategy2: import.meta.env.VITE_STRATEGY2_ADDRESS as `0x${string}`,
} as const;

export function getContractAddress(name: keyof typeof contracts): `0x${string}` {
  const address = contracts[name];
  if (!address) {
    throw new Error(`Contract address not found for: ${name}`);
  }
  return address;
}
