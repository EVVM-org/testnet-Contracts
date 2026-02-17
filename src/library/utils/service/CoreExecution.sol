// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title EVVM Payment Integration for Services
 * @author Mate labs
 * @notice Abstract contract providing Core.sol payment processing interface
 * @dev Four payment types: requestPay (user-to-service with signature), requestDispersePay (batch user-to-service),  makeCaPay (contract-authorized service-to-user), makeDisperseCaPay (batch CA).
 */

import {ICore, CoreStructs} from "@evvm/testnet-contracts/interfaces/ICore.sol";

abstract contract CoreExecution {
    /// @notice EVVM core contract reference
    /// @dev Used for all payment operations
    ICore internal core;

    /**
     * @notice Initializes EVVM payment integration
     * @param _coreAddress Address of Core.sol contract
     */
    constructor(address _coreAddress) {
        core = ICore(_coreAddress);
    }

    /**
     * @notice Requests payment from user to service via Evvm.pay with signature validation
     * @dev Calls core.pay(from, address(this), "", ...). Signature validated by State.validateAndConsumeNonce.
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
        core.pay(
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
     * @dev Signature validated by Core.sol. Total amount must match sum of toData amounts.
     * @param toData Array of (recipient, amount) pairs
     * @param token Token address
     * @param amount Total amount (must match sum)
     * @param priorityFee Executor fee
     * @param nonce Sequential or async nonce
     * @param isAsyncExec Nonce type (true=async, false=sync)
     * @param signature User's ECDSA signature
     */
    function requestDispersePay(
        CoreStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature
    ) internal virtual {
        core.dispersePay(
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
     * @dev Calls core.caPay(to, token, amount). Service must have sufficient Evvm balance.
     * @param to Recipient address
     * @param token Token address
     * @param amount Token amount
     */
    function makeCaPay(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        core.caPay(to, token, amount);
    }

    /**
     * @notice Sends tokens to multiple recipients via contract authorization (batch)
     * @dev Calls evvm.disperseCaPay. Total amount must match sum of toData amounts.
     * @param toData Array of (recipient, amount) pairs
     * @param token Token address
     * @param amount Total amount (must match sum)
     */
    function makeDisperseCaPay(
        CoreStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) internal virtual {
        core.disperseCaPay(toData, token, amount);
    }

    /**
     * @notice Reserves async nonce for user and this service exclusively
     * @dev Calls core.reserveAsyncNonce(user, nonce, address(this)). Nonce can be revoked before use.
     * @param nonce Async nonce number to reserve
     */
    function reserveAsyncNonceToService(uint256 nonce) external {
        core.reserveAsyncNonce(nonce, address(this));
    }

    /**
     * @notice Revokes reserved async nonce before use
     * @dev Calls core.revokeAsyncNonce(user, nonce). Cannot revoke consumed nonces.
     * @param user User address that reserved nonce
     * @param nonce Async nonce number to revoke
     */
    function revokeAsyncNonceToService(address user, uint256 nonce) external {
        core.revokeAsyncNonce(user, nonce);
    }

    /**
     * @notice Gets next sequential sync nonce for user
     * @dev View function returning core.getNextCurrentSyncNonce(user). Auto-increments after each use.
     * @param user User address to query
     * @return Next sync nonce for user
     */
    function getNextCurrentSyncNonce(
        address user
    ) external view returns (uint256) {
        return core.getNextCurrentSyncNonce(user);
    }

    /**
     * @notice Checks if async nonce was consumed
     * @dev View function returning core.getIfUsedAsyncNonce(user, nonce). Reserved nonces return false until consumed.
     * @param user User address to query
     * @param nonce Async nonce to check
     * @return true if consumed, false if available/reserved
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return core.getIfUsedAsyncNonce(user, nonce);
    }

    /**
     * @notice Updates Core.sol contract address for governance-controlled upgrades
     * @dev Should be protected with onlyAdmin and time-delay (ProposalStructs pattern recommended).
     * @param newCoreAddress New Core.sol contract address
     */
    function _changeCoreAddress(address newCoreAddress) internal virtual {
        core = ICore(newCoreAddress);
    }
}
