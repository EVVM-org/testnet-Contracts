// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library EvvmStructs {
    struct BatchData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        address executor;
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

interface IEvvm {
    error AddressCantBeZero();
    error BreakerExploded();
    error ImplementationIsNotActive();
    error IncorrectAddressInput();
    error InsufficientBalance();
    error InvalidAmount();
    error NotAnCA();
    error SenderIsNotAdmin();
    error SenderIsNotTheExecutor();
    error SenderIsNotTheProposedAdmin();
    error SenderIsNotTreasury();
    error TimeLockNotExpired();
    error WindowExpired();

    fallback() external;

    function acceptAdmin() external;
    function acceptImplementation() external;
    function addAmountToUser(address user, address token, uint256 amount) external;
    function addBalance(address user, address token, uint256 quantity) external;
    function batchPay(EvvmStructs.BatchData[] memory batchData)
        external
        returns (uint256 successfulTransactions, bool[] memory results);
    function caPay(address to, address token, uint256 amount) external;
    function disperseCaPay(EvvmStructs.DisperseCaPayMetadata[] memory toData, address token, uint256 amount) external;
    function dispersePay(
        address from,
        EvvmStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function getBalance(address user, address token) external view returns (uint256);
    function getChainHostCoinAddress() external pure returns (address);
    function getCurrentAdmin() external view returns (address);
    function getCurrentImplementation() external view returns (address);
    function getEraPrincipalToken() external view returns (uint256);
    function getEvvmID() external view returns (uint256);
    function getEvvmMetadata() external view returns (EvvmStructs.EvvmMetadata memory);
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
    function getWhitelistTokenToBeAdded() external view returns (address);
    function getWhitelistTokenToBeAddedDateToSet() external view returns (uint256);
    function initializeSystemContracts(address _nameServiceAddress, address _treasuryAddress, address _stateAddress)
        external;
    function isAddressStaker(address user) external view returns (bool);
    function pay(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) external;
    function pointStaker(address user, bytes1 answer) external;
    function proposeAdmin(address _newOwner) external;
    function proposeImplementation(address _newImpl) external;
    function recalculateReward() external;
    function rejectProposalAdmin() external;
    function rejectUpgrade() external;
    function removeAmountFromUser(address user, address token, uint256 amount) external;
    function setEvvmID(uint256 newEvvmID) external;
    function setPointStaker(address user, bytes1 answer) external;
}
