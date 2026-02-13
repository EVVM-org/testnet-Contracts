// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title StateError - Error Definitions for State Contract
 * @author Mate labs
 * @notice Custom errors for State.sol nonce coordinator
 * @dev Gas-efficient errors for async/sync nonce validation and EIP-191 signature verification.
 */
library StateError {
    /// @dev Thrown when async nonce already consumed
    error AsyncNonceAlreadyUsed();

    /// @dev Thrown when sync nonce != expected sequential nonce
    error SyncNonceMismatch();

    /// @dev Thrown when EIP-191 signature signer != expected user
    error InvalidSignature();

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
}