import { http, createConfig } from 'wagmi';
import { mainnet, arbitrum, arbitrumSepolia, base, baseSepolia, localhost } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// Get WalletConnect project ID from environment
const projectId = import.meta.env.VITE_WALLETCONNECT_PROJECT_ID || '';

// Define the chains we support
export const chains = [localhost, arbitrumSepolia, arbitrum, baseSepolia, base, mainnet] as const;

// Create wagmi config
export const config = createConfig({
  chains,
  connectors: [
    injected(),
    walletConnect({
      projectId,
      showQrModal: true,
    }),
  ],
  transports: {
    [localhost.id]: http('http://127.0.0.1:8545'),
    [arbitrumSepolia.id]: http(),
    [arbitrum.id]: http(),
    [baseSepolia.id]: http(),
    [base.id]: http(),
    [mainnet.id]: http(),
  },
});

// Helper to get current chain
export function getActiveChain() {
  const chainId = parseInt(import.meta.env.VITE_CHAIN_ID || '31337');
  const chain = chains.find(c => c.id === chainId);
  return chain || localhost;
}
