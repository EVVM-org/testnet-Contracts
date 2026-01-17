// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error SenderIsNotAdmin();
    error UserIsNotOwnerOfIdentity();
    error InvalidSignatureOnNameService();
    error InvalidUsername();
    error AmountMustBeGreaterThanZero();
    error CannotBeBeforeCurrentTime();
    error UsernameAlreadyRegistered();
    error PreRegistrationNotValid();
    error UserIsNotOwnerOfOffer();
    error OfferInactive();
    error IdentityIsNotAUsername();
    error RenewalTimeLimitExceeded();
    error EmptyCustomMetadata();
    error InvalidKey();
    error OwnershipExpired();
    error InvalidAdminProposal();
    error SenderIsNotProposedAdmin();
    error LockTimeNotExpired();
    error InvalidWithdrawAmount();
    error InvalidEvvmAddress();
}