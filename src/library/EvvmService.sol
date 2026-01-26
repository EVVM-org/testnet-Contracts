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
 *         validateServiceSignature("myFunction", "...", sig, user);
 *         // Your logic here
 *     }
 * }
 * ```
 */

import {EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {SignatureUtil} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {AsyncNonce} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";
import {StakingServiceUtils} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {EvvmPayments} from "@evvm/testnet-contracts/library/utils/service/EvvmPayments.sol";

abstract contract EvvmService is
    AsyncNonce,
    StakingServiceUtils,
    EvvmPayments
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
        address stakingAddress
    ) StakingServiceUtils(stakingAddress) EvvmPayments(evvmAddress) {}

    /**
     * @notice Validates an EIP-191 signature for a service operation
     * @dev Verifies that the signature was created by the expected signer using the EVVM ID,
     *      function name, and inputs as the signed message
     * @param functionName Name of the function being called (used in signature message)
     * @param inputs Comma-separated string of function inputs (used in signature message)
     * @param signature The EIP-191 signature to verify
     * @param expectedSigner Address that should have signed the message
     * @custom:throws InvalidServiceSignature If signature verification fails
     */
    function validateServiceSignature(
        string memory functionName,
        string memory inputs,
        bytes memory signature,
        address expectedSigner
    ) internal view virtual {
        if (
            !SignatureUtil.verifySignature(
                evvm.getEvvmID(),
                functionName,
                inputs,
                signature,
                expectedSigner
            )
        ) revert InvalidServiceSignature();
    }

    /**
     * @notice Retrieves the unique EVVM instance identifier
     * @dev Used internally for signature verification to ensure signatures are chain-specific
     * @return The unique identifier of the connected EVVM instance
     */
    function getEvvmID() internal view returns (uint256) {
        return evvm.getEvvmID();
    }
}
