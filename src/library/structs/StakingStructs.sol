// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title StakingStructs
 * @author Mate Labs
 * @notice Abstract contract containing all data structures used by the Staking contract
 * @dev This contract is exclusive to the Staking.sol contract and defines the data
 * structures for managing staking operations, governance proposals, and user history.
 *
 * Structure Categories:
 * - Staker Metadata: presaleStakerMetadata, HistoryMetadata
 * - Governance Proposals: AddressTypeProposal, UintTypeProposal, BoolTypeProposal
 * - Service Staking: ServiceStakingMetadata, AccountMetadata
 */

library StakingStructs {
    /**
     * @dev Metadata for presale stakers
     * @param isAllow Whether the address is allowed to participate in presale staking
     * @param stakingAmount Current number of staking tokens staked (max 2 for presale)
     */
    struct PresaleStakerMetadata {
        bool isAllow;
        uint256 stakingAmount;
    }

    /**
     * @dev Struct to store the history of the user
     * @param transactionType Type of transaction:
     *          - 0x01 for staking
     *          - 0x02 for unstaking
     *          - Other values for yield/reward transactions
     * @param amount Amount of staking staked/unstaked or reward received
     * @param timestamp Timestamp when the transaction occurred
     * @param totalStaked Total amount of staking currently staked after this transaction
     */
    struct HistoryMetadata {
        bytes32 transactionType;
        uint256 amount;
        uint256 timestamp;
        uint256 totalStaked;
    }

    /**
     * @dev Struct to store service staking metadata during the staking process
     * @param service Address of the service or contract account
     * @param timestamp Timestamp when the prepareServiceStaking was called
     * @param amountOfStaking Amount of staking tokens to be staked
     * @param amountServiceBeforeStaking Service's Principal Token balance before staking
     * @param amountStakingBeforeStaking Staking contract's Principal Token balance before staking
     */
    struct ServiceStakingMetadata {
        address service;
        uint256 timestamp;
        uint256 amountOfStaking;
        uint256 amountServiceBeforeStaking;
        uint256 amountStakingBeforeStaking;
    }

    /**
     * @dev Struct to encapsulate account metadata for staking operations
     * @param Address Address of the account
     * @param IsAService Boolean indicating if the account is a smart contract (service) account
     */
    struct AccountMetadata {
        address Address;
        bool IsAService;
    }

}
