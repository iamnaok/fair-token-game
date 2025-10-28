// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FAIRMiner
 * @dev ERC-721 NFT representing mining equipment with different tiers and mining power
 */
contract FAIRMiner is ERC721, ERC721Enumerable, Ownable {
    // Miner tiers
    enum MinerTier { BASIC, ADVANCED, ELITE }
    
    // Tier configurations
    struct TierConfig {
        uint256 price;          // Price in FAIR tokens
        uint256 miningPower;    // Mining power multiplier (scaled by 100, e.g., 100 = 1.0x)
        uint256 maxSupply;      // Maximum number of miners for this tier
        uint256 minted;         // Number of miners minted for this tier
    }
    
    // Miner metadata
    struct MinerData {
        MinerTier tier;
        uint256 miningPower;
        uint256 mintTimestamp;
    }
    
    // Tier configurations
    mapping(MinerTier => TierConfig) public tierConfigs;
    
    // Token ID to miner data
    mapping(uint256 => MinerData) public miners;
    
    // Next token ID to mint
    uint256 private _nextTokenId = 1;
    
    // Base URI for token metadata
    string private _baseTokenURI;
    
    // Authorized minter (MinerSale contract)
    address public authorizedMinter;
    
    event MinerMinted(address indexed to, uint256 indexed tokenId, MinerTier tier, uint256 miningPower);
    event AuthorizedMinterUpdated(address indexed minter);
    event BaseURIUpdated(string baseURI);

    constructor() ERC721("FAIR Miner", "FMINER") Ownable(msg.sender) {
        // Initialize tier configurations
        // Basic: 10,000 FAIR, 1.0x power, 2,500 max supply
        tierConfigs[MinerTier.BASIC] = TierConfig({
            price: 10_000 * 10**18,
            miningPower: 100, // 1.0x
            maxSupply: 2500,
            minted: 0
        });
        
        // Advanced: 30,000 FAIR, 2.5x power, 1,500 max supply
        tierConfigs[MinerTier.ADVANCED] = TierConfig({
            price: 30_000 * 10**18,
            miningPower: 250, // 2.5x
            maxSupply: 1500,
            minted: 0
        });
        
        // Elite: 75,000 FAIR, 5.0x power, 1,000 max supply
        tierConfigs[MinerTier.ELITE] = TierConfig({
            price: 75_000 * 10**18,
            miningPower: 500, // 5.0x
            maxSupply: 1000,
            minted: 0
        });
    }

    /**
     * @dev Set authorized minter address (MinerSale contract)
     */
    function setAuthorizedMinter(address minter) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinter = minter;
        emit AuthorizedMinterUpdated(minter);
    }

    /**
     * @dev Set base URI for token metadata
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    /**
     * @dev Mint a new miner NFT (only callable by authorized minter)
     */
    function mint(address to, MinerTier tier) external returns (uint256) {
        require(msg.sender == authorizedMinter, "Not authorized");
        require(to != address(0), "Invalid recipient");
        
        TierConfig storage config = tierConfigs[tier];
        require(config.minted < config.maxSupply, "Tier sold out");
        
        uint256 tokenId = _nextTokenId++;
        config.minted++;
        
        miners[tokenId] = MinerData({
            tier: tier,
            miningPower: config.miningPower,
            mintTimestamp: block.timestamp
        });
        
        _safeMint(to, tokenId);
        
        emit MinerMinted(to, tokenId, tier, config.miningPower);
        
        return tokenId;
    }

    /**
     * @dev Get miner data for a token ID
     */
    function getMinerData(uint256 tokenId) external view returns (MinerData memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return miners[tokenId];
    }

    /**
     * @dev Get tier configuration
     */
    function getTierConfig(MinerTier tier) external view returns (TierConfig memory) {
        return tierConfigs[tier];
    }

    /**
     * @dev Get available supply for a tier
     */
    function getAvailableSupply(MinerTier tier) external view returns (uint256) {
        TierConfig memory config = tierConfigs[tier];
        return config.maxSupply - config.minted;
    }

    /**
     * @dev Get all token IDs owned by an address
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        
        return tokenIds;
    }

    /**
     * @dev Override base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Override required by Solidity for multiple inheritance
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Override required by Solidity for multiple inheritance
     */
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    /**
     * @dev Override required by Solidity for multiple inheritance
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
