// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./FAIRMiner.sol";

/**
 * @title MiningStaking
 * @dev Staking contract for FAIR Miner NFTs with emission schedule
 * SECURITY FIX: Simplified reward calculation without loops to prevent DoS
 */
contract MiningStaking is Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
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
    bool public emissionsStarted;
    
    // Staking data
    struct StakeInfo {
        uint256 tokenId;
        uint256 miningPower;
        uint256 stakedAt;
        uint256 lastClaimTime;
        uint256 accumulatedRewards;
    }
    
    // User stakes
    mapping(address => StakeInfo[]) public userStakes;
    mapping(uint256 => address) public stakedTokenOwner;
    mapping(uint256 => uint256) public stakedTokenIndex;
    
    // Total staked mining power
    uint256 public totalStakedPower;
    
    // Total rewards claimed
    uint256 public totalRewardsClaimed;
    
    // Maximum claim period to prevent excessive calculations
    uint256 public constant MAX_CLAIM_PERIOD = 365 days;
    
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
     * SECURITY FIX: Can only start after deployment, prevents insider advantage
     */
    function startEmissions() external onlyOwner {
        require(!emissionsStarted, "Already started");
        require(totalStakedPower > 0, "No miners staked yet");
        
        emissionStartTime = block.timestamp;
        emissionsStarted = true;
        
        emit EmissionStarted(emissionStartTime);
    }

    /**
     * @dev Stake a miner NFT
     */
    function stake(uint256 tokenId) external nonReentrant whenNotPaused {
        require(emissionsStarted, "Emissions not started");
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
            lastClaimTime: block.timestamp,
            accumulatedRewards: 0
        }));
        
        stakedTokenOwner[tokenId] = msg.sender;
        stakedTokenIndex[tokenId] = index;
        totalStakedPower += minerData.miningPower;
        
        emit Staked(msg.sender, tokenId, minerData.miningPower);
    }

    /**
     * @dev Stake multiple miner NFTs
     */
    function stakeMultiple(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        require(emissionsStarted, "Emissions not started");
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
                lastClaimTime: block.timestamp,
                accumulatedRewards: 0
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
        StakeInfo storage stakeInfo = userStakes[msg.sender][index];
        
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
    function claimRewards() external nonReentrant whenNotPaused {
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < userStakes[msg.sender].length; i++) {
            uint256 rewards = calculateRewards(msg.sender, i);
            totalRewards += rewards;
            userStakes[msg.sender][i].lastClaimTime = block.timestamp;
            userStakes[msg.sender][i].accumulatedRewards = 0;
        }
        
        require(totalRewards > 0, "No rewards to claim");
        require(fairToken.transfer(msg.sender, totalRewards), "Transfer failed");
        
        totalRewardsClaimed += totalRewards;
        emit RewardsClaimed(msg.sender, totalRewards);
    }

    /**
     * @dev Calculate pending rewards for a specific stake (FIXED - no loops)
     */
    function calculateRewards(address user, uint256 stakeIndex) public view returns (uint256) {
        if (!emissionsStarted) return 0;
        if (userStakes[user].length <= stakeIndex) return 0;
        if (totalStakedPower == 0) return 0;
        
        StakeInfo memory stakeInfo = userStakes[user][stakeIndex];
        
        uint256 timeElapsed = block.timestamp - stakeInfo.lastClaimTime;
        if (timeElapsed == 0) return stakeInfo.accumulatedRewards;
        
        // Cap time elapsed to prevent excessive calculations
        if (timeElapsed > MAX_CLAIM_PERIOD) {
            timeElapsed = MAX_CLAIM_PERIOD;
        }
        
        // Calculate which year(s) the staking period falls into
        uint256 startOffset = stakeInfo.lastClaimTime - emissionStartTime;
        uint256 endOffset = startOffset + timeElapsed;
        
        // Simplified calculation: use weighted average emission rate
        uint256 avgDailyEmission = getWeightedAverageEmission(startOffset, endOffset);
        
        // Calculate rewards: (avgDailyEmission * timeElapsed * miningPower) / (SECONDS_PER_DAY * totalStakedPower)
        uint256 rewards = (avgDailyEmission * timeElapsed * stakeInfo.miningPower) / 
                          (SECONDS_PER_DAY * totalStakedPower);
        
        return rewards + stakeInfo.accumulatedRewards;
    }

    /**
     * @dev Get weighted average daily emission for a time period
     */
    function getWeightedAverageEmission(uint256 startOffset, uint256 endOffset) public pure returns (uint256) {
        // Determine which years the period spans
        uint256 year1End = YEAR_IN_SECONDS;
        uint256 year2End = 2 * YEAR_IN_SECONDS;
        uint256 year3End = 3 * YEAR_IN_SECONDS;
        uint256 year4End = 4 * YEAR_IN_SECONDS;
        
        if (endOffset <= year1End) {
            return YEAR_1_DAILY;
        } else if (startOffset >= year4End) {
            return 0; // Emissions ended
        } else if (startOffset >= year3End) {
            return YEAR_4_DAILY;
        } else if (startOffset >= year2End) {
            return YEAR_3_DAILY;
        } else if (startOffset >= year1End) {
            return YEAR_2_DAILY;
        } else {
            // Period spans multiple years - calculate weighted average
            uint256 totalTime = endOffset - startOffset;
            uint256 weightedSum = 0;
            
            // Year 1 contribution
            if (startOffset < year1End) {
                uint256 year1Time = (endOffset < year1End ? endOffset : year1End) - startOffset;
                weightedSum += YEAR_1_DAILY * year1Time;
            }
            
            // Year 2 contribution
            if (startOffset < year2End && endOffset > year1End) {
                uint256 start = startOffset < year1End ? year1End : startOffset;
                uint256 end = endOffset < year2End ? endOffset : year2End;
                uint256 year2Time = end - start;
                weightedSum += YEAR_2_DAILY * year2Time;
            }
            
            // Year 3 contribution
            if (startOffset < year3End && endOffset > year2End) {
                uint256 start = startOffset < year2End ? year2End : startOffset;
                uint256 end = endOffset < year3End ? endOffset : year3End;
                uint256 year3Time = end - start;
                weightedSum += YEAR_3_DAILY * year3Time;
            }
            
            // Year 4 contribution
            if (startOffset < year4End && endOffset > year3End) {
                uint256 start = startOffset < year3End ? year3End : startOffset;
                uint256 end = endOffset < year4End ? endOffset : year4End;
                uint256 year4Time = end - start;
                weightedSum += YEAR_4_DAILY * year4Time;
            }
            
            return weightedSum / totalTime;
        }
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
        uint256 currentDailyEmission,
        bool started
    ) {
        uint256 timeElapsed = emissionsStarted ? block.timestamp - emissionStartTime : 0;
        return (
            totalStakedPower,
            totalRewardsClaimed,
            getDailyEmission(timeElapsed),
            emissionsStarted
        );
    }

    /**
     * @dev Pause staking (emergency)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause staking
     */
    function unpause() external onlyOwner {
        _unpause();
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
