# $FAIR - Provably Fair Mining Game

A decentralized crypto gaming platform on Base blockchain featuring NFT miners, staking mechanics, and privacy-preserving transactions.

## 🎮 Overview

$FAIR is a provably fair virtual Bitcoin mining game where players stake NFT miners to earn $FAIR tokens. Built with transparency and community-first economics, 99.5% of NFT sales revenue is distributed back to token holders.

## ✨ Features

- **NFT Miners**: 3 tiers of miners with different mining power (1x, 2.5x, 5x)
- **Staking System**: Stake miners to earn $FAIR tokens with 4-year emission schedule
- **Revenue Sharing**: 99.5% of NFT sales distributed to token holders
- **Privacy Pool**: Optional privacy for transactions with 1% deposit / 0.5% withdrawal fees
- **Fair Launch**: 70% of supply launched on Aerodrome DEX
- **Low Fees**: Built on Base L2 for minimal gas costs

## 📊 Tokenomics

### Token Distribution
- **Total Supply**: 1,000,000,000 $FAIR (fixed)
- **Aerodrome Liquidity**: 70% (700M tokens)
- **Mining Rewards**: 20% (200M tokens over 4 years)
- **Development**: 5% (2-year vesting)
- **Marketing**: 3% (1-year vesting)
- **Community Treasury**: 2%

### Emission Schedule (Sigmoid Curve)
- **Year 1**: 50,000 $FAIR/day
- **Year 2**: 150,000 $FAIR/day (peak rewards)
- **Year 3**: 100,000 $FAIR/day
- **Year 4**: 250,000 $FAIR/day (final distribution)

## 🔨 NFT Miner Tiers

| Tier | Price | Mining Power | Max Supply |
|------|-------|--------------|------------|
| Basic | 10,000 $FAIR | 1.0x | 2,500 |
| Advanced | 30,000 $FAIR | 2.5x | 1,500 |
| Elite | 75,000 $FAIR | 5.0x | 1,000 |

## 🏗️ Smart Contracts

### Core Contracts
- **FAIRToken.sol**: ERC-20 token with 1B fixed supply
- **FAIRMiner.sol**: ERC-721 NFT with 3 tiers and mining power
- **MinerSale.sol**: NFT purchasing with automatic revenue distribution
- **MiningStaking.sol**: Staking logic with emission schedule
- **RevenueDistributor.sol**: Claimable revenue sharing for holders
- **PrivacyPool.sol**: Optional privacy with deposit/withdrawal fees

### Revenue Streams
1. **0.5%** from all NFT miner sales → Protocol owner
2. **99.5%** from NFT sales → Token holders (claimable)
3. **1%** from privacy pool deposits → Protocol owner
4. **0.5%** from privacy pool withdrawals → Protocol owner

## 🚀 Tech Stack

### Frontend
- React 19 + TypeScript
- Vite 7
- Tailwind CSS 4
- shadcn/ui components
- wagmi + viem for Web3
- Wouter for routing

### Smart Contracts
- Solidity 0.8.20
- Hardhat development environment
- OpenZeppelin contracts
- Base blockchain (Ethereum L2)

## 📦 Installation

```bash
# Install dependencies
pnpm install

# Compile smart contracts
pnpm exec hardhat compile

# Run development server
cd client && pnpm dev
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Deployment
PRIVATE_KEY=your_private_key_here
BASE_RPC_URL=https://mainnet.base.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=your_basescan_api_key

# Frontend (update after deployment)
VITE_FAIR_TOKEN_ADDRESS=0x...
VITE_FAIR_MINER_ADDRESS=0x...
VITE_MINER_SALE_ADDRESS=0x...
VITE_MINING_STAKING_ADDRESS=0x...
VITE_REVENUE_DISTRIBUTOR_ADDRESS=0x...
VITE_PRIVACY_POOL_ADDRESS=0x...
```

## 📝 Deployment Guide

### 1. Deploy Smart Contracts

```bash
# Deploy to Base Sepolia (testnet)
pnpm exec hardhat run scripts/deploy.ts --network baseSepolia

# Deploy to Base Mainnet
pnpm exec hardhat run scripts/deploy.ts --network base
```

### 2. Update Contract Addresses

After deployment, update the contract addresses in:
- `client/src/lib/web3.ts`
- `.env` file

### 3. Verify Contracts

```bash
pnpm exec hardhat verify --network base <CONTRACT_ADDRESS>
```

### 4. Start Emissions

```bash
# Call startEmissions() on MiningStaking contract
# This can only be done once by the owner
```

### 5. Deploy Frontend

The frontend can be deployed to:
- Vercel
- Netlify
- Cloudflare Pages
- Any static hosting service

```bash
cd client
pnpm build
# Upload 'dist' folder to your hosting provider
```

## 🎯 Usage

### For Players

1. **Connect Wallet**: Use MetaMask or Coinbase Wallet
2. **Buy $FAIR**: Purchase on Aerodrome DEX
3. **Buy Miners**: Purchase NFT miners with $FAIR tokens
4. **Stake Miners**: Stake your miners to start earning
5. **Claim Rewards**: Claim your mining rewards anytime
6. **Claim Revenue**: Token holders can claim their share of NFT sales

### For Protocol Owner

1. **Withdraw Protocol Revenue**: Claim 0.5% from NFT sales
2. **Withdraw Privacy Fees**: Claim fees from privacy pool
3. **Adjust Privacy Fees**: Modify deposit/withdrawal fees (max 5%)
4. **Update Revenue Distributor**: Change distribution contract if needed

## 🔒 Security Features

- **Reentrancy Protection**: All contracts use OpenZeppelin's ReentrancyGuard
- **Access Control**: Owner-only functions for critical operations
- **Fixed Supply**: Token supply is capped at 1B, no minting possible
- **Transparent Calculations**: All mining rewards calculated on-chain
- **Auditable**: Open source code for community review

## 🛣️ Roadmap

- [x] Smart contract development
- [x] Frontend development
- [x] Privacy pool integration
- [ ] Smart contract audit
- [ ] Testnet deployment
- [ ] Community testing
- [ ] Mainnet deployment
- [ ] Aerodrome fair launch
- [ ] CEX listings
- [ ] Mobile app
- [ ] Advanced analytics dashboard

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📞 Contact

- Twitter: [@FAIRToken](https://twitter.com/FAIRToken)
- Discord: [Join our community](https://discord.gg/fair)
- Telegram: [t.me/FAIRToken](https://t.me/FAIRToken)

## ⚠️ Disclaimer

This is experimental software. Use at your own risk. Always DYOR (Do Your Own Research) before investing in any cryptocurrency project.

---

Built with ❤️ on Base blockchain
