// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FAIRMiner.sol";

/**
 * @title MiningStaking
 * @dev Staking contract for FAIR Miner NFTs with emission schedule
 * Implements a 4-year sigmoid emission curve
 */
contract MiningStaking is Ownable, ReentrancyGuard, IERC721Receiver {
    IERC20 public immutable fairToken;
    FAIRMiner public immutable fairMiner;
    
    // Emission schedule (daily emissions in FAIR tokens with 18 decimals)
    uint256 public constant YEAR_1_DAILY = 50_000 * 10**18;
    uint256 public constant YEAR_2_DAILY = 150_000 * 10**18;
    uint256 public constant YEAR_3_DAILY = 100_000 * 10**18;
    uint256 public constant YEAR_4_DAILY = 250_000 * 10**18;
    
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant YEAR_IN_SECONDS = 365 * SECONDS_PER_DAY;
    
    // Start timestamp for emissions
    uint256 public emissionStartTime;
    
    // Staking data
    struct StakeInfo {
        uint256 tokenId;
        uint256 miningPower;
        uint256 stakedAt;
        uint256 lastClaimTime;
    }
    
    // User stakes
    mapping(address => StakeInfo[]) public userStakes;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(uint256 => uint256) public stakedTokenIndex;
    
    // Total staked mining power
    uint256 public totalStakedPower;
    
    // Total rewards claimed
    uint256 public totalRewardsClaimed;
    
    event Staked(address indexed user, uint256 indexed tokenId, uint256 miningPower);
    event Unstaked(address indexed user, uint256 indexed tokenId);
    event RewardsClaimed(address indexed user, uint256 amount);
    event EmissionStarted(uint256 startTime);

    constructor(
        address _fairToken,
        address _fairMiner
    ) Ownable(msg.sender) {
        require(_fairToken != address(0), "Invalid token address");
        require(_fairMiner != address(0), "Invalid miner address");
        
        fairToken = IERC20(_fairToken);
        fairMiner = FAIRMiner(_fairMiner);
    }

    /**
     * @dev Start emission schedule (can only be called once)
     */
    function startEmissions() external onlyOwner {
        require(emissionStartTime == 0, "Already started");
        emissionStartTime = block.timestamp;
        emit EmissionStarted(emissionStartTime);
    }

    /**
     * @dev Stake a miner NFT
     */
    function stake(uint256 tokenId) external nonReentrant {
        require(emissionStartTime > 0, "Emissions not started");
        require(fairMiner.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(stakedTokenOwner[tokenId] == address(0), "Already staked");
        
        // Get miner data
        FAIRMiner.MinerData memory minerData = fairMiner.getMinerData(tokenId);
        
        // Transfer NFT to contract
        fairMiner.safeTransferFrom(msg.sender, address(this), tokenId);
        
        // Add to user stakes
        uint256 index = userStakes[msg.sender].length;
        userStakes[msg.sender].push(StakeInfo({
            tokenId: tokenId,
            miningPower: minerData.miningPower,
            stakedAt: block.timestamp,
            lastClaimTime: block.timestamp
        }));
        
        stakedTokenOwner[tokenId] = msg.sender;
        stakedTokenIndex[tokenId] = index;
        totalStakedPower += minerData.miningPower;
        
        emit Staked(msg.sender, tokenId, minerData.miningPower);
    }

    /**
     * @dev Stake multiple miner NFTs
     */
    function stakeMultiple(uint256[] calldata tokenIds) external nonReentrant {
        require(emissionStartTime > 0, "Emissions not started");
        require(tokenIds.length > 0 && tokenIds.length <= 20, "Invalid quantity");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(fairMiner.ownerOf(tokenId) == msg.sender, "Not token owner");
            require(stakedTokenOwner[tokenId] == address(0), "Already staked");
            
            // Get miner data
            FAIRMiner.MinerData memory minerData = fairMiner.getMinerData(tokenId);
            
            // Transfer NFT to contract
            fairMiner.safeTransferFrom(msg.sender, address(this), tokenId);
            
            // Add to user stakes
            uint256 index = userStakes[msg.sender].length;
            userStakes[msg.sender].push(StakeInfo({
                tokenId: tokenId,
                miningPower: minerData.miningPower,
                stakedAt: block.timestamp,
                lastClaimTime: block.timestamp
            }));
            
            stakedTokenOwner[tokenId] = msg.sender;
            stakedTokenIndex[tokenId] = index;
            totalStakedPower += minerData.miningPower;
            
            emit Staked(msg.sender, tokenId, minerData.miningPower);
        }
    }

    /**
     * @dev Unstake a miner NFT and claim rewards
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(stakedTokenOwner[tokenId] == msg.sender, "Not staked by you");
        
        uint256 index = stakedTokenIndex[tokenId];
        StakeInfo memory stakeInfo = userStakes[msg.sender][index];
        
        // Calculate and transfer pending rewards
        uint256 rewards = calculateRewards(msg.sender, index);
        if (rewards > 0) {
            require(fairToken.transfer(msg.sender, rewards), "Reward transfer failed");
            totalRewardsClaimed += rewards;
            emit RewardsClaimed(msg.sender, rewards);
        }
        
        // Update total staked power
        totalStakedPower -= stakeInfo.miningPower;
        
        // Remove from user stakes (swap with last and pop)
        uint256 lastIndex = userStakes[msg.sender].length - 1;
        if (index != lastIndex) {
            userStakes[msg.sender][index] = userStakes[msg.sender][lastIndex];
            stakedTokenIndex[userStakes[msg.sender][index].tokenId] = index;
        }
        userStakes[msg.sender].pop();
        
        delete stakedTokenOwner[tokenId];
        delete stakedTokenIndex[tokenId];
        
        // Transfer NFT back to user
        fairMiner.safeTransferFrom(address(this), msg.sender, tokenId);
        
        emit Unstaked(msg.sender, tokenId);
    }

    /**
     * @dev Claim rewards for all staked miners
     */
    function claimRewards() external nonReentrant {
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < userStakes[msg.sender].length; i++) {
            uint256 rewards = calculateRewards(msg.sender, i);
            totalRewards += rewards;
            userStakes[msg.sender][i].lastClaimTime = block.timestamp;
        }
        
        require(totalRewards > 0, "No rewards to claim");
        require(fairToken.transfer(msg.sender, totalRewards), "Transfer failed");
        
        totalRewardsClaimed += totalRewards;
        emit RewardsClaimed(msg.sender, totalRewards);
    }

    /**
     * @dev Calculate pending rewards for a specific stake
     */
    function calculateRewards(address user, uint256 stakeIndex) public view returns (uint256) {
        if (emissionStartTime == 0) return 0;
        if (userStakes[user].length <= stakeIndex) return 0;
        
        StakeInfo memory stakeInfo = userStakes[user][stakeIndex];
        
        uint256 timeElapsed = block.timestamp - stakeInfo.lastClaimTime;
        if (timeElapsed == 0 || totalStakedPower == 0) return 0;
        
        // Calculate rewards based on time elapsed
        uint256 rewards = 0;
        uint256 currentTime = stakeInfo.lastClaimTime;
        
        while (currentTime < block.timestamp) {
            uint256 timeIntoEmissions = currentTime - emissionStartTime;
            uint256 dailyEmission = getDailyEmission(timeIntoEmissions);
            
            uint256 secondsInPeriod = block.timestamp - currentTime;
            if (secondsInPeriod > SECONDS_PER_DAY) {
                secondsInPeriod = SECONDS_PER_DAY;
            }
            
            uint256 periodReward = (dailyEmission * secondsInPeriod * stakeInfo.miningPower) / 
                                   (SECONDS_PER_DAY * totalStakedPower);
            
            rewards += periodReward;
            currentTime += secondsInPeriod;
            
            if (secondsInPeriod < SECONDS_PER_DAY) break;
        }
        
        return rewards;
    }

    /**
     * @dev Get daily emission based on time elapsed since start
     */
    function getDailyEmission(uint256 timeElapsed) public pure returns (uint256) {
        if (timeElapsed < YEAR_IN_SECONDS) {
            return YEAR_1_DAILY;
        } else if (timeElapsed < 2 * YEAR_IN_SECONDS) {
            return YEAR_2_DAILY;
        } else if (timeElapsed < 3 * YEAR_IN_SECONDS) {
            return YEAR_3_DAILY;
        } else if (timeElapsed < 4 * YEAR_IN_SECONDS) {
            return YEAR_4_DAILY;
        } else {
            return 0; // Emissions end after 4 years
        }
    }

    /**
     * @dev Get all pending rewards for a user
     */
    function getPendingRewards(address user) external view returns (uint256) {
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < userStakes[user].length; i++) {
            totalRewards += calculateRewards(user, i);
        }
        
        return totalRewards;
    }

    /**
     * @dev Get user's staked tokens
     */
    function getUserStakes(address user) external view returns (StakeInfo[] memory) {
        return userStakes[user];
    }

    /**
     * @dev Get staking statistics
     */
    function getStakingStats() external view returns (
        uint256 totalPower,
        uint256 totalClaimed,
        uint256 currentDailyEmission
    ) {
        uint256 timeElapsed = emissionStartTime > 0 ? block.timestamp - emissionStartTime : 0;
        return (
            totalStakedPower,
            totalRewardsClaimed,
            getDailyEmission(timeElapsed)
        );
    }

    /**
     * @dev Required for receiving ERC721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
