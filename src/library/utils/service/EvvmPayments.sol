// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EVVM Payment Integration for Services
 * @author Mate labs
 * @notice Abstract contract providing Evvm.sol payment processing interface
 * @dev Four payment types: requestPay (user-to-service with signature), requestDispersePay (batch user-to-service),  makeCaPay (contract-authorized service-to-user), makeDisperseCaPay (batch CA).
 */

import {IEvvm, EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract EvvmPayments {
    /// @notice EVVM core contract reference
    /// @dev Used for all payment operations
    IEvvm internal evvm;

    /**
     * @notice Initializes EVVM payment integration
     * @param evvmAddress Address of Evvm.sol contract
     */
    constructor(address evvmAddress) {
        evvm = IEvvm(evvmAddress);
    }

    /**
     * @notice Requests payment from user to service via Evvm.pay with signature validation
     * @dev Calls evvm.pay(from, address(this), "", ...). Signature validated by State.validateAndConsumeNonce.
     * @param from User paying (signer)
     * @param token Token address
     * @param amount Token amount
     * @param priorityFee Executor fee
     * @param nonce Sequential or async nonce
     * @param isAsyncExec Nonce type (true=async, false=sync)
     * @param signature User's ECDSA signature
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
     * @notice Requests batch payment from user via Evvm.dispersePay
     * @dev Signature validated by State.sol. Total amount must match sum of toData amounts.
     * @param toData Array of (recipient, amount) pairs
     * @param token Token address
     * @param amount Total amount (must match sum)
     * @param priorityFee Executor fee
     * @param nonce Sequential or async nonce
     * @param isAsyncExec Nonce type (true=async, false=sync)
     * @param signature User's ECDSA signature
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
     * @notice Sends tokens from service to recipient via contract authorization (no signature)
     * @dev Calls evvm.caPay(to, token, amount). Service must have sufficient Evvm balance.
     * @param to Recipient address
     * @param token Token address
     * @param amount Token amount
     */
    function makeCaPay(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.caPay(to, token, amount);
    }

    /**
     * @notice Sends tokens to multiple recipients via contract authorization (batch)
     * @dev Calls evvm.disperseCaPay. Total amount must match sum of toData amounts.
     * @param toData Array of (recipient, amount) pairs
     * @param token Token address
     * @param amount Total amount (must match sum)
     */
    function makeDisperseCaPay(
        EvvmStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.disperseCaPay(toData, token, amount);
    }

    /**
     * @notice Updates Evvm.sol contract address for governance-controlled upgrades
     * @dev Should be protected with onlyAdmin and time-delay (ProposalStructs pattern recommended).
     * @param newEvvmAddress New Evvm.sol contract address
     */
    function _changeEvvmAddress(address newEvvmAddress) internal virtual {
        evvm = IEvvm(newEvvmAddress);
    }
}
