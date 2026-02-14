// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;
/**
 * @title Staking Utilities for EVVM Services
 * @author Mate labs
 * @notice Abstract contract for Staking.sol integration enabling services to stake and earn Fisher fees
 * @dev Three-step staking: prepareServiceStaking → core.caPay(5083 PT * amount) → confirmServiceStaking. Cost: 5083 PT per staking token.
 */

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";

abstract contract StakingServiceUtils {
    /// @notice Staking contract reference
    /// @dev Used for all staking operations
    Staking internal staking;

    /**
     * @notice Initializes staking integration
     * @param stakingAddress Address of Staking.sol
     */
    constructor(address stakingAddress) {
        staking = Staking(stakingAddress);
    }

    /**
     * @notice Stakes tokens for this service via 3-step atomic process
     * @dev Calls prepareServiceStaking → core.caPay(PT, cost) → confirmServiceStaking. Requires 5083 PT * amountToStake in service Evvm balance.
     * @param amountToStake Number of staking tokens to purchase
     */
    function _makeStakeService(uint256 amountToStake) internal {
        staking.prepareServiceStaking(amountToStake);
        Core(staking.getCoreAddress()).caPay(
            address(staking),
            Core(staking.getCoreAddress()).getPrincipalTokenAddress(),
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    /**
     * @notice Unstakes tokens from this service, burning them and refunding 5083 PT per token
     * @dev Calls staking.serviceUnstaking(amount). PT refunded to service Evvm balance.
     * @param amountToUnstake Number of staking tokens to release
     */
    function _makeUnstakeService(uint256 amountToUnstake) internal {
        staking.serviceUnstaking(amountToUnstake);
    }

    /**
     * @notice Updates Staking.sol contract address for governance-controlled upgrades
     * @dev Should be protected with onlyAdmin and time-delay. Existing stakes remain in old contract.
     * @param newStakingAddress New Staking.sol contract address
     */
    function _changeStakingAddress(address newStakingAddress) internal virtual {
        staking = Staking(newStakingAddress);
    }
}
