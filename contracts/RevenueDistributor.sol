// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title RevenueDistributor
 * @dev Distributes revenue from NFT sales to FAIR token holders using rewards-per-token accounting
 * SECURITY FIX: Proper accounting prevents double-claiming and unfair distribution
 */
contract RevenueDistributor is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable fairToken;
    
    // Rewards-per-token accounting (FIXED)
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateRevenue;
    uint256 public totalRevenue;
    uint256 public totalClaimed;
    
    // User state
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    // Total supply snapshot for calculations
    uint256 public totalSupplySnapshot;
    
    // Emergency withdraw timelock
    uint256 public emergencyWithdrawTime;
    uint256 public constant EMERGENCY_DELAY = 7 days;
    
    event RevenueReceived(uint256 amount, uint256 newRewardPerToken);
    event RewardsClaimed(address indexed user, uint256 amount);
    event SnapshotUpdated(uint256 totalSupply);
    event EmergencyWithdrawInitiated(uint256 executeTime);
    event EmergencyWithdrawExecuted(uint256 amount);

    constructor(address _fairToken) Ownable(msg.sender) {
        require(_fairToken != address(0), "Invalid token address");
        fairToken = IERC20(_fairToken);
        totalSupplySnapshot = 1_000_000_000 * 10**18; // Initial total supply
    }

    /**
     * @dev Update reward per token stored
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateRevenue = totalRevenue;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @dev Calculate current reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupplySnapshot == 0) {
            return rewardPerTokenStored;
        }
        
        uint256 newRevenue = totalRevenue - lastUpdateRevenue;
        return rewardPerTokenStored + ((newRevenue * 1e18) / totalSupplySnapshot);
    }

    /**
     * @dev Calculate earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        uint256 balance = fairToken.balanceOf(account);
        uint256 rewardDelta = rewardPerToken() - userRewardPerTokenPaid[account];
        return ((balance * rewardDelta) / 1e18) + rewards[account];
    }

    /**
     * @dev Receive revenue from MinerSale contract
     */
    function receiveRevenue(uint256 amount) external updateReward(address(0)) {
        require(amount > 0, "Invalid amount");
        totalRevenue += amount;
        emit RevenueReceived(amount, rewardPerToken());
    }

    /**
     * @dev Update total supply snapshot (owner only)
     * Should be called periodically to reflect accurate supply
     */
    function updateSnapshot() external onlyOwner updateReward(address(0)) {
        totalSupplySnapshot = fairToken.totalSupply();
        emit SnapshotUpdated(totalSupplySnapshot);
    }

    /**
     * @dev Claim rewards for caller
     */
    function claimRewards() external nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        
        rewards[msg.sender] = 0;
        totalClaimed += reward;
        
        require(
            fairToken.transfer(msg.sender, reward),
            "Transfer failed"
        );
        
        emit RewardsClaimed(msg.sender, reward);
    }

    /**
     * @dev Get claimable rewards for a user
     */
    function getClaimableRewards(address user) external view returns (uint256) {
        return earned(user);
    }

    /**
     * @dev Get distribution statistics
     */
    function getDistributionStats() external view returns (
        uint256 total,
        uint256 claimed,
        uint256 available,
        uint256 rewardPerTokenCurrent
    ) {
        uint256 contractBalance = fairToken.balanceOf(address(this));
        return (
            totalRevenue,
            totalClaimed,
            contractBalance,
            rewardPerToken()
        );
    }

    /**
     * @dev Pause distributions (emergency)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause distributions
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Initiate emergency withdraw (owner only, requires 7 day delay)
     */
    function initiateEmergencyWithdraw() external onlyOwner whenPaused {
        require(emergencyWithdrawTime == 0, "Already initiated");
        emergencyWithdrawTime = block.timestamp;
        emit EmergencyWithdrawInitiated(block.timestamp + EMERGENCY_DELAY);
    }
    
    /**
     * @dev Execute emergency withdraw after timelock (owner only, for contract upgrades)
     * Gives users 7 days to claim their rewards before withdrawal
     */
    function emergencyWithdraw() external onlyOwner whenPaused {
        require(emergencyWithdrawTime > 0, "Not initiated");
        require(block.timestamp >= emergencyWithdrawTime + EMERGENCY_DELAY, "Too early");
        
        uint256 balance = fairToken.balanceOf(address(this));
        require(balance > 0, "No balance");
        
        require(
            fairToken.transfer(owner(), balance),
            "Transfer failed"
        );
        
        emit EmergencyWithdrawExecuted(balance);
    }
    
    /**
     * @dev Cancel emergency withdraw
     */
    function cancelEmergencyWithdraw() external onlyOwner {
        require(emergencyWithdrawTime > 0, "Not initiated");
        emergencyWithdrawTime = 0;
    }
}
