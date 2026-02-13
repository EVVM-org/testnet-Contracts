// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EVVM Service Base Contract
 * @author Mate Labs
 * @notice Abstract base contract for building EVVM services with payment, staking, and nonce management
 * @dev Inherits StakingServiceUtils, EvvmPayments, StateManagment. Signatures validated via State.sol. Community can build custom services.
 */

import {EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {
    StateManagment
} from "@evvm/testnet-contracts/library/utils/service/StateManagment.sol";
import {
    StakingServiceUtils
} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {
    EvvmPayments
} from "@evvm/testnet-contracts/library/utils/service/EvvmPayments.sol";

abstract contract EvvmService is
    StakingServiceUtils,
    EvvmPayments,
    StateManagment
{
    /// @dev Thrown when signature validation fails
    error InvalidServiceSignature();

    /**
     * @notice Initializes EVVM service with core contract references
     * @dev Initializes StakingServiceUtils, EvvmPayments, StateManagment in order
     * @param evvmAddress Address of Evvm.sol contract
     * @param stakingAddress Address of Staking.sol contract
     * @param stateAddress Address of State.sol contract
     */
    constructor(
        address evvmAddress,
        address stakingAddress,
        address stateAddress
    )
        StakingServiceUtils(stakingAddress)
        EvvmPayments(evvmAddress)
        StateManagment(stateAddress)
    {}

    /**
     * @notice Gets unique EVVM instance identifier for signature validation
     * @dev Returns evvm.getEvvmID(). Prevents cross-chain replays.
     * @return Unique EVVM instance identifier
     */
    function getEvvmID() internal view returns (uint256) {
        return evvm.getEvvmID();
    }

    /**
     * @notice Gets Principal Token (MATE) address
     * @dev Returns evvm.getPrincipalTokenAddress(). Used for payment operations.
     * @return Address of Principal Token (MATE)
     */
    function getPrincipalTokenAddress() internal view returns (address) {
        return evvm.getPrincipalTokenAddress();
    }
}
