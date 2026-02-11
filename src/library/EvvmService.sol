// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EvvmService
 * @author Mate Labs
 * @notice Abstract base contract for building services on the EVVM ecosystem
 * @dev This contract provides a complete foundation for creating EVVM-compatible services.
 * It combines multiple utility contracts to offer:
 *
 * Core Capabilities:
 * - Async nonce management for replay protection (AsyncNonce)
 * - Staking utilities for service-level staking (StakingServiceUtils)
 * - Payment processing through the EVVM core (EvvmPayments)
 * - EIP-191 signature verification for gasless transactions
 *
 * Usage:
 * Inherit from this contract and implement your service logic. All signature
 * verification, payment processing, and nonce management are handled automatically.
 *
 * Example:
 * ```solidity
 * contract MyService is EvvmService {
 *     constructor(address evvm, address staking)
 *         EvvmService(evvm, staking) {}
 *
 *     function myFunction(address user, ..., bytes memory sig) external {
 *      validateAndConsumeNonce(
 *          user,
 *          keccak256(
 *              abi.encodePacked(
 *                  "myFunction",
 *                  <input1>,
 *                  ...,
 *                  <inputN>
 *              )
 *          ),
 *          nonce,
 *          isAsyncExec, // if you want to set as a only async transaction, set this to true.
 *          signature
 *      )
 *         // Your logic here
 *     }
 * }
 * ```
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
    /// @dev Thrown when a signature verification fails for a service operation
    error InvalidServiceSignature();

    /**
     * @notice Initializes the EvvmService with EVVM and Staking contract addresses
     * @param evvmAddress Address of the EVVM core contract for payment processing
     * @param stakingAddress Address of the Staking contract for service staking operations
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
     * @notice Retrieves the unique EVVM instance identifier
     * @dev Used internally for signature verification to ensure signatures are chain-specific
     * @return The unique identifier of the connected EVVM instance
     */
    function getEvvmID() internal view returns (uint256) {
        return evvm.getEvvmID();
    }

    function getPrincipalTokenAddress() internal view returns (address) {
        return evvm.getPrincipalTokenAddress();
    }
}
