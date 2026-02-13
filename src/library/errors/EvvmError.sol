// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title EvvmError - Error Definitions for EVVM Core
 * @author Mate labs
 * @notice Custom error definitions for Evvm.sol core contract
 * @dev Custom errors are more gas-efficient than require
 *      statements with strings and provide better error
 *      handling in client applications.
 *
 * Error Categories:
 * - Access Control: Unauthorized access attempts
 * - Validation: Invalid inputs or state conditions
 * - Balance Management: Insufficient funds or amounts
 * - Time-Lock: Governance time delay mechanisms
 * - Initialization: Setup and configuration errors
 *
 * Integration:
 * - Used exclusively by Evvm.sol core contract
 * - Complements State.sol error handling
 * - Provides clear failure reasons for users
 *
 * @custom:scope Exclusive to Evvm.sol contract
 * @custom:security Clear failures without exposing state
 */
library EvvmError {
    //░▒▓█ Access Control Errors ████████████████████████████████████████████████▓▒░

    /// @dev Thrown when non-admin calls admin-only function (onlyAdmin modifier)
    error SenderIsNotAdmin();

    /// @dev Thrown when proxy implementation == address(0)
    error ImplementationIsNotActive();

    /// @dev Thrown when EIP-191 signature invalid or signer mismatch
    error InvalidSignature();

    /// @dev Thrown when msg.sender != tx executor address
    error SenderIsNotTheExecutor();

    /// @dev Thrown when non-treasury calls treasury-only function
    error SenderIsNotTreasury();

    /// @dev Thrown when non-proposed admin attempts acceptAdmin before timelock
    error SenderIsNotTheProposedAdmin();

    /// @dev Thrown when EOA calls caPay/disperseCaPay (contract-only functions)
    error NotAnCA();

    //░▒▓█ Balance and Amount Errors ████████████████████████████████████████████▓▒░

    /// @dev Thrown when balance < transfer amount
    error InsufficientBalance();

    /// @dev Thrown when amount validation fails (e.g., dispersePay total != sum)
    error InvalidAmount();

    //░▒▓█ Initialization and Setup Errors ██████████████████████████████████████▓▒░

    /// @dev Thrown when one-time setup function called after breaker flag set
    error BreakerExploded();

    /// @dev Thrown when attempting EVVM ID change after 24h window
    error WindowExpired();

    /// @dev Thrown when address(0) provided (constructor, setup)
    error AddressCantBeZero();

    /// @dev Thrown when address validation fails in proposals
    error IncorrectAddressInput();

    //░▒▓█ Time-Lock Errors █████████████████████████████████████████████████████▓▒░

    /// @dev Thrown when attempting time-locked action before delay (30d impl, 1d admin)
    error TimeLockNotExpired();
}
