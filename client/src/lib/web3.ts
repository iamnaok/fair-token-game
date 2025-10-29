import { http, createConfig } from 'wagmi';
import { base, baseSepolia } from 'wagmi/chains';
import { injected, coinbaseWallet } from 'wagmi/connectors';

export const config = createConfig({
  chains: [base, baseSepolia],
  connectors: [
    injected(),
    coinbaseWallet({
      appName: '$FAIR - Provably Fair Mining Game',
    }),
  ],
  transports: {
    [base.id]: http(),
    [baseSepolia.id]: http(),
  },
});

// Contract addresses (update after deployment)
export const CONTRACTS = {
  fairToken: '0x0000000000000000000000000000000000000000',
  fairMiner: '0x0000000000000000000000000000000000000000',
  minerSale: '0x0000000000000000000000000000000000000000',
  miningStaking: '0x0000000000000000000000000000000000000000',
  revenueDistributor: '0x0000000000000000000000000000000000000000',
  privacyPool: '0x0000000000000000000000000000000000000000',
} as const;

// Miner tier enum
export enum MinerTier {
  BASIC = 0,
  ADVANCED = 1,
  ELITE = 2,
}

// Miner tier data
export const MINER_TIERS = {
  [MinerTier.BASIC]: {
    name: 'Basic Miner',
    price: '10000',
    power: '1.0x',
    maxSupply: 2500,
    description: 'Entry-level miner for new players',
  },
  [MinerTier.ADVANCED]: {
    name: 'Advanced Miner',
    price: '30000',
    power: '2.5x',
    maxSupply: 1500,
    description: 'Best value - optimal efficiency',
  },
  [MinerTier.ELITE]: {
    name: 'Elite Miner',
    price: '75000',
    power: '5.0x',
    maxSupply: 1000,
    description: 'Premium miner for maximum output',
  },
} as const;
