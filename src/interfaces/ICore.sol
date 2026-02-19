// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library CoreStructs {
    struct BatchData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        address senderExecutor;
        uint256 nonce;
        bool isAsyncExec;
        bytes signature;
    }

    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    struct EvvmMetadata {
        string EvvmName;
        uint256 EvvmID;
        string principalTokenName;
        string principalTokenSymbol;
        address principalTokenAddress;
        uint256 totalSupply;
        uint256 eraTokens;
        uint256 reward;
    }
}

library ProposalStructs {
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }
}

interface ICore {
    error AddressCantBeZero();
    error AsyncNonceAlreadyReserved();
    error AsyncNonceAlreadyUsed();
    error AsyncNonceIsReservedByAnotherService();
    error AsyncNonceNotReserved();
    error BreakerExploded();
    error ImplementationIsNotActive();
    error IncorrectAddressInput();
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidServiceAddress();
    error InvalidSignature();
    error MsgSenderIsNotAContract();
    error NotAnCA();
    error OriginIsNotTheOriginExecutor();
    error ProposalForUserValidatorNotReady();
    error SenderIsNotAdmin();
    error SenderIsNotTheProposedAdmin();
    error SenderIsNotTheSenderExecutor();
    error SenderIsNotTreasury();
    error SyncNonceMismatch();
    error TimeLockNotExpired();
    error UserCannotExecuteTransaction();
    error WindowExpired();

    fallback() external;

    function acceptAdmin() external;
    function acceptImplementation() external;
    function acceptUserValidatorProposal() external;
    function addAmountToUser(address user, address token, uint256 amount) external;
    function addBalance(address user, address token, uint256 quantity) external;
    function asyncNonceStatus(address user, uint256 nonce) external view returns (bytes1);
    function batchPay(CoreStructs.BatchData[] memory batchData)
        external
        returns (uint256 successfulTransactions, bool[] memory results);
    function caPay(address to, address token, uint256 amount) external;
    function cancelUserValidatorProposal() external;
    function disperseCaPay(CoreStructs.DisperseCaPayMetadata[] memory toData, address token, uint256 amount) external;
    function dispersePay(
        address from,
        CoreStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function getAsyncNonceReservation(address user, uint256 nonce) external view returns (address);
    function getBalance(address user, address token) external view returns (uint256);
    function getChainHostCoinAddress() external pure returns (address);
    function getCurrentAdmin() external view returns (address);
    function getCurrentImplementation() external view returns (address);
    function getEraPrincipalToken() external view returns (uint256);
    function getEvvmID() external view returns (uint256);
    function getEvvmMetadata() external view returns (CoreStructs.EvvmMetadata memory);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getNameServiceAddress() external view returns (address);
    function getNextCurrentSyncNonce(address user) external view returns (uint256);
    function getNextFisherDepositNonce(address user) external view returns (uint256);
    function getPrincipalTokenAddress() external view returns (address);
    function getPrincipalTokenTotalSupply() external view returns (uint256);
    function getProposalAdmin() external view returns (address);
    function getProposalImplementation() external view returns (address);
    function getRewardAmount() external view returns (uint256);
    function getStakingContractAddress() external view returns (address);
    function getTimeToAcceptAdmin() external view returns (uint256);
    function getTimeToAcceptImplementation() external view returns (uint256);
    function getUserValidatorAddress() external view returns (address);
    function getUserValidatorAddressDetails() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getWhitelistTokenToBeAdded() external view returns (address);
    function getWhitelistTokenToBeAddedDateToSet() external view returns (uint256);
    function initializeSystemContracts(address _nameServiceAddress, address _treasuryAddress) external;
    function isAddressStaker(address user) external view returns (bool);
    function pay(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function pointStaker(address user, bytes1 answer) external;
    function proposeAdmin(address _newOwner) external;
    function proposeImplementation(address _newImpl) external;
    function proposeUserValidator(address newValidator) external;
    function recalculateReward() external;
    function rejectProposalAdmin() external;
    function rejectUpgrade() external;
    function removeAmountFromUser(address user, address token, uint256 amount) external;
    function reserveAsyncNonce(uint256 nonce, address serviceAddress) external;
    function revokeAsyncNonce(uint256 nonce) external;
    function setEvvmID(uint256 newEvvmID) external;
    function setPointStaker(address user, bytes1 answer) external;
    function validateAndConsumeNonce(
        address user,
        bytes32 hashPayload,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
}
