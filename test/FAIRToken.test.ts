import { expect } from "chai";
import { ethers } from "hardhat";
import { FAIRToken } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("FAIRToken", function () {
  let fairToken: FAIRToken;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  const TOTAL_SUPPLY = ethers.parseEther("1000000000"); // 1 billion

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const FAIRToken = await ethers.getContractFactory("FAIRToken");
    fairToken = await FAIRToken.deploy();
    await fairToken.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await fairToken.name()).to.equal("FAIR Token");
      expect(await fairToken.symbol()).to.equal("FAIR");
    });

    it("Should mint total supply to owner", async function () {
      const ownerBalance = await fairToken.balanceOf(owner.address);
      expect(ownerBalance).to.equal(TOTAL_SUPPLY);
    });

    it("Should have correct total supply", async function () {
      const totalSupply = await fairToken.totalSupply();
      expect(totalSupply).to.equal(TOTAL_SUPPLY);
    });

    it("Should have 18 decimals", async function () {
      expect(await fairToken.decimals()).to.equal(18);
    });
  });

  describe("Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const transferAmount = ethers.parseEther("1000");
      
      await fairToken.transfer(addr1.address, transferAmount);
      expect(await fairToken.balanceOf(addr1.address)).to.equal(transferAmount);

      await fairToken.connect(addr1).transfer(addr2.address, transferAmount);
      expect(await fairToken.balanceOf(addr2.address)).to.equal(transferAmount);
      expect(await fairToken.balanceOf(addr1.address)).to.equal(0);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await fairToken.balanceOf(owner.address);
      
      await expect(
        fairToken.connect(addr1).transfer(owner.address, ethers.parseEther("1"))
      ).to.be.reverted;

      expect(await fairToken.balanceOf(owner.address)).to.equal(initialOwnerBalance);
    });

    it("Should emit Transfer event", async function () {
      const transferAmount = ethers.parseEther("1000");
      
      await expect(fairToken.transfer(addr1.address, transferAmount))
        .to.emit(fairToken, "Transfer")
        .withArgs(owner.address, addr1.address, transferAmount);
    });
  });

  describe("Allowances", function () {
    it("Should approve tokens for delegated transfer", async function () {
      const approveAmount = ethers.parseEther("1000");
      
      await fairToken.approve(addr1.address, approveAmount);
      expect(await fairToken.allowance(owner.address, addr1.address)).to.equal(approveAmount);
    });

    it("Should allow delegated transfer", async function () {
      const transferAmount = ethers.parseEther("1000");
      
      await fairToken.approve(addr1.address, transferAmount);
      await fairToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount);
      
      expect(await fairToken.balanceOf(addr2.address)).to.equal(transferAmount);
    });

    it("Should fail delegated transfer if allowance is insufficient", async function () {
      const approveAmount = ethers.parseEther("500");
      const transferAmount = ethers.parseEther("1000");
      
      await fairToken.approve(addr1.address, approveAmount);
      
      await expect(
        fairToken.connect(addr1).transferFrom(owner.address, addr2.address, transferAmount)
      ).to.be.reverted;
    });

    it("Should emit Approval event", async function () {
      const approveAmount = ethers.parseEther("1000");
      
      await expect(fairToken.approve(addr1.address, approveAmount))
        .to.emit(fairToken, "Approval")
        .withArgs(owner.address, addr1.address, approveAmount);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle zero transfers", async function () {
      await expect(fairToken.transfer(addr1.address, 0))
        .to.emit(fairToken, "Transfer")
        .withArgs(owner.address, addr1.address, 0);
    });

    it("Should handle max uint256 approval", async function () {
      const maxApproval = ethers.MaxUint256;
      await fairToken.approve(addr1.address, maxApproval);
      expect(await fairToken.allowance(owner.address, addr1.address)).to.equal(maxApproval);
    });

    it("Should not allow transfer to zero address", async function () {
      await expect(
        fairToken.transfer(ethers.ZeroAddress, ethers.parseEther("1000"))
      ).to.be.reverted;
    });
  });
});
