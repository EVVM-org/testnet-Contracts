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
        address originExecutor;
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

    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAccept;
    }

    struct Bytes1TypeProposal {
        bytes1 current;
        bytes1 proposal;
        uint256 timeToAccept;
    }

    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }
}

interface ICore {
    error AddressCantBeZero();
    error AsyncNonceAlreadyReserved();
    error AsyncNonceAlreadyUsed();
    error AsyncNonceIsReservedByAnotherService();
    error AsyncNonceNotReserved();
    error BaseRewardIncreaseNotAllowed();
    error BreakerExploded();
    error ImplementationIsNotActive();
    error IncorrectAddressInput();
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidListStatus();
    error InvalidServiceAddress();
    error InvalidSignature();
    error MaxSupplyDeletionNotAllowed();
    error NotAnCA();
    error OriginMismatch();
    error ProposalNotReadyToAccept();
    error RewardFlowDistributionChangeNotAllowed();
    error SenderIsNotAdmin();
    error SenderIsNotTheProposedAdmin();
    error SenderIsNotTreasury();
    error SenderMismatch();
    error SyncNonceMismatch();
    error TokenIsDeniedForExecution();
    error UserCannotExecuteTransaction();
    error WindowExpired();

    fallback() external;

    function acceptAdmin() external;
    function acceptChangeBaseRewardAmount() external;
    function acceptChangeRewardFlowDistribution() external;
    function acceptDeleteTotalSupply() external;
    function acceptImplementation() external;
    function acceptListStatusProposal() external;
    function acceptUserValidatorProposal() external;
    function addAmountToUser(address user, address token, uint256 amount) external;
    function addBalance(address user, address token, uint256 quantity) external;
    function asyncNonceStatus(address user, uint256 nonce) external view returns (bytes1);
    function batchPay(CoreStructs.BatchData[] memory batchData)
        external
        returns (uint256 successfulTransactions, bool[] memory results);
    function caPay(address to, address token, uint256 amount) external;
    function canExecuteUserTransaction(address user) external view returns (bool);
    function cancelUserValidatorProposal() external;
    function disperseCaPay(CoreStructs.DisperseCaPayMetadata[] memory toData, address token, uint256 amount) external;
    function dispersePay(
        address from,
        CoreStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address senderExecutor,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function getAllowListStatus(address token) external view returns (bool);
    function getAsyncNonceReservation(address user, uint256 nonce) external view returns (address);
    function getBalance(address user, address token) external view returns (uint256);
    function getChainHostCoinAddress() external pure returns (address);
    function getCurrentAdmin() external view returns (address);
    function getCurrentImplementation() external view returns (address);
    function getCurrentListStatus() external view returns (bytes1);
    function getCurrentSupply() external view returns (uint256);
    function getDenyListStatus(address token) external view returns (bool);
    function getETHAddress() external pure returns (address);
    function getEvvmID() external view returns (uint256);
    function getEvvmMetadata() external view returns (CoreStructs.EvvmMetadata memory);
    function getFlagIsStaker() external pure returns (bytes1);
    function getFullDetailAdmin() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getFullDetailImplementation() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getFullDetailListStatus() external view returns (ProposalStructs.Bytes1TypeProposal memory);
    function getFullDetailReward() external view returns (ProposalStructs.UintTypeProposal memory);
    function getFullDetailRewardFlowDistribution() external view returns (ProposalStructs.BoolTypeProposal memory);
    function getFullDetailUserValidator() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getNameServiceAddress() external view returns (address);
    function getNextCurrentSyncNonce(address user) external view returns (uint256);
    function getPrincipalTokenAddress() external view returns (address);
    function getPrincipalTokenTotalSupply() external view returns (uint256);
    function getRewardAmount() external view returns (uint256);
    function getRewardFlowDistributionFlag() external view returns (bool);
    function getStakingContractAddress() external view returns (address);
    function getTimeToAcceptImplementation() external pure returns (uint256);
    function getTimeToAcceptProposal() external pure returns (uint256);
    function getTimeToDeleteMaxSupply() external view returns (uint256);
    function getTreasuryAddress() external view returns (address);
    function getUserValidatorAddress() external view returns (address);
    function getWindowTimeToChangeEvvmID() external view returns (uint256);
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
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function pointStaker(address user, bytes1 answer) external;
    function proposeAdmin(address _newOwner) external;
    function proposeChangeBaseRewardAmount(uint256 newBaseReward) external;
    function proposeChangeRewardFlowDistribution() external;
    function proposeDeleteTotalSupply() external;
    function proposeImplementation(address _newImpl) external;
    function proposeListStatus(bytes1 newStatus) external;
    function proposeUserValidator(address newValidator) external;
    function recalculateReward() external;
    function rejectChangeBaseRewardAmount() external;
    function rejectChangeRewardFlowDistribution() external;
    function rejectDeleteTotalSupply() external;
    function rejectListStatusProposal() external;
    function rejectProposalAdmin() external;
    function rejectUpgrade() external;
    function removeAmountFromUser(address user, address token, uint256 amount) external;
    function reserveAsyncNonce(uint256 nonce, address senderExecutor) external;
    function revokeAsyncNonce(uint256 nonce) external;
    function setEvvmID(uint256 newEvvmID) external;
    function setPointStaker(address user, bytes1 answer) external;
    function setTokenStatusOnAllowList(address token, bool status) external;
    function setTokenStatusOnDenyList(address token, bool status) external;
    function validateAndConsumeNonce(
        address user,
        address senderExecutor,
        bytes32 hashPayload,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
}
