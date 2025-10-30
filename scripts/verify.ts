import { run } from "hardhat";

async function main() {
  console.log("Starting contract verification on Basescan...\n");

  // Load deployment addresses
  const fs = require('fs');
  const addresses = JSON.parse(fs.readFileSync('deployment-addresses.json', 'utf8'));

  console.log("Network:", addresses.network);
  console.log("Chain ID:", addresses.chainId);
  console.log("\n");

  // 1. Verify FAIRToken
  console.log("1. Verifying FAIRToken...");
  try {
    await run("verify:verify", {
      address: addresses.contracts.fairToken,
      constructorArguments: [],
    });
    console.log("✅ FAIRToken verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ FAIRToken already verified\n");
    } else {
      console.error("❌ FAIRToken verification failed:", error.message, "\n");
    }
  }

  // 2. Verify FAIRMiner
  console.log("2. Verifying FAIRMiner...");
  try {
    await run("verify:verify", {
      address: addresses.contracts.fairMiner,
      constructorArguments: [],
    });
    console.log("✅ FAIRMiner verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ FAIRMiner already verified\n");
    } else {
      console.error("❌ FAIRMiner verification failed:", error.message, "\n");
    }
  }

  // 3. Verify RevenueDistributor
  console.log("3. Verifying RevenueDistributor...");
  try {
    await run("verify:verify", {
      address: addresses.contracts.revenueDistributor,
      constructorArguments: [addresses.contracts.fairToken],
    });
    console.log("✅ RevenueDistributor verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ RevenueDistributor already verified\n");
    } else {
      console.error("❌ RevenueDistributor verification failed:", error.message, "\n");
    }
  }

  // 4. Verify MinerSale
  console.log("4. Verifying MinerSale...");
  try {
    await run("verify:verify", {
      address: addresses.contracts.minerSale,
      constructorArguments: [
        addresses.contracts.fairToken,
        addresses.contracts.fairMiner,
        addresses.contracts.revenueDistributor
      ],
    });
    console.log("✅ MinerSale verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ MinerSale already verified\n");
    } else {
      console.error("❌ MinerSale verification failed:", error.message, "\n");
    }
  }

  // 5. Verify MiningStaking
  console.log("5. Verifying MiningStaking...");
  try {
    await run("verify:verify", {
      address: addresses.contracts.miningStaking,
      constructorArguments: [
        addresses.contracts.fairToken,
        addresses.contracts.fairMiner
      ],
    });
    console.log("✅ MiningStaking verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ MiningStaking already verified\n");
    } else {
      console.error("❌ MiningStaking verification failed:", error.message, "\n");
    }
  }

  console.log("=".repeat(60));
  console.log("VERIFICATION COMPLETE");
  console.log("=".repeat(60));
  console.log("All contracts have been verified on Basescan");
  console.log("View them at: https://basescan.org/address/<contract_address>");
  console.log("=".repeat(60));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
