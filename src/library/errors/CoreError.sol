// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title CoreError - Error Definitions for EVVM Core
 * @author Mate labs
 * @notice Custom error definitions for Core.sol core contract
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
 * - Used exclusively by Core.sol core contract
 * - Includes payment and nonce validation errors
 * - Provides clear failure reasons for users
 *
 * @custom:scope Exclusive to Core.sol contract
 * @custom:security Clear failures without exposing state
 */
library CoreError {
    //░▒▓█ Access Control Errors ████████████████████████████████████████████████▓▒░

    /// @dev Thrown when non-admin calls admin-only function (onlyAdmin modifier)
    error SenderIsNotAdmin();

    /// @dev Thrown when proxy implementation == address(0)
    error ImplementationIsNotActive();

    /// @dev Thrown when EIP-191 signature invalid or signer mismatch
    error InvalidSignature();

    /// @dev Thrown when msg.sender != sender executor address
    error SenderIsNotTheSenderExecutor();

    /// @dev Thrown when non-treasury calls treasury-only function
    error SenderIsNotTreasury();

    /// @dev Thrown when non-proposed admin attempts acceptAdmin before timelock
    error SenderIsNotTheProposedAdmin();

    error OriginIsNotTheOriginExecutor();

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



    /// @dev Thrown when async nonce already consumed
    error AsyncNonceAlreadyUsed();

    /// @dev Thrown when sync nonce != expected sequential nonce
    error SyncNonceMismatch();

    /// @dev Thrown when reserving already-reserved async nonce
    error AsyncNonceAlreadyReserved();

    /// @dev Thrown when revoking non-reserved async nonce
    error AsyncNonceNotReserved();

    /// @dev Thrown when using reserved async nonce (general check)
    error AsyncNonceIsReserved();

    /// @dev Thrown when UserValidator blocks user transaction
    error UserCannotExecuteTransaction();

    /// @dev Thrown when using async nonce reserved by different service
    error AsyncNonceIsReservedByAnotherService();

    /// @dev Thrown when accepting UserValidator proposal before timelock
    error ProposalForUserValidatorNotReady();

    /// @dev Thrown when validateAndConsumeNonce caller is EOA (contracts only)
    error MsgSenderIsNotAContract();

    /// @dev Thrown when accepting EVVM address proposal before timelock
    error ProposalForEvvmAddressNotReady();

    /// @dev Thrown when reserving nonce with service == address(0)
    error InvalidServiceAddress();
    
    /**
     * @dev Thrown when a token is in
     *    - the denylist (if the denylist is active)
     *    - not in the allowlist (if the allowlist is active)
     */
    error TokenIsDeniedForExecution();
}
