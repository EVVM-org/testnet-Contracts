// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title Staking Data Structures
 * @author Mate Labs
 * @notice Core data structures for Staking.sol (presale, history, service staking)
 * @dev Operations validated via State.sol. Payments via Core.sol. Cost: PRICE_OF_STAKING (5083 PT) per token.
 */

library StakingStructs {
    /**
     * @notice Metadata for presale staker whitelist
     * @dev Max 800 presale stakers globally. Each limited to 2 staking tokens.
     * @param isAllow Presale whitelist status
     * @param stakingAmount Current staking tokens staked (max 2)
     */
    struct PresaleStakerMetadata {
        bool isAllow;
        uint256 stakingAmount;
    }

    /**
     * @notice Historical record of staking transactions
     * @dev Transaction types: 0x01=staking, 0x02=unstaking, others=yield/rewards.
     * @param transactionType Operation type identifier
     * @param amount Staking tokens affected
     * @param timestamp Block timestamp
     * @param totalStaked Total after operation
     */
    struct HistoryMetadata {
        bytes32 transactionType;
        uint256 amount;
        uint256 timestamp;
        uint256 totalStaked;
    }

    /**
     * @notice Temporary metadata for service staking process
     * @dev Atomic 3-step process: prepareServiceStaking → Evvm.caPay → confirmServiceStaking. All steps MUST occur in same tx.
     * @param service Contract performing staking
     * @param timestamp Block timestamp of prepare
     * @param amountOfStaking Staking tokens to acquire
     * @param amountServiceBeforeStaking Service PT balance before
     * @param amountStakingBeforeStaking Staking PT balance before
     */
    struct ServiceStakingMetadata {
        address service;
        uint256 timestamp;
        uint256 amountOfStaking;
        uint256 amountServiceBeforeStaking;
        uint256 amountStakingBeforeStaking;
    }

    /**
     * @notice Account metadata with service/EOA indicator
     * @dev IsAService: true if code size > 0 (contract), false if code size == 0 (EOA).
     * @param Address Account address
     * @param IsAService Contract flag
     */
    struct AccountMetadata {
        address Address;
        bool IsAService;
    }

}
