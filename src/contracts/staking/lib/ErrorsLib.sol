// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error SenderIsNotAdmin();
    error SenderIsNotGoldenFisher();
    error InvalidSignatureOnStaking();
    error StakingNonceAlreadyUsed();
    error PresaleStakingDisabled();
    error UserPresaleStakerLimitExceeded();
    error UserIsNotPresaleStaker();
    error PublicStakingDisabled();
    error AddressIsNotAService();
    error UserAndServiceMismatch();
    error AddressMustWaitToStakeAgain();
    error AddressMustWaitToFullUnstake();
    error ServiceDoesNotFulfillCorrectStakingAmount(uint256 requiredAmount);
    error ServiceDoesNotStakeInSameTx();
    error AddressMismatch();
    error LimitPresaleStakersExceeded();
    error SenderIsNotProposedAdmin();
    error TimeToAcceptProposalNotReached();
}
