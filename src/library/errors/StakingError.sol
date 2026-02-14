// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title Staking Error Library
 * @author Mate Labs
 * @notice Custom errors for Staking.sol
 * @dev Gas-efficient errors for Staking.sol. State.sol validates signatures, Core.sol processes payments.
 */

library StakingError {
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Access Control Errors
    /// ▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when non-admin calls admin-only function (onlyOwner)
    error SenderIsNotAdmin();

    /// @dev Thrown when non-goldenFisher attempts goldenStaking (sync nonces with Core.sol)
    error SenderIsNotGoldenFisher();

    /// @dev Thrown when non-proposed admin attempts acceptNewAdmin (1d delay)
    error SenderIsNotProposedAdmin();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Presale Staking Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when presale staking attempted while disabled (allowPresaleStaking.flag == false)
    error PresaleStakingDisabled();

    /// @dev Thrown when presale user tries to stake beyond 2-token cap
    error UserPresaleStakerLimitExceeded();

    /// @dev Thrown when non-whitelisted user attempts presaleStaking (max 800 presale stakers)
    error UserIsNotPresaleStaker();

    /// @dev Thrown when adding presale staker beyond 800 limit (LIMIT_PRESALE_STAKER)
    error LimitPresaleStakersExceeded();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Public Staking Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when public staking attempted while disabled (allowPublicStaking.flag == false). Uses State.sol async nonces.
    error PublicStakingDisabled();

    ///Service Staking Errors

    /// @dev Thrown when EOA calls service-only function (onlyCA checks code size)
    error AddressIsNotAService();

    /// @dev Thrown when service stakes for wrong user (user must equal service address)
    error UserAndServiceMismatch();

    /// @dev Thrown when confirmServiceStaking caller != prepareServiceStaking caller
    error AddressMismatch();

    /// @dev Thrown when Principal Token transfer != PRICE_OF_STAKING * amountOfStaking (via Evvm.caPay)
    /// @param requiredAmount Exact Principal Tokens needed
    error ServiceDoesNotFulfillCorrectStakingAmount(uint256 requiredAmount);

    /// @dev Thrown when confirm timestamp != prepare timestamp (atomic 3-step process required)
    error ServiceDoesNotStakeInSameTx();

    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    /// Time Lock Errors
    ///▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /// @dev Thrown when re-staking before cooldown expires (secondsToUnlockStaking.current)
    error AddressMustWaitToStakeAgain();

    /// @dev Thrown when full unstake attempted before lock period (secondsToUnllockFullUnstaking.current = 5 days)
    error AddressMustWaitToFullUnstake();

    /// @dev Thrown when accepting governance proposal before 1-day delay (TIME_TO_ACCEPT_PROPOSAL)
    error TimeToAcceptProposalNotReached();
}
