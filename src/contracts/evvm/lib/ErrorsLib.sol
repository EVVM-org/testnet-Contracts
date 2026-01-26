// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title ErrorsLib
 * @author Mate labs
 * @notice Library containing custom error definitions exclusively for the Evvm.sol contract
 * @dev This library defines all custom errors used by the Evvm.sol core contract.
 *      Custom errors are more gas-efficient than require statements with strings
 *      and provide better error handling in client applications.
 *
 * Error Categories:
 * - Access Control: Errors related to unauthorized access attempts
 * - Validation: Errors for invalid inputs or state conditions
 * - Nonce Management: Errors for transaction replay protection
 * - Time-Lock: Errors for governance time delay mechanisms
 * - Balance: Errors for insufficient funds or invalid amounts
 *
 * @custom:scope Exclusive to the Evvm.sol contract
 * @custom:security All errors are designed to provide clear failure reasons
 *                  without exposing sensitive internal state information
 */
library ErrorsLib {
    //░▒▓█ Access Control Errors ████████████████████████████████████████████████▓▒░

    /**
     * @notice Thrown when a function restricted to admin is called by a non-admin address
     * @dev Used in functions with the `onlyAdmin` modifier
     */
    error SenderIsNotAdmin();

    /**
     * @notice Thrown when attempting to use the proxy without a valid implementation contract
     * @dev Occurs when the fallback function is called but currentImplementation is address(0)
     */
    error ImplementationIsNotActive();

    /**
     * @notice Thrown when the provided cryptographic signature is invalid or doesn't match the signer
     * @dev Used in payment functions to verify EIP-191 signatures
     */
    error InvalidSignature();

    /**
     * @notice Thrown when a transaction specifies an executor but the caller is not that executor
     * @dev Enforces that only the designated executor can process certain transactions
     */
    error SenderIsNotTheExecutor();

    /**
     * @notice Thrown when a function restricted to treasury is called by a non-treasury address
     * @dev Used in treasury-exclusive functions like addAmountToUser and removeAmountFromUser
     */
    error SenderIsNotTreasury();

    /**
     * @notice Thrown when the proposed admin tries to accept before the time lock expires
     * @dev Part of the time-delayed admin transfer mechanism
     */
    error SenderIsNotTheProposedAdmin();

    /**
     * @notice Thrown when a caller is not a smart contract (Contract Account)
     * @dev Used in caPay and disperseCaPay to ensure only contracts can call these functions
     */
    error NotAnCA();

    //░▒▓█ Nonce Management Errors ██████████████████████████████████████████████▓▒░

    /**
     * @notice Thrown when the provided synchronous nonce doesn't match the expected sequential nonce
     * @dev Sync nonces must be used in order (0, 1, 2, ...)
     */
    error SyncNonceMismatch();

    /**
     * @notice Thrown when attempting to use an asynchronous nonce that has already been consumed
     * @dev Async nonces can be used in any order but only once
     */
    error AsyncNonceAlreadyUsed();

    //░▒▓█ Balance and Amount Errors ████████████████████████████████████████████▓▒░

    /**
     * @notice Thrown when a user doesn't have enough tokens to complete a transfer
     * @dev Checked before any balance deduction to prevent underflows
     */
    error InsufficientBalance();

    /**
     * @notice Thrown when the provided amount doesn't match expected values
     * @dev Used in dispersePay to verify total amount equals sum of individual amounts
     */
    error InvalidAmount();

    //░▒▓█ Initialization and Setup Errors ██████████████████████████████████████▓▒░

    /**
     * @notice Thrown when attempting to call a one-time setup function after it has been used
     * @dev Used in _setupNameServiceAndTreasuryAddress to prevent reconfiguration
     */
    error BreakerExploded();

    /**
     * @notice Thrown when attempting to change EVVM ID after the allowed time window has passed
     * @dev The EVVM ID can only be changed within 24 hours of the last change
     */
    error WindowExpired();

    /**
     * @notice Thrown when address(0) is provided where a valid address is required
     * @dev Used in constructor and setup functions to validate critical addresses
     */
    error AddressCantBeZero();

    /**
     * @notice Thrown when an address input doesn't meet validation requirements
     * @dev Used when proposing new admin or implementation with invalid addresses
     */
    error IncorrectAddressInput();

    //░▒▓█ Time-Lock Errors █████████████████████████████████████████████████████▓▒░

    /**
     * @notice Thrown when attempting to execute a time-locked action before the delay has passed
     * @dev Used in acceptImplementation (30 days) and acceptAdmin (1 day) functions
     */
    error TimeLockNotExpired();
}
