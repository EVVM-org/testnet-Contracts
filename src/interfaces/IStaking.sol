// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library StakingStructs {
    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAccept;
    }

    struct HistoryMetadata {
        bytes32 transactionType;
        uint256 amount;
        uint256 timestamp;
        uint256 totalStaked;
    }
}

interface IStaking {
    error AddressIsNotAService();
    error AddressMismatch();
    error AddressMustWaitToFullUnstake();
    error AddressMustWaitToStakeAgain();
    error AsyncNonceAlreadyUsed();
    error InvalidSignatureOnStaking();
    error LimitPresaleStakersExceeded();
    error PresaleStakingDisabled();
    error PublicStakingDisabled();
    error SenderIsNotAdmin();
    error SenderIsNotGoldenFisher();
    error SenderIsNotProposedAdmin();
    error ServiceDoesNotFulfillCorrectStakingAmount(uint256 requiredAmount);
    error ServiceDoesNotStakeInSameTx();
    error TimeToAcceptProposalNotReached();
    error UserIsNotPresaleStaker();
    error UserPresaleStakerLimitExceeded();

    function _setupEstimatorAndEvvm(address _estimator, address _evvm) external;
    function acceptNewAdmin() external;
    function acceptNewEstimator() external;
    function acceptNewGoldenFisher() external;
    function acceptSetSecondsToUnlockStaking() external;
    function addPresaleStaker(address _staker) external;
    function addPresaleStakers(address[] memory _stakers) external;
    function cancelChangeAllowPresaleStaking() external;
    function cancelChangeAllowPublicStaking() external;
    function cancelSetSecondsToUnllockFullUnstaking() external;
    function confirmChangeAllowPresaleStaking() external;
    function confirmChangeAllowPublicStaking() external;
    function confirmServiceStaking() external;
    function confirmSetSecondsToUnllockFullUnstaking() external;
    function getAddressHistory(address _account) external view returns (StakingStructs.HistoryMetadata[] memory);
    function getAddressHistoryByIndex(address _account, uint256 _index)
        external
        view
        returns (StakingStructs.HistoryMetadata memory);
    function getAllowPresaleStaking() external view returns (StakingStructs.BoolTypeProposal memory);
    function getAllowPublicStaking() external view returns (StakingStructs.BoolTypeProposal memory);
    function getEstimatorAddress() external view returns (address);
    function getEstimatorProposal() external view returns (address);
    function getEvvmAddress() external view returns (address);
    function getEvvmID() external view returns (uint256);
    function getGoldenFisher() external view returns (address);
    function getGoldenFisherProposal() external view returns (address);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getMateAddress() external view returns (address);
    function getOwner() external view returns (address);
    function getPresaleStaker(address _account) external view returns (bool, uint256);
    function getPresaleStakerCount() external view returns (uint256);
    function getSecondsToUnlockFullUnstaking() external view returns (uint256);
    function getSecondsToUnlockStaking() external view returns (uint256);
    function getSizeOfAddressHistory(address _account) external view returns (uint256);
    function getTimeToUserUnlockFullUnstakingTime(address _account) external view returns (uint256);
    function getTimeToUserUnlockStakingTime(address _account) external view returns (uint256);
    function getUserAmountStaked(address _account) external view returns (uint256);
    function gimmeYiel(address user)
        external
        returns (
            bytes32 epochAnswer,
            address tokenToBeRewarded,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwriteUserHistory,
            uint256 timestampToBeOverwritten
        );
    function goldenStaking(bool isStaking, uint256 amountOfStaking, bytes memory signature_EVVM) external;
    function prepareChangeAllowPresaleStaking() external;
    function prepareChangeAllowPublicStaking() external;
    function prepareServiceStaking(uint256 amountOfStaking) external;
    function prepareSetSecondsToUnllockFullUnstaking(uint256 _secondsToUnllockFullUnstaking) external;
    function presaleStaking(
        address user,
        bool isStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool isAsyncExec_EVVM,
        bytes memory signature_EVVM
    ) external;
    function priceOfStaking() external pure returns (uint256);
    function proposeAdmin(address _newAdmin) external;
    function proposeEstimator(address _estimator) external;
    function proposeGoldenFisher(address _goldenFisher) external;
    function proposeSetSecondsToUnlockStaking(uint256 _secondsToUnlockStaking) external;
    function publicStaking(
        address user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool isAsyncExec_EVVM,
        bytes memory signature_EVVM
    ) external;
    function rejectProposalAdmin() external;
    function rejectProposalEstimator() external;
    function rejectProposalGoldenFisher() external;
    function rejectProposalSetSecondsToUnlockStaking() external;
    function serviceUnstaking(uint256 amountOfStaking) external;
}
