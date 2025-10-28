// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RevenueDistributor
 * @dev Distributes revenue from NFT sales to FAIR token holders
 * Holders can claim their proportional share at any time
 */
contract RevenueDistributor is Ownable, ReentrancyGuard {
    IERC20 public immutable fairToken;
    
    // Total revenue available for distribution
    uint256 public totalRevenue;
    
    // Total revenue claimed by all users
    uint256 public totalClaimed;
    
    // Track claimed amount per user
    mapping(address => uint256) public userClaimed;
    
    // Snapshot of total supply for reward calculation
    uint256 public totalSupplySnapshot;
    
    event RevenueReceived(uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SnapshotUpdated(uint256 totalSupply);

    constructor(address _fairToken) Ownable(msg.sender) {
        require(_fairToken != address(0), "Invalid token address");
        fairToken = IERC20(_fairToken);
        totalSupplySnapshot = 1_000_000_000 * 10**18; // Initial total supply
    }

    /**
     * @dev Receive revenue from MinerSale contract
     */
    function receiveRevenue(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        totalRevenue += amount;
        emit RevenueReceived(amount);
    }

    /**
     * @dev Update total supply snapshot (owner only)
     * Should be called periodically to reflect accurate supply
     */
    function updateSnapshot() external onlyOwner {
        totalSupplySnapshot = fairToken.totalSupply();
        emit SnapshotUpdated(totalSupplySnapshot);
    }

    /**
     * @dev Calculate claimable rewards for a user
     */
    function getClaimableRewards(address user) public view returns (uint256) {
        if (totalSupplySnapshot == 0) return 0;
        
        uint256 userBalance = fairToken.balanceOf(user);
        if (userBalance == 0) return 0;
        
        // Calculate user's proportional share of total revenue
        uint256 userShare = (totalRevenue * userBalance) / totalSupplySnapshot;
        
        // Subtract what they've already claimed
        if (userShare > userClaimed[user]) {
            return userShare - userClaimed[user];
        }
        
        return 0;
    }

    /**
     * @dev Claim rewards for caller
     */
    function claimRewards() external nonReentrant {
        uint256 claimable = getClaimableRewards(msg.sender);
        require(claimable > 0, "No rewards to claim");
        
        userClaimed[msg.sender] += claimable;
        totalClaimed += claimable;
        
        require(
            fairToken.transfer(msg.sender, claimable),
            "Transfer failed"
        );
        
        emit RewardsClaimed(msg.sender, claimable);
    }

    /**
     * @dev Get distribution statistics
     */
    function getDistributionStats() external view returns (
        uint256 total,
        uint256 claimed,
        uint256 available
    ) {
        uint256 contractBalance = fairToken.balanceOf(address(this));
        return (totalRevenue, totalClaimed, contractBalance);
    }

    /**
     * @dev Emergency withdraw (owner only, for contract upgrades)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = fairToken.balanceOf(address(this));
        require(balance > 0, "No balance");
        require(
            fairToken.transfer(owner(), balance),
            "Transfer failed"
        );
    }
}
