// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title EvvmStructs
 * @author Mate labs
 * @notice Library of data structures used exclusively by the Evvm.sol core contract
 * @dev This contract defines the type system for the Evvm.sol contract,
 *      providing structured data types for payment operations, governance proposals,
 *      and system configuration. These structures are not shared with external services.
 *
 * Structure Categories:
 * - Payment Structures: BatchData, DisperseBatchData, CaBatchData for transaction processing
 * - Governance Structures: AddressTypeProposal, UintTypeProposal for time-delayed changes
 * - Metadata Structures: EvvmMetadata for system-wide configuration
 *
 * @custom:inheritance This contract is inherited by EvvmStorage, which is then inherited by Evvm.sol
 * @custom:scope Exclusive to the Evvm.sol contract and its storage layout
 * @custom:version 1.0.0
 */

abstract contract EvvmStructs {
    //░▒▓█ Payment Data Structures ██████████████████████████████████████████████████████▓▒░

    /**
     * @notice Data structure for single payment operations
     * @dev Used in pay() and batchPay() functions for individual transfers
     *
     * @param from Address of the payment sender (signer of the transaction)
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity to resolve via NameService (takes priority)
     * @param token Address of the token to transfer (address(0) for ETH)
     * @param amount Amount of tokens to transfer to the recipient
     * @param priorityFee Additional fee paid to staker for transaction processing
     * @param nonce Transaction nonce for replay protection
     * @param priorityFlag False for sync nonce (sequential), true for async nonce (flexible)
     * @param executor Address authorized to execute this transaction (address(0) = any)
     * @param signature EIP-191 signature authorizing this payment
     */
    struct BatchData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        uint256 nonce;
        bool priorityFlag;
        address executor;
        bytes signature;
    }

    /**
     * @notice Data structure for single-source multi-recipient payment distributions
     * @dev Used in dispersePay() for efficient batch distributions from one sender
     *
     * @param from Address of the payment sender (signer of the transaction)
     * @param toData Array of recipient metadata with individual amounts and addresses
     * @param token Address of the token to distribute (address(0) for ETH)
     * @param totalAmount Total amount being distributed (must equal sum of toData amounts)
     * @param priorityFee Fee paid to staker for processing the distribution
     * @param nonce Transaction nonce for replay protection
     * @param priorityFlag False for sync nonce, true for async nonce
     * @param executor Address authorized to execute this distribution (address(0) = any)
     * @param signature EIP-191 signature authorizing this distribution
     */
    struct DisperseBatchData {
        address from;
        DispersePayMetadata[] toData;
        address token;
        uint256 totalAmount;
        uint256 priorityFee;
        uint256 nonce;
        bool priorityFlag;
        address executor;
        bytes signature;
    }

    /**
     * @notice Data structure for contract-to-address payments without signatures
     * @dev Used in caPay() for authorized contract distributions
     *
     * @param from Address of the sending contract (must be a contract, not EOA)
     * @param to Address of the token recipient
     * @param token Address of the token to transfer (address(0) for ETH)
     * @param amount Amount of tokens to transfer
     */
    struct CaBatchData {
        address from;
        address to;
        address token;
        uint256 amount;
    }

    /**
     * @notice Data structure for contract-based multi-recipient distributions
     * @dev Used in disperseCaPay() for batch distributions from contracts
     *
     * @param from Address of the sending contract (must be a contract, not EOA)
     * @param toData Array of recipient metadata with individual amounts and addresses
     * @param token Address of the token to distribute (address(0) for ETH)
     * @param amount Total amount being distributed (must equal sum of toData amounts)
     */
    struct DisperseCaBatchData{
        address from;
        DisperseCaPayMetadata[] toData;
        address token;
        uint256 amount;
    }

    //░▒▓█ Payment Metadata Structures ██████████████████████████████████████████████████▓▒░

    /**
     * @notice Recipient metadata for user-signed disperse payments
     * @dev Used within DisperseBatchData to specify individual recipients
     *
     * @param amount Amount of tokens to send to this recipient
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity to resolve via NameService (takes priority)
     */
    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    /**
     * @notice Recipient metadata for contract-based disperse payments
     * @dev Used within DisperseCaBatchData to specify individual recipients
     *      Simpler than DispersePayMetadata as identity resolution is not supported
     *
     * @param amount Amount of tokens to send to this recipient
     * @param toAddress Direct recipient address
     */
    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    //░▒▓█ System Configuration Structures ██████████████████████████████████████████████▓▒░

    /**
     * @notice Core metadata configuration for the EVVM instance
     * @dev Contains all system-wide parameters for the EVVM ecosystem
     *
     * Economic Model:
     * - reward: Base Principal Tokens distributed per successful transaction
     * - eraTokens: Supply threshold that triggers the next reward halving
     * - totalSupply: Current total supply tracking for era calculations
     *
     * @param EvvmName Human-readable name of this EVVM instance
     * @param EvvmID Unique identifier used in signature verification to prevent cross-chain replay
     * @param principalTokenName Full name of the principal token (customizable)
     * @param principalTokenSymbol Symbol of the principal token (customizable)
     * @param principalTokenAddress Virtual address representing the Principal Token in balance mappings
     * @param totalSupply Current total supply of principal tokens in circulation
     * @param eraTokens Token supply threshold for next reward halving era
     * @param reward Current reward amount in Principal Tokens per successful transaction
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

    //░▒▓█ Governance Proposal Structures ███████████████████████████████████████████████▓▒░

    /**
     * @notice Time-delayed proposal structure for address-type governance changes
     * @dev Used for admin changes (1-day delay) and can be extended for other address proposals
     *
     * Governance Flow:
     * 1. Admin proposes new address -> sets proposal and timeToAccept
     * 2. Time delay passes (1 day for admin, 30 days for implementation)
     * 3. Proposed address calls accept -> current is updated, proposal is cleared
     *
     * @param current Currently active address with the role/privilege
     * @param proposal Proposed new address awaiting acceptance after time delay
     * @param timeToAccept Timestamp after which the proposal can be accepted
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @notice Time-delayed proposal structure for uint-type governance changes
     * @dev Used for numeric parameter changes requiring time-delayed governance
     *      Follows the same pattern as AddressTypeProposal for consistency
     *
     * @param current Currently active value for the parameter
     * @param proposal Proposed new value awaiting acceptance after time delay
     * @param timeToAccept Timestamp after which the proposal can be accepted
     */
    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }
}
