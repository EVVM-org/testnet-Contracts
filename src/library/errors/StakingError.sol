// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title ErrorsLib
 * @author Mate Labs
 * @notice Library containing all custom error definitions for the Staking contract
 * @dev This library is exclusive to the Staking.sol contract and provides descriptive
 * error types for better gas efficiency and debugging compared to revert strings.
 *
 * Error Categories:
 * - Access Control: Permission and authorization errors
 * - Signature Verification: EIP-191 signature validation errors
 * - Presale Staking: Presale-specific staking limitations
 * - Public Staking: General staking state errors
 * - Service Staking: Smart contract (service) staking errors
 * - Time Lock: Time-delayed governance and cooldown errors
 */

library StakingError {
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Access Control Errors
    /// ▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when a non-admin address attempts to call an admin-only function
    error SenderIsNotAdmin();

    /// @dev Thrown when a non-golden-fisher address attempts to call a golden fisher function
    error SenderIsNotGoldenFisher();

    /// @dev Thrown when a non-proposed-admin address attempts to accept an admin proposal
    error SenderIsNotProposedAdmin();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Presale Staking Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when presale staking is attempted while disabled or when public staking is active
    error PresaleStakingDisabled();

    /// @dev Thrown when a presale user tries to stake more than the 2-staking limit
    error UserPresaleStakerLimitExceeded();

    /// @dev Thrown when a non-presale-registered address attempts presale staking
    error UserIsNotPresaleStaker();

    /// @dev Thrown when attempting to add more presale stakers beyond the 800 limit
    error LimitPresaleStakersExceeded();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Public Staking Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when public staking is attempted while the feature is disabled
    error PublicStakingDisabled();

    ///Service Staking Errors

    /// @dev Thrown when a non-contract address attempts to call a service-only function
    error AddressIsNotAService();

    /// @dev Thrown when the user address doesn't match the service address in staking metadata
    error UserAndServiceMismatch();

    /// @dev Thrown when confirmServiceStaking is called by a different address than prepareServiceStaking
    error AddressMismatch();

    /// @dev Thrown when the payment amount doesn't match the required staking cost
    /// @param requiredAmount The exact amount of Principal Tokens that should have been transferred
    error ServiceDoesNotFulfillCorrectStakingAmount(uint256 requiredAmount);

    /// @dev Thrown when confirmServiceStaking is not called in the same transaction as prepareServiceStaking
    error ServiceDoesNotStakeInSameTx();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Time Lock Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when a user attempts to stake before their cooldown period expires
    error AddressMustWaitToStakeAgain();

    /// @dev Thrown when a user attempts full unstaking before the 21-day lock period expires
    error AddressMustWaitToFullUnstake();

    /// @dev Thrown when attempting to accept a proposal before the time delay has passed
    error TimeToAcceptProposalNotReached();
}
