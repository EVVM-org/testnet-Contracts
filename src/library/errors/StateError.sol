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
library StateError {
        /// @dev Thrown when attempting to use a nonce that has already been consumed
    error AsyncNonceAlreadyUsed();

    /// @dev Thrown when the provided nonce does not match the expected next nonce
    error SyncNonceMismatch();

    /// @dev Thrown when the recovered signer does not match the expected user address
    error InvalidSignature();

    error AsyncNonceAlreadyReserved();

    error AsyncNonceNotReserved();

    error AsyncNonceIsReserved();

    error UserCannotExecuteTransaction();

    error AsyncNonceIsReservedByAnotherService();

    error ProposalForUserValidatorNotReady();

    error MsgSenderIsNotAContract();
}