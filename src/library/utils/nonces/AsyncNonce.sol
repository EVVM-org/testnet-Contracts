// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title AsyncNonce
 * @author Mate Labs
 * @notice Abstract contract for asynchronous nonce management in EVVM services
 * @dev Provides replay protection using a bitmap-style nonce system where each nonce
 * can be used only once, but nonces can be used in any order (non-sequential).
 *
 * Key Features:
 * - Non-sequential nonce usage (any unused nonce is valid)
 * - Gas-efficient O(1) lookup and marking
 * - Suitable for parallel transaction submission
 *
 * Use Cases:
 * - Services that allow users to submit multiple transactions simultaneously
 * - Operations where transaction ordering is not critical
 * - Batch operations where sequential nonces would be a bottleneck
 *
 * This contract is designed for use by community-developed services that need
 * flexible replay protection without strict ordering requirements.
 */

abstract contract AsyncNonce {
    /// @dev Thrown when attempting to use a nonce that has already been consumed
    error AsyncNonceAlreadyUsed();

    /// @dev Mapping to track used nonces: user address => nonce value => used flag
    mapping(address user => mapping(uint256 nonce => bool availability))
        private asyncNonce;

    /**
     * @notice Marks a nonce as used for a specific user
     * @dev Should be called after successful operation validation to prevent replay
     * @param user Address of the user whose nonce is being marked
     * @param nonce The nonce value to mark as used
     */
    function markAsyncNonceAsUsed(
        address user,
        uint256 nonce
    ) internal virtual {
        asyncNonce[user][nonce] = true;
    }

    /**
     * @notice Verifies that a nonce has not been used yet
     * @dev Reverts with AsyncNonceAlreadyUsed if the nonce was previously consumed
     * @param user Address of the user to check the nonce for
     * @param nonce The nonce value to verify
     * @custom:throws AsyncNonceAlreadyUsed If the nonce has already been used
     */
    function verifyAsyncNonce(
        address user,
        uint256 nonce
    ) internal view virtual {
        if (asyncNonce[user][nonce]) revert AsyncNonceAlreadyUsed();
    }

    /**
     * @notice Checks if a specific nonce has been used by a user
     * @dev Public view function for external queries and UI integration
     * @param user Address of the user to check
     * @param nonce The nonce value to query
     * @return True if the nonce has been used, false if available
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncNonce[user][nonce];
    }
}
