// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title SyncNonce
 * @author Mate Labs
 * @notice Abstract contract for synchronous (sequential) nonce management in EVVM services
 * @dev Provides replay protection using a sequential nonce system where nonces must be
 * used in strict ascending order starting from 0.
 *
 * Key Features:
 * - Sequential nonce enforcement (must use nonce N before N+1)
 * - Gas-efficient single uint256 counter per user
 * - Guarantees transaction ordering
 *
 * Use Cases:
 * - Operations requiring strict ordering guarantees
 * - Financial transactions where sequence matters
 * - State-dependent operations that must execute in order
 *
 * Trade-offs:
 * - Cannot submit parallel transactions (must wait for confirmation)
 * - Transaction N+1 cannot be mined before transaction N
 *
 * This contract is designed for use by community-developed services that need
 * strict sequential ordering for their operations.
 */

abstract contract SyncNonce {
    /// @dev Thrown when the provided nonce does not match the expected next nonce
    error SyncNonceMismatch();

    /// @dev Mapping to track the next expected nonce for each user
    mapping(address user => uint256 nonce) private syncNonce;

    /**
     * @notice Increments the nonce counter for a user after successful operation
     * @dev Should be called after operation validation to advance the nonce
     * @param user Address of the user whose nonce counter should be incremented
     */
    function incrementSyncNonce(address user) internal virtual {
        syncNonce[user]++;
    }

    /**
     * @notice Verifies that the provided nonce matches the expected next nonce
     * @dev Reverts with SyncNonceMismatch if the nonce is not the expected value
     * @param user Address of the user to verify the nonce for
     * @param nonce The nonce value to verify
     * @custom:throws SyncNonceMismatch If nonce does not match the expected value
     */
    function verifySyncNonce(
        address user,
        uint256 nonce
    ) internal view virtual {
        if (syncNonce[user] != nonce) revert SyncNonceMismatch();
    }

    /**
     * @notice Gets the current (next expected) nonce for a user
     * @dev Public view function for external queries and transaction preparation
     * @param user Address of the user to query
     * @return The next nonce value that must be used by the user
     */
    function getNextCurrentSyncNonce(
        address user
    ) public view virtual returns (uint256) {
        return syncNonce[user];
    }
}
