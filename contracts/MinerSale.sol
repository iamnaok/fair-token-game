// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FAIRMiner.sol";

/**
 * @title MinerSale
 * @dev Handles the sale of FAIR Miner NFTs for FAIR tokens
 * Distributes revenue: 0.5% to protocol, 99.5% to revenue distributor
 */
contract MinerSale is Ownable, ReentrancyGuard {
    IERC20 public immutable fairToken;
    FAIRMiner public immutable fairMiner;
    address public revenueDistributor;
    
    // Protocol commission: 0.5% (50 basis points out of 10000)
    uint256 public constant PROTOCOL_FEE_BPS = 50;
    uint256 public constant BPS_DENOMINATOR = 10000;
    
    // Sale status
    bool public saleActive;
    
    // Total revenue collected
    uint256 public totalRevenue;
    uint256 public protocolRevenue;
    uint256 public distributorRevenue;
    
    event MinerPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        FAIRMiner.MinerTier tier,
        uint256 price
    );
    event SaleStatusUpdated(bool active);
    event RevenueDistributorUpdated(address indexed distributor);
    event ProtocolRevenueWithdrawn(address indexed to, uint256 amount);

    constructor(
        address _fairToken,
        address _fairMiner,
        address _revenueDistributor
    ) Ownable(msg.sender) {
        require(_fairToken != address(0), "Invalid token address");
        require(_fairMiner != address(0), "Invalid miner address");
        require(_revenueDistributor != address(0), "Invalid distributor address");
        
        fairToken = IERC20(_fairToken);
        fairMiner = FAIRMiner(_fairMiner);
        revenueDistributor = _revenueDistributor;
        saleActive = true;
    }

    /**
     * @dev Purchase a miner NFT with FAIR tokens
     */
    function purchaseMiner(FAIRMiner.MinerTier tier) external nonReentrant returns (uint256) {
        require(saleActive, "Sale not active");
        
        // Get tier configuration
        FAIRMiner.TierConfig memory config = fairMiner.getTierConfig(tier);
        require(config.minted < config.maxSupply, "Tier sold out");
        
        uint256 price = config.price;
        
        // Calculate fees
        uint256 protocolFee = (price * PROTOCOL_FEE_BPS) / BPS_DENOMINATOR;
        uint256 distributorAmount = price - protocolFee;
        
        // Transfer FAIR tokens from buyer
        require(
            fairToken.transferFrom(msg.sender, address(this), price),
            "Transfer failed"
        );
        
        // Update revenue tracking
        totalRevenue += price;
        protocolRevenue += protocolFee;
        distributorRevenue += distributorAmount;
        
        // Transfer to revenue distributor
        require(
            fairToken.transfer(revenueDistributor, distributorAmount),
            "Distributor transfer failed"
        );
        
        // Mint NFT to buyer
        uint256 tokenId = fairMiner.mint(msg.sender, tier);
        
        emit MinerPurchased(msg.sender, tokenId, tier, price);
        
        return tokenId;
    }

    /**
     * @dev Purchase multiple miners in one transaction
     */
    function purchaseMiners(FAIRMiner.MinerTier tier, uint256 quantity) 
        external 
        nonReentrant 
        returns (uint256[] memory) 
    {
        require(saleActive, "Sale not active");
        require(quantity > 0 && quantity <= 10, "Invalid quantity");
        
        // Get tier configuration
        FAIRMiner.TierConfig memory config = fairMiner.getTierConfig(tier);
        require(config.minted + quantity <= config.maxSupply, "Insufficient supply");
        
        uint256 totalPrice = config.price * quantity;
        
        // Calculate fees
        uint256 protocolFee = (totalPrice * PROTOCOL_FEE_BPS) / BPS_DENOMINATOR;
        uint256 distributorAmount = totalPrice - protocolFee;
        
        // Transfer FAIR tokens from buyer
        require(
            fairToken.transferFrom(msg.sender, address(this), totalPrice),
            "Transfer failed"
        );
        
        // Update revenue tracking
        totalRevenue += totalPrice;
        protocolRevenue += protocolFee;
        distributorRevenue += distributorAmount;
        
        // Transfer to revenue distributor
        require(
            fairToken.transfer(revenueDistributor, distributorAmount),
            "Distributor transfer failed"
        );
        
        // Mint NFTs to buyer
        uint256[] memory tokenIds = new uint256[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            tokenIds[i] = fairMiner.mint(msg.sender, tier);
            emit MinerPurchased(msg.sender, tokenIds[i], tier, config.price);
        }
        
        return tokenIds;
    }

    /**
     * @dev Set sale status (owner only)
     */
    function setSaleActive(bool active) external onlyOwner {
        saleActive = active;
        emit SaleStatusUpdated(active);
    }

    /**
     * @dev Update revenue distributor address (owner only)
     */
    function setRevenueDistributor(address _revenueDistributor) external onlyOwner {
        require(_revenueDistributor != address(0), "Invalid address");
        revenueDistributor = _revenueDistributor;
        emit RevenueDistributorUpdated(_revenueDistributor);
    }

    /**
     * @dev Withdraw protocol revenue (owner only)
     */
    function withdrawProtocolRevenue() external onlyOwner {
        uint256 balance = fairToken.balanceOf(address(this));
        require(balance > 0, "No revenue to withdraw");
        
        require(
            fairToken.transfer(owner(), balance),
            "Withdrawal failed"
        );
        
        emit ProtocolRevenueWithdrawn(owner(), balance);
    }

    /**
     * @dev Get current sale statistics
     */
    function getSaleStats() external view returns (
        bool active,
        uint256 total,
        uint256 protocol,
        uint256 distributor
    ) {
        return (saleActive, totalRevenue, protocolRevenue, distributorRevenue);
    }
}
