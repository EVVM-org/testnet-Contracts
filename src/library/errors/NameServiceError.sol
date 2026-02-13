// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title NameServiceError - Error Definitions for NameService
 * @author Mate labs
 * @notice Custom errors for NameService.sol
 * @dev Gas-efficient errors used exclusively by NameService.sol. Works with State.sol (nonce) and Evvm.sol (payment).
 */
library NameServiceError {
    //█ Access Control Errors ███████████████████████████████████████████████████

    /// @dev Thrown when non-admin calls admin-only function (onlyAdmin modifier)
    error SenderIsNotAdmin();

    /// @dev Thrown when non-owner attempts to modify username or accept offers
    error UserIsNotOwnerOfIdentity();

    /// @dev Thrown when non-creator attempts withdrawOffer
    error UserIsNotOwnerOfOffer();

    /// @dev Thrown when non-proposed admin attempts acceptNewAdmin before timelock
    error SenderIsNotProposedAdmin();

    //█ Validation Errors ███████████████████████████████████████████████████████

    /// @dev Thrown when username format invalid (4+ chars, start with letter, alphanumeric)
    error InvalidUsername();

    /// @dev Thrown when amount == 0 (e.g., makeOffer requires value)
    error AmountMustBeGreaterThanZero();

    /// @dev Thrown when removing non-existent custom metadata key
    error InvalidKey();

    /// @dev Thrown when custom metadata value == empty string
    error EmptyCustomMetadata();

    /// @dev Thrown when admin proposal address/config invalid
    error InvalidAdminProposal();

    /// @dev Thrown when proposed EVVM address invalid
    error InvalidEvvmAddress();

    /// @dev Thrown when withdrawal amount invalid or > balance
    error InvalidWithdrawAmount();

    //█ Registration and Time-Based Errors █████████████████████████████████████

    /// @dev Thrown when attempting to register already-taken username
    error UsernameAlreadyRegistered();

    /// @dev Thrown when pre-registration doesn't exist or expired (30min window)
    error PreRegistrationNotValid();

    /// @dev Thrown when timestamp < current time (offer expiration, future ops)
    error CannotBeBeforeCurrentTime();

    /// @dev Thrown when operating on expired username (after expireDate)
    error OwnershipExpired();

    /// @dev Thrown when renewing > 100 years in advance
    error RenewalTimeLimitExceeded();

    /// @dev Thrown when time-locked governance action attempted prematurely
    error LockTimeNotExpired();

    //█ Marketplace and Offer Errors ███████████████████████████████████████████

    /// @dev Thrown when accepting/interacting with expired/non-existent offer (offerer == 0)
    error OfferInactive();

    //█ Identity Type Errors ██████████████████████████████████████████████████

    /// @dev Thrown when username operation attempted on pre-registration (flagNotAUsername: 0x01=pre-reg, 0x00=username)
    error IdentityIsNotAUsername();
}