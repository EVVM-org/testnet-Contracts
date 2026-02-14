// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EVVM Service Base Contract
 * @author Mate Labs
 * @notice Abstract base contract for building EVVM services with payment, staking, and nonce management
 * @dev Inherits StakingServiceUtils, CoreExecution, StateManagment. Signatures validated via State.sol. Community can build custom services.
 */

import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    StakingServiceUtils
} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {
    CoreExecution
} from "@evvm/testnet-contracts/library/utils/service/CoreExecution.sol";

abstract contract EvvmService is
    StakingServiceUtils,
    CoreExecution
{
    /// @dev Thrown when signature validation fails
    error InvalidServiceSignature();

    /**
     * @notice Initializes EVVM service with core contract references
     * @dev Initializes StakingServiceUtils, CoreExecution, StateManagment in order
     * @param coreAddress Address of Core.sol contract
     * @param stakingAddress Address of Staking.sol contract
     */
    constructor(
        address coreAddress,
        address stakingAddress
    )
        StakingServiceUtils(stakingAddress)
        CoreExecution(coreAddress)
    {}

    /**
     * @notice Gets unique EVVM instance identifier for signature validation
     * @dev Returns core.getEvvmID(). Prevents cross-chain replays.
     * @return Unique EVVM instance identifier
     */
    function getEvvmID() internal view returns (uint256) {
        return core.getEvvmID();
    }

    /**
     * @notice Gets Principal Token (MATE) address
     * @dev Returns core.getPrincipalTokenAddress(). Used for payment operations.
     * @return Address of Principal Token (MATE)
     */
    function getPrincipalTokenAddress() internal view returns (address) {
        return core.getPrincipalTokenAddress();
    }
}
