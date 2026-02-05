// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title ErrorsLib
 * @author Mate labs
 * @notice Library containing custom error definitions exclusively for the NameService.sol contract
 * @dev This library defines all custom errors used by the NameService.sol contract.
 *      Custom errors are more gas-efficient than require statements with strings
 *      and provide better error handling in client applications.
 *
 * Error Categories:
 * - Access Control: Errors related to ownership and admin permissions
 * - Validation: Errors for invalid usernames, signatures, and input validation
 * - Registration: Errors specific to username registration and pre-registration
 * - Marketplace: Errors for offer management and username trading
 * - Metadata: Errors for custom metadata operations
 * - Time-Lock: Errors for governance and renewal timing
 *
 * @custom:scope Exclusive to the NameService.sol contract
 * @custom:security All errors provide clear failure reasons without exposing sensitive data
 */
library NameServiceError {
    //█ Access Control Errors ███████████████████████████████████████████████████

    /**
     * @notice Thrown when a function restricted to admin is called by a non-admin address
     * @dev Used in functions with the `onlyAdmin` modifier
     */
    error SenderIsNotAdmin();

    /**
     * @notice Thrown when an operation is attempted by someone other than the username owner
     * @dev Used in functions that modify username data or accept offers
     */
    error UserIsNotOwnerOfIdentity();

    /**
     * @notice Thrown when an operation is attempted by someone other than the offer creator
     * @dev Used in withdrawOffer to ensure only the offerer can withdraw their own offer
     */
    error UserIsNotOwnerOfOffer();

    /**
     * @notice Thrown when the proposed admin tries to accept before meeting requirements
     * @dev Part of the time-delayed admin transfer mechanism
     */
    error SenderIsNotProposedAdmin();

    //█ Validation Errors ███████████████████████████████████████████████████████

    /**
     * @notice Thrown when the provided EIP-191 signature is invalid or doesn't match the signer
     * @dev Used in all operations requiring signature verification
     */
    error InvalidSignatureOnNameService();

    /**
     * @notice Thrown when a username doesn't meet format requirements
     * @dev Username must be 4+ characters, start with letter, contain only alphanumeric
     */
    error InvalidUsername();

    /**
     * @notice Thrown when an amount parameter is zero but should be positive
     * @dev Used in makeOffer to ensure offers have value
     */
    error AmountMustBeGreaterThanZero();

    /**
     * @notice Thrown when a custom metadata key is invalid
     * @dev Used when trying to remove metadata with a key that doesn't exist
     */
    error InvalidKey();

    /**
     * @notice Thrown when attempting to add empty custom metadata
     * @dev Custom metadata value cannot be an empty string
     */
    error EmptyCustomMetadata();

    /**
     * @notice Thrown when a proposed address or configuration is invalid
     * @dev Used in admin proposal functions
     */
    error InvalidAdminProposal();

    /**
     * @notice Thrown when the EVVM address being proposed is invalid
     * @dev Used when updating the EVVM contract integration address
     */
    error InvalidEvvmAddress();

    /**
     * @notice Thrown when the withdrawal amount is invalid or exceeds available balance
     * @dev Used in token withdrawal functions
     */
    error InvalidWithdrawAmount();

    //█ Registration and Time-Based Errors █████████████████████████████████████

    /**
     * @notice Thrown when attempting to register a username that is already taken
     * @dev Usernames are unique and cannot be registered twice
     */
    error UsernameAlreadyRegistered();

    /**
     * @notice Thrown when the pre-registration doesn't exist or has expired
     * @dev Pre-registration must be completed within 30 minutes and by the same user
     */
    error PreRegistrationNotValid();

    /**
     * @notice Thrown when a timestamp/date is set to before the current time
     * @dev Used for offer expiration dates and other future-dated operations
     */
    error CannotBeBeforeCurrentTime();

    /**
     * @notice Thrown when attempting operations on an expired username
     * @dev Username ownership expires after the expireDate timestamp
     */
    error OwnershipExpired();

    /**
     * @notice Thrown when trying to renew a username beyond the maximum allowed period
     * @dev Usernames can only be renewed up to 100 years in advance
     */
    error RenewalTimeLimitExceeded();

    /**
     * @notice Thrown when attempting to execute a time-locked action prematurely
     * @dev Used in governance functions with time-delay requirements
     */
    error LockTimeNotExpired();

    //█ Marketplace and Offer Errors ███████████████████████████████████████████

    /**
     * @notice Thrown when trying to accept or interact with an expired or non-existent offer
     * @dev Offers expire at their expireDate timestamp or when offerer is address(0)
     */
    error OfferInactive();

    //█ Identity Type Errors ██████████████████████████████████████████████████

    /**
     * @notice Thrown when an operation requiring a fully registered username is attempted on a pre-registration
     * @dev Pre-registrations have flagNotAUsername = 0x01, full usernames have 0x00
     */
    error IdentityIsNotAUsername();
}