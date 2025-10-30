import { ethers } from "hardhat";

async function main() {
  console.log("Starting deployment to Base network...\n");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

  // 1. Deploy FAIRToken
  console.log("1. Deploying FAIRToken...");
  const FAIRToken = await ethers.getContractFactory("FAIRToken");
  const fairToken = await FAIRToken.deploy();
  await fairToken.waitForDeployment();
  const fairTokenAddress = await fairToken.getAddress();
  console.log("✅ FAIRToken deployed to:", fairTokenAddress);
  console.log("   Total Supply:", ethers.formatEther(await fairToken.totalSupply()), "FAIR\n");

  // 2. Deploy FAIRMiner NFT
  console.log("2. Deploying FAIRMiner NFT...");
  const FAIRMiner = await ethers.getContractFactory("FAIRMiner");
  const fairMiner = await FAIRMiner.deploy();
  await fairMiner.waitForDeployment();
  const fairMinerAddress = await fairMiner.getAddress();
  console.log("✅ FAIRMiner deployed to:", fairMinerAddress, "\n");

  // 3. Deploy RevenueDistributor
  console.log("3. Deploying RevenueDistributor...");
  const RevenueDistributor = await ethers.getContractFactory("RevenueDistributor");
  const revenueDistributor = await RevenueDistributor.deploy(fairTokenAddress);
  await revenueDistributor.waitForDeployment();
  const revenueDistributorAddress = await revenueDistributor.getAddress();
  console.log("✅ RevenueDistributor deployed to:", revenueDistributorAddress, "\n");

  // 4. Deploy MinerSale
  console.log("4. Deploying MinerSale...");
  const MinerSale = await ethers.getContractFactory("MinerSale");
  const minerSale = await MinerSale.deploy(
    fairTokenAddress,
    fairMinerAddress,
    revenueDistributorAddress
  );
  await minerSale.waitForDeployment();
  const minerSaleAddress = await minerSale.getAddress();
  console.log("✅ MinerSale deployed to:", minerSaleAddress, "\n");

  // 5. Deploy MiningStaking
  console.log("5. Deploying MiningStaking...");
  const MiningStaking = await ethers.getContractFactory("MiningStaking");
  const miningStaking = await MiningStaking.deploy(
    fairTokenAddress,
    fairMinerAddress
  );
  await miningStaking.waitForDeployment();
  const miningStakingAddress = await miningStaking.getAddress();
  console.log("✅ MiningStaking deployed to:", miningStakingAddress, "\n");

  // 6. Initialize FAIRToken (transfer tokens to appropriate contracts)
  console.log("6. Initializing FAIRToken distribution...");
  
  // Transfer 20% (200M) to MiningStaking for rewards
  const miningRewards = ethers.parseEther("200000000");
  console.log("   Transferring", ethers.formatEther(miningRewards), "FAIR to MiningStaking...");
  await fairToken.transfer(miningStakingAddress, miningRewards);
  
  // Transfer 5% (50M) to deployer for team/development (with vesting recommended)
  const teamAllocation = ethers.parseEther("50000000");
  console.log("   Transferring", ethers.formatEther(teamAllocation), "FAIR to deployer for team...");
  // Already in deployer wallet, no transfer needed
  
  console.log("✅ Token distribution complete\n");

  // 7. Set up permissions
  console.log("7. Setting up permissions...");
  
  // Set MinerSale as minter for FAIRMiner
  console.log("   Setting MinerSale as minter...");
  await fairMiner.setMinter(minerSaleAddress);
  
  console.log("✅ Permissions configured\n");

  // 8. Activate sale
  console.log("8. Activating NFT sale...");
  await minerSale.setSaleActive(true);
  console.log("✅ Sale activated\n");

  // Print deployment summary
  console.log("=".repeat(60));
  console.log("DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Deployer:", deployer.address);
  console.log("\nContract Addresses:");
  console.log("-------------------");
  console.log("FAIRToken:           ", fairTokenAddress);
  console.log("FAIRMiner:           ", fairMinerAddress);
  console.log("RevenueDistributor:  ", revenueDistributorAddress);
  console.log("MinerSale:           ", minerSaleAddress);
  console.log("MiningStaking:       ", miningStakingAddress);
  console.log("\nToken Distribution:");
  console.log("-------------------");
  console.log("Total Supply:        ", "1,000,000,000 FAIR");
  console.log("Mining Rewards:      ", "200,000,000 FAIR (20%)");
  console.log("Team/Development:    ", "50,000,000 FAIR (5%)");
  console.log("Fair Launch (Aerodrome): ", "700,000,000 FAIR (70%)");
  console.log("Protocol Reserve:    ", "50,000,000 FAIR (5%)");
  console.log("\nNFT Miner Tiers:");
  console.log("-------------------");
  console.log("Basic (1x power):    ", "10,000 FAIR - 2,500 supply");
  console.log("Advanced (2.5x):     ", "30,000 FAIR - 1,500 supply");
  console.log("Elite (5x):          ", "75,000 FAIR - 1,000 supply");
  console.log("\nNext Steps:");
  console.log("-------------------");
  console.log("1. Verify contracts on Basescan");
  console.log("2. Create liquidity pool on Aerodrome");
  console.log("3. Start emission schedule (after miners are staked)");
  console.log("4. Update frontend with contract addresses");
  console.log("5. Test all flows on testnet before mainnet");
  console.log("=".repeat(60));

  // Save addresses to file
  const fs = require('fs');
  const addresses = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    deployer: deployer.address,
    contracts: {
      fairToken: fairTokenAddress,
      fairMiner: fairMinerAddress,
      revenueDistributor: revenueDistributorAddress,
      minerSale: minerSaleAddress,
      miningStaking: miningStakingAddress
    },
    deployedAt: new Date().toISOString()
  };

  fs.writeFileSync(
    'deployment-addresses.json',
    JSON.stringify(addresses, null, 2)
  );
  console.log("\n✅ Deployment addresses saved to deployment-addresses.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
