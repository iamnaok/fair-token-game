// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PrivacyPool
 * @dev Simple privacy pool for FAIR tokens with configurable fees
 * Users deposit tokens publicly and can withdraw to any address privately
 * Protocol earns fees on deposits (1%) and withdrawals (0.5%)
 */
contract PrivacyPool is Ownable, ReentrancyGuard {
    IERC20 public immutable fairToken;
    
    // Fee configuration (in basis points, 100 = 1%)
    uint256 public depositFeeBps = 100;  // 1%
    uint256 public withdrawalFeeBps = 50; // 0.5%
    uint256 public constant BPS_DENOMINATOR = 10000;
    
    // Minimum deposit amount
    uint256 public minDepositAmount = 100 * 10**18; // 100 FAIR
    
    // Commitment structure for privacy
    struct Commitment {
        bytes32 commitmentHash;
        uint256 amount;
        uint256 timestamp;
        bool spent;
    }
    
    // Mapping of commitment hashes to commitment data
    mapping(bytes32 => Commitment) public commitments;
    
    // Track if a nullifier has been used (prevents double-spending)
    mapping(bytes32 => bool) public nullifierUsed;
    
    // Total deposits and withdrawals
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public totalFeesCollected;
    
    // Pool balance tracking
    uint256 public poolBalance;
    
    event Deposited(
        address indexed depositor,
        bytes32 indexed commitmentHash,
        uint256 amount,
        uint256 fee
    );
    
    event Withdrawn(
        address indexed recipient,
        bytes32 indexed nullifierHash,
        uint256 amount,
        uint256 fee
    );
    
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event DepositFeeUpdated(uint256 newFeeBps);
    event WithdrawalFeeUpdated(uint256 newFeeBps);
    event MinDepositUpdated(uint256 newAmount);

    constructor(address _fairToken) Ownable(msg.sender) {
        require(_fairToken != address(0), "Invalid token address");
        fairToken = IERC20(_fairToken);
    }

    /**
     * @dev Deposit FAIR tokens into the privacy pool
     * @param amount Amount of FAIR tokens to deposit
     * @param commitmentHash Hash of (secret, nullifier) for later withdrawal
     */
    function deposit(uint256 amount, bytes32 commitmentHash) external nonReentrant {
        require(amount >= minDepositAmount, "Amount below minimum");
        require(commitmentHash != bytes32(0), "Invalid commitment");
        require(commitments[commitmentHash].commitmentHash == bytes32(0), "Commitment exists");
        
        // Calculate fee
        uint256 fee = (amount * depositFeeBps) / BPS_DENOMINATOR;
        uint256 netAmount = amount - fee;
        
        // Transfer tokens from user
        require(
            fairToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        // Store commitment
        commitments[commitmentHash] = Commitment({
            commitmentHash: commitmentHash,
            amount: netAmount,
            timestamp: block.timestamp,
            spent: false
        });
        
        // Update statistics
        totalDeposits += netAmount;
        totalFeesCollected += fee;
        poolBalance += netAmount;
        
        emit Deposited(msg.sender, commitmentHash, netAmount, fee);
    }

    /**
     * @dev Withdraw tokens to any address using commitment secret and nullifier
     * @param recipient Address to receive the tokens
     * @param amount Amount to withdraw
     * @param nullifierHash Hash of nullifier (prevents double-spending)
     * @param secret Secret used in commitment
     * 
     * Note: In production, this should use zero-knowledge proofs
     * This simplified version requires revealing the secret
     */
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 nullifierHash,
        bytes32 secret
    ) external nonReentrant {
        require(recipient != address(0), "Invalid recipient");
        require(!nullifierUsed[nullifierHash], "Nullifier already used");
        
        // Reconstruct commitment hash
        bytes32 commitmentHash = keccak256(abi.encodePacked(secret, nullifierHash));
        
        Commitment storage commitment = commitments[commitmentHash];
        require(commitment.commitmentHash != bytes32(0), "Commitment not found");
        require(!commitment.spent, "Already withdrawn");
        require(commitment.amount >= amount, "Insufficient commitment amount");
        
        // Calculate withdrawal fee
        uint256 fee = (amount * withdrawalFeeBps) / BPS_DENOMINATOR;
        uint256 netAmount = amount - fee;
        
        // Mark commitment as spent
        commitment.spent = true;
        nullifierUsed[nullifierHash] = true;
        
        // Update statistics
        totalWithdrawals += netAmount;
        totalFeesCollected += fee;
        poolBalance -= amount;
        
        // Transfer tokens to recipient
        require(
            fairToken.transfer(recipient, netAmount),
            "Transfer failed"
        );
        
        emit Withdrawn(recipient, nullifierHash, netAmount, fee);
    }

    /**
     * @dev Batch deposit for multiple commitments
     */
    function batchDeposit(
        uint256[] calldata amounts,
        bytes32[] calldata commitmentHashes
    ) external nonReentrant {
        require(amounts.length == commitmentHashes.length, "Length mismatch");
        require(amounts.length > 0 && amounts.length <= 10, "Invalid batch size");
        
        uint256 totalAmount = 0;
        uint256 totalFees = 0;
        
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minDepositAmount, "Amount below minimum");
            require(commitmentHashes[i] != bytes32(0), "Invalid commitment");
            require(
                commitments[commitmentHashes[i]].commitmentHash == bytes32(0),
                "Commitment exists"
            );
            
            uint256 fee = (amounts[i] * depositFeeBps) / BPS_DENOMINATOR;
            uint256 netAmount = amounts[i] - fee;
            
            commitments[commitmentHashes[i]] = Commitment({
                commitmentHash: commitmentHashes[i],
                amount: netAmount,
                timestamp: block.timestamp,
                spent: false
            });
            
            totalAmount += netAmount;
            totalFees += fee;
            
            emit Deposited(msg.sender, commitmentHashes[i], netAmount, fee);
        }
        
        // Transfer total amount once
        uint256 totalTransfer = totalAmount + totalFees;
        require(
            fairToken.transferFrom(msg.sender, address(this), totalTransfer),
            "Transfer failed"
        );
        
        totalDeposits += totalAmount;
        totalFeesCollected += totalFees;
        poolBalance += totalAmount;
    }

    /**
     * @dev Set deposit fee (owner only)
     */
    function setDepositFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 500, "Fee too high"); // Max 5%
        depositFeeBps = newFeeBps;
        emit DepositFeeUpdated(newFeeBps);
    }

    /**
     * @dev Set withdrawal fee (owner only)
     */
    function setWithdrawalFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 500, "Fee too high"); // Max 5%
        withdrawalFeeBps = newFeeBps;
        emit WithdrawalFeeUpdated(newFeeBps);
    }

    /**
     * @dev Set minimum deposit amount (owner only)
     */
    function setMinDepositAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Invalid amount");
        minDepositAmount = newAmount;
        emit MinDepositUpdated(newAmount);
    }

    /**
     * @dev Withdraw collected fees (owner only)
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 feeBalance = fairToken.balanceOf(address(this)) - poolBalance;
        require(feeBalance > 0, "No fees to withdraw");
        
        require(
            fairToken.transfer(owner(), feeBalance),
            "Transfer failed"
        );
        
        emit FeesWithdrawn(owner(), feeBalance);
    }

    /**
     * @dev Get pool statistics
     */
    function getPoolStats() external view returns (
        uint256 deposits,
        uint256 withdrawals,
        uint256 fees,
        uint256 balance,
        uint256 depositFee,
        uint256 withdrawalFee
    ) {
        return (
            totalDeposits,
            totalWithdrawals,
            totalFeesCollected,
            poolBalance,
            depositFeeBps,
            withdrawalFeeBps
        );
    }

    /**
     * @dev Check if commitment exists and is unspent
     */
    function isCommitmentValid(bytes32 commitmentHash) external view returns (bool) {
        Commitment memory commitment = commitments[commitmentHash];
        return commitment.commitmentHash != bytes32(0) && !commitment.spent;
    }

    /**
     * @dev Get commitment details
     */
    function getCommitment(bytes32 commitmentHash) external view returns (
        uint256 amount,
        uint256 timestamp,
        bool spent
    ) {
        Commitment memory commitment = commitments[commitmentHash];
        return (commitment.amount, commitment.timestamp, commitment.spent);
    }
}
