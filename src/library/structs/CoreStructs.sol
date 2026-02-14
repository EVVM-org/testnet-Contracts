// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title CoreStructs
 * @author Mate labs
 * @notice Data structures for Core.sol (payments, governance, metadata)
 * @dev Payment structures with nonce validation. CA structures bypass nonces. Used by CoreStorage then Core.sol.
 */

library CoreStructs {
    //░▒▓█ Payment Data Structures ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Data structure for single payment operations
     * @dev Used in pay() and batchPay(). Validated via State.validateAndConsumeNonce.
     * @param from Payment sender (signer)
     * @param to_address Direct recipient
     * @param to_identity Username via NameService (priority over to_address)
     * @param token Token address (address(0) = ETH)
     * @param amount Token amount
     * @param priorityFee Fee for staker
     * @param senderExecutor Authorized senderExecutor (address(0) = any)
     * @param nonce Replay protection nonce
     * @param isAsyncExec Nonce type (false=sync, true=async)
     * @param signature EIP-191 signature
     */
    struct BatchData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        address senderExecutor;
        uint256 nonce;
        bool isAsyncExec;
        bytes signature;
    }

    /**
     * @notice Single-source multi-recipient payment data
     * @dev Used in dispersePay(). Single nonce for entire batch.
     * @param from Payment sender (signer)
     * @param toData Recipients and amounts
     * @param token Token address (address(0) = ETH)
     * @param totalAmount Total distributed (must equal sum)
     * @param priorityFee Fee for staker
     * @param senderExecutor Authorized senderExecutor (address(0) = any)
     * @param nonce Replay protection nonce
     * @param isAsyncExec Nonce type (false=sync, true=async)
     * @param signature EIP-191 signature
     */
    struct DisperseBatchData {
        address from;
        DispersePayMetadata[] toData;
        address token;
        uint256 totalAmount;
        uint256 priorityFee;
        address senderExecutor;
        uint256 nonce;
        bool isAsyncExec;
        bytes signature;
    }

    /**
     * @notice Contract-to-address payment data
     * @dev Used in caPay(). No nonce validation (contract-authorized).
     * @param from Sending contract (must be CA)
     * @param to Recipient address
     * @param token Token address (address(0) = ETH)
     * @param amount Token amount
     */
    struct CaBatchData {
        address from;
        address to;
        address token;
        uint256 amount;
    }

    /**
     * @notice Contract-based multi-recipient distribution
     * @dev Used in disperseCaPay(). No nonce validation (contract-authorized).
     * @param from Sending contract (must be CA)
     * @param toData Recipients and amounts
     * @param token Token address (address(0) = ETH)
     * @param amount Total distributed (must equal sum)
     */
    struct DisperseCaBatchData {
        address from;
        DisperseCaPayMetadata[] toData;
        address token;
        uint256 amount;
    }

    //░▒▓█ Payment Metadata Structures ██████████████████████████████████████████████████▓▒░

    /**
     * @notice Recipient metadata for user-signed disperses
     * @param amount Tokens to send
     * @param to_address Direct recipient
     * @param to_identity Username via NameService (priority)
     */
    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    /**
     * @notice Recipient metadata for contract disperses
     * @param amount Tokens to send
     * @param toAddress Recipient address
     */
    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    //░▒▓█ System Configuration Structures ██████████████████████████████████████████████▓▒░

    /**
     * @notice Core metadata configuration for EVVM instance
     * @dev EvvmID used for cross-chain replay protection. Reward halvings occur at eraTokens supply thresholds.
     * @param EvvmName Human-readable instance name
     * @param EvvmID Unique ID for signature verification
     * @param principalTokenName Principal token name
     * @param principalTokenSymbol Principal token symbol
     * @param principalTokenAddress Virtual token address
     * @param totalSupply Current PT supply
     * @param eraTokens Supply threshold for next era
     * @param reward Current reward per transaction
     */
    struct EvvmMetadata {
        string EvvmName;
        uint256 EvvmID;
        string principalTokenName;
        string principalTokenSymbol;
        address principalTokenAddress;
        uint256 totalSupply;
        uint256 eraTokens;
        uint256 reward;
    }
}
