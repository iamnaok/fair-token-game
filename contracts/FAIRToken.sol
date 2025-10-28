// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FAIRToken
 * @dev ERC-20 token with fixed supply of 1 billion tokens
 * Used as the primary currency in the FAIR mining game ecosystem
 */
contract FAIRToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    
    // Distribution allocations
    uint256 public constant LIQUIDITY_ALLOCATION = 700_000_000 * 10**18; // 70%
    uint256 public constant MINING_REWARDS_ALLOCATION = 200_000_000 * 10**18; // 20%
    uint256 public constant DEVELOPMENT_ALLOCATION = 50_000_000 * 10**18; // 5%
    uint256 public constant MARKETING_ALLOCATION = 30_000_000 * 10**18; // 3%
    uint256 public constant TREASURY_ALLOCATION = 20_000_000 * 10**18; // 2%

    bool public initialized;

    event TokensDistributed(
        address liquidityAddress,
        address miningRewardsAddress,
        address developmentAddress,
        address marketingAddress,
        address treasuryAddress
    );

    constructor() ERC20("FAIR Token", "FAIR") Ownable(msg.sender) {
        // Mint total supply to contract for controlled distribution
        _mint(address(this), TOTAL_SUPPLY);
    }

    /**
     * @dev Initialize token distribution (can only be called once)
     * @param liquidityAddress Address to receive liquidity allocation
     * @param miningRewardsAddress Address to receive mining rewards allocation
     * @param developmentAddress Address to receive development allocation
     * @param marketingAddress Address to receive marketing allocation
     * @param treasuryAddress Address to receive treasury allocation
     */
    function initializeDistribution(
        address liquidityAddress,
        address miningRewardsAddress,
        address developmentAddress,
        address marketingAddress,
        address treasuryAddress
    ) external onlyOwner {
        require(!initialized, "Already initialized");
        require(liquidityAddress != address(0), "Invalid liquidity address");
        require(miningRewardsAddress != address(0), "Invalid mining rewards address");
        require(developmentAddress != address(0), "Invalid development address");
        require(marketingAddress != address(0), "Invalid marketing address");
        require(treasuryAddress != address(0), "Invalid treasury address");

        initialized = true;

        _transfer(address(this), liquidityAddress, LIQUIDITY_ALLOCATION);
        _transfer(address(this), miningRewardsAddress, MINING_REWARDS_ALLOCATION);
        _transfer(address(this), developmentAddress, DEVELOPMENT_ALLOCATION);
        _transfer(address(this), marketingAddress, MARKETING_ALLOCATION);
        _transfer(address(this), treasuryAddress, TREASURY_ALLOCATION);

        emit TokensDistributed(
            liquidityAddress,
            miningRewardsAddress,
            developmentAddress,
            marketingAddress,
            treasuryAddress
        );
    }
}
