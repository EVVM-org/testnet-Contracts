// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

interface IState {
    error AsyncNonceAlreadyReserved();
    error AsyncNonceAlreadyUsed();
    error AsyncNonceIsReservedByAnotherService();
    error AsyncNonceNotReserved();
    error InvalidSignature();
    error ProposalForUserValidatorNotReady();
    error ProposalNotReady();
    error SenderIsNotAdmin();
    error SyncNonceMismatch();
    error UserCannotExecuteTransaction();

    function acceptAdminProposal() external;
    function acceptUserValidatorProposal() external;
    function admin() external view returns (address current, address proposal, uint256 timeToAccept);
    function asyncNonceStatus(address user, uint256 nonce) external view returns (bytes1);
    function cancelUserValidatorProposal() external;
    function getAsyncNonceReservation(address user, uint256 nonce) external view returns (address);
    function getEvvmAddress() external view returns (address);
    function getEvvmID() external view returns (uint256);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getNextCurrentSyncNonce(address user) external view returns (uint256);
    function isAsyncNonceReserved(address user, uint256 nonce) external view returns (bool);
    function proposeAdmin(address newAdmin, uint256 delay) external;
    function proposeUserValidator(address newValidator) external;
    function reserveAsyncNonce(address user, uint256 nonce, address serviceAddress) external;
    function revokeAsyncNonce(address user, uint256 nonce) external;
    function userValidatorAddress() external view returns (address current, address proposal, uint256 timeToAccept);
    function validateAndConsumeNonce(
        address user,
        bytes32 hashPayload,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
}
