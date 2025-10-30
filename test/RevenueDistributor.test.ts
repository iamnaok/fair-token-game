import { expect } from "chai";
import { ethers } from "hardhat";
import { FAIRToken, RevenueDistributor } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("RevenueDistributor", function () {
  let fairToken: FAIRToken;
  let revenueDistributor: RevenueDistributor;
  let owner: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy FAIRToken
    const FAIRToken = await ethers.getContractFactory("FAIRToken");
    fairToken = await FAIRToken.deploy();
    await fairToken.waitForDeployment();

    // Deploy RevenueDistributor
    const RevenueDistributor = await ethers.getContractFactory("RevenueDistributor");
    revenueDistributor = await RevenueDistributor.deploy(await fairToken.getAddress());
    await revenueDistributor.waitForDeployment();

    // Distribute tokens to users for testing
    await fairToken.transfer(user1.address, ethers.parseEther("100000"));
    await fairToken.transfer(user2.address, ethers.parseEther("50000"));
  });

  describe("Deployment", function () {
    it("Should set the correct token address", async function () {
      expect(await revenueDistributor.fairToken()).to.equal(await fairToken.getAddress());
    });

    it("Should set initial snapshot to 1B tokens", async function () {
      expect(await revenueDistributor.totalSupplySnapshot()).to.equal(ethers.parseEther("1000000000"));
    });

    it("Should start with zero revenue", async function () {
      expect(await revenueDistributor.totalRevenue()).to.equal(0);
      expect(await revenueDistributor.totalClaimed()).to.equal(0);
    });
  });

  describe("Revenue Distribution", function () {
    it("Should receive and track revenue", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      // Transfer revenue to distributor
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      
      // Call receiveRevenue
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      expect(await revenueDistributor.totalRevenue()).to.equal(revenueAmount);
    });

    it("Should calculate rewards correctly for single user", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      // User1 has 100,000 tokens out of 1B total
      // Should get 100,000/1,000,000,000 * 10,000 = 1 FAIR
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      const claimable = await revenueDistributor.getClaimableRewards(user1.address);
      expect(claimable).to.be.closeTo(ethers.parseEther("1"), ethers.parseEther("0.01"));
    });

    it("Should allow users to claim rewards", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      const initialBalance = await fairToken.balanceOf(user1.address);
      await revenueDistributor.connect(user1).claimRewards();
      const finalBalance = await fairToken.balanceOf(user1.address);
      
      expect(finalBalance).to.be.gt(initialBalance);
    });

    it("Should prevent double claiming", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      await revenueDistributor.connect(user1).claimRewards();
      
      // Try to claim again
      await expect(
        revenueDistributor.connect(user1).claimRewards()
      ).to.be.revertedWith("No rewards to claim");
    });

    it("Should distribute rewards proportionally", async function () {
      const revenueAmount = ethers.parseEther("15000");
      
      // User1: 100,000 tokens (66.67%)
      // User2: 50,000 tokens (33.33%)
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      const claimable1 = await revenueDistributor.getClaimableRewards(user1.address);
      const claimable2 = await revenueDistributor.getClaimableRewards(user2.address);
      
      // User1 should get ~2x what user2 gets
      expect(claimable1).to.be.closeTo(claimable2 * 2n, ethers.parseEther("0.1"));
    });
  });

  describe("Emergency Functions", function () {
    it("Should allow owner to pause", async function () {
      await revenueDistributor.pause();
      expect(await revenueDistributor.paused()).to.be.true;
    });

    it("Should prevent claims when paused", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      await revenueDistributor.pause();
      
      await expect(
        revenueDistributor.connect(user1).claimRewards()
      ).to.be.revertedWithCustomError(revenueDistributor, "EnforcedPause");
    });

    it("Should require 7 day delay for emergency withdraw", async function () {
      const revenueAmount = ethers.parseEther("10000");
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      
      await revenueDistributor.pause();
      await revenueDistributor.initiateEmergencyWithdraw();
      
      // Try to withdraw immediately
      await expect(
        revenueDistributor.emergencyWithdraw()
      ).to.be.revertedWith("Too early");
      
      // Fast forward 7 days
      await time.increase(7 * 24 * 60 * 60);
      
      // Now should work
      await expect(revenueDistributor.emergencyWithdraw()).to.not.be.reverted;
    });

    it("Should allow canceling emergency withdraw", async function () {
      await revenueDistributor.pause();
      await revenueDistributor.initiateEmergencyWithdraw();
      await revenueDistributor.cancelEmergencyWithdraw();
      
      await time.increase(7 * 24 * 60 * 60);
      
      await expect(
        revenueDistributor.emergencyWithdraw()
      ).to.be.revertedWith("Not initiated");
    });
  });

  describe("Snapshot Updates", function () {
    it("Should allow owner to update snapshot", async function () {
      const newSupply = ethers.parseEther("900000000");
      
      // Burn some tokens to change supply
      const burnAmount = ethers.parseEther("100000000");
      await fairToken.transfer(ethers.ZeroAddress, burnAmount);
      
      await revenueDistributor.updateSnapshot();
      
      expect(await revenueDistributor.totalSupplySnapshot()).to.be.lt(ethers.parseEther("1000000000"));
    });
  });

  describe("Edge Cases", function () {
    it("Should handle zero revenue", async function () {
      await expect(
        revenueDistributor.receiveRevenue(0)
      ).to.be.revertedWith("Invalid amount");
    });

    it("Should handle user with zero balance", async function () {
      const revenueAmount = ethers.parseEther("10000");
      
      await fairToken.transfer(await revenueDistributor.getAddress(), revenueAmount);
      await revenueDistributor.receiveRevenue(revenueAmount);
      
      const claimable = await revenueDistributor.getClaimableRewards(owner.address);
      // Owner transferred most tokens away, should have significant rewards
      expect(claimable).to.be.gt(0);
    });
  });
});
