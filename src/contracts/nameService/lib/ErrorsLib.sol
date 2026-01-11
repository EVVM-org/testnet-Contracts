// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error SenderIsNotAdmin();
    error UserIsNotOwnerOfIdentity();
    error InvalidSignatureOnNameService();
    error InvalidUsername();
    error AmountMustBeGreaterThanZero();
    error UsernameExpired();
    error UsernameAlreadyRegistered();
    error PreRegistrationNotValid();
    error UserIsNotOwnerOfOffer();
    error AcceptOfferVerificationFailed();
    error RenewUsernameVerificationFailed();
    error EmptyCustomMetadata();
    error InvalidKey();
    error FlushUsernameVerificationFailed();
}