// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EvvmPayments
 * @author Mate Labs
 * @notice Abstract contract providing EVVM payment integration for services
 * @dev This contract provides a standardized interface for interacting with
 * the EVVM core contract for payment operations. It supports:
 *
 * Payment Types:
 * - Single payments (pay): Transfer tokens from a user to the service
 * - Disperse payments (dispersePay): Batch payments from multiple sources
 * - Contract-authorized payments (caPay): Service-initiated token distributions
 * - Disperse CA payments: Batch service-initiated distributions
 *
 * This contract is designed for use by community-developed services that need
 * to process payments through the EVVM ecosystem.
 */

import {IEvvm, EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract EvvmPayments {
    /// @dev Reference to the EVVM core contract for payment operations
    IEvvm internal evvm;

    /**
     * @notice Initializes the EvvmPayments contract with the EVVM address
     * @param evvmAddress Address of the EVVM core contract
     */
    constructor(address evvmAddress) {
        evvm = IEvvm(evvmAddress);
    }

    /**
     * @notice Requests a payment from a user to this contract
     * @dev Calls the EVVM pay function to transfer tokens with signature verification
     * @param from Address of the user making the payment
     * @param token Address of the token being transferred
     * @param amount Amount of tokens to transfer
     * @param priorityFee Additional fee for priority processing
     * @param nonce Nonce for replay protection in EVVM
     * @param isAsyncExec True for async nonce, false for sync nonce in EVVM
     * @param signature EIP-191 signature authorizing the payment
     */
    function requestPay(
        address from,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) internal virtual {
        evvm.pay(
            from,
            address(this),
            "",
            token,
            amount,
            priorityFee,
            address(this),
            nonce,
            isAsyncExec,
            signature
        );
    }

    /**
     * @notice Requests a batch payment from the caller to multiple recipients
     * @dev Calls the EVVM dispersePay function for efficient batch transfers
     * @param toData Array of recipient addresses and amounts
     * @param token Address of the token being transferred
     * @param amount Total amount being transferred (for signature verification)
     * @param priorityFee Additional fee for priority processing
     * @param nonce Nonce for replay protection in EVVM
     * @param isAsyncExec True for async nonce, false for sync nonce in EVVM
     * @param signature EIP-191 signature authorizing the batch payment
     */
    function requestDispersePay(
        EvvmStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) internal virtual {
        evvm.dispersePay(
            address(this),
            toData,
            token,
            amount,
            priorityFee,
            address(this),
            nonce,
            isAsyncExec,
            signature
        );
    }

    /**
     * @notice Sends tokens from this contract to a recipient (contract-authorized)
     * @dev Calls the EVVM caPay function for service-initiated token transfers.
     *      This function does not require user signature as it's authorized by the contract.
     * @param to Address of the recipient
     * @param token Address of the token to transfer
     * @param amount Amount of tokens to transfer
     */
    function makeCaPay(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.caPay(to, token, amount);
    }

    /**
     * @notice Sends tokens from this contract to multiple recipients (batch CA pay)
     * @dev Calls the EVVM disperseCaPay for efficient batch distributions.
     *      This function does not require user signatures.
     * @param toData Array of recipient addresses and amounts
     * @param token Address of the token to transfer
     * @param amount Total amount being distributed
     */
    function makeDisperseCaPay(
        EvvmStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.disperseCaPay(toData, token, amount);
    }

    /**
     * @notice Updates the EVVM contract address
     * @dev Internal function for governance-controlled EVVM address changes.
     *      Should be protected by time-delayed governance in implementing contracts.
     * @param newEvvmAddress Address of the new EVVM contract
     */
    function _changeEvvmAddress(address newEvvmAddress) internal virtual {
        evvm = IEvvm(newEvvmAddress);
    }
}
