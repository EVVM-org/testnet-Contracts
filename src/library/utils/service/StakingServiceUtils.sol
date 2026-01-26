// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;
/**
 * @title StakingServiceUtils
 * @author Mate Labs
 * @notice Abstract contract providing staking utilities for EVVM services
 * @dev This contract provides helper functions for services that need to
 * interact with the EVVM Staking contract. Services can stake tokens to:
 *
 * Benefits of Service Staking:
 * - Earn rewards from Fisher (executor) transaction fees
 * - Participate in the EVVM staking ecosystem
 * - Increase service credibility and commitment
 *
 * Staking Flow:
 * 1. Call _makeStakeService with desired amount
 * 2. Contract prepares staking, transfers tokens, and confirms
 * 3. Call _makeUnstakeService when ready to withdraw
 *
 * This contract is designed for use by community-developed services that want
 * to participate in the EVVM staking mechanism.
 */

import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";
import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract StakingServiceUtils {
    /// @dev Reference to the Staking contract for staking operations
    IStaking internal staking;

    /**
     * @notice Initializes the StakingServiceUtils with the Staking contract address
     * @param stakingAddress Address of the EVVM Staking contract
     */
    constructor(address stakingAddress) {
        staking = IStaking(stakingAddress);
    }

    /**
     * @notice Stakes tokens on behalf of this service contract
     * @dev Performs the full staking flow:
     *      1. Prepares staking in the Staking contract
     *      2. Transfers the required Principal Tokens via EVVM caPay
     *      3. Confirms the staking operation
     * @param amountToStake Number of staking units to purchase
     */
    function _makeStakeService(uint256 amountToStake) internal {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            IEvvm(staking.getEvvmAddress()).getPrincipalTokenAddress(),
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    /**
     * @notice Unstakes tokens from this service contract
     * @dev Calls the Staking contract to release staked tokens
     * @param amountToUnstake Number of staking units to release
     */
    function _makeUnstakeService(uint256 amountToUnstake) internal {
        staking.serviceUnstaking(amountToUnstake);
    }

    /**
     * @notice Updates the Staking contract address
     * @dev Internal function for governance-controlled Staking address changes.
     *      Should be protected by time-delayed governance in implementing contracts.
     * @param newStakingAddress Address of the new Staking contract
     */
    function _changeStakingAddress(address newStakingAddress) internal virtual {
        staking = IStaking(newStakingAddress);
    }
}
