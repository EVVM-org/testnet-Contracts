// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    SignatureUtil
} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

/**
 * @title SignatureUtils
 * @author Mate labs
 * @notice Library for EIP-191 signature verification exclusively for NameService.sol operations
 * @dev This library provides signature verification utilities for all NameService.sol operations,
 *      including username registration, marketplace offers, custom metadata management, and
 *      administrative functions. It constructs deterministic message formats and validates signatures.
 *
 * Signature Verification:
 * - Uses EIP-191 standard for message signing and verification
 * - Constructs deterministic message strings from operation parameters
 * - Integrates with SignatureUtil for cryptographic verification
 * - Prevents replay attacks through nonce inclusion
 * - Supports cross-chain safety through EvvmID inclusion
 *
 * Operation Types:
 * - Registration: preRegistrationUsername, registrationUsername
 * - Marketplace: makeOffer, withdrawOffer, acceptOffer
 * - Renewal: renewUsername
 * - Metadata: addCustomMetadata, removeCustomMetadata, flushCustomMetadata
 * - Management: flushUsername
 *
 * @custom:scope Exclusive to NameService.sol operations
 * @custom:standard EIP-191 (https://eips.ethereum.org/EIPS/eip-191)
 * @custom:security All signatures include EvvmID to prevent cross-chain replay attacks
 */
library SignatureUtils {

    /**
     * @notice Verifies EIP-191 signature for username pre-registration operations
     * @dev Constructs message from hash and nonce, verifies against signer
     *
     * Message Format: "[hashUsername],[nameServiceNonce]"
     * Used in: preRegistrationUsername function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (user pre-registering)
     * @param hashUsername Keccak256 hash of username + random number for commitment
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForPreRegistrationUsername(
        uint256 evvmID,
        address signer,
        bytes32 hashUsername,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "preRegistrationUsername",
                string.concat(
                    AdvancedStrings.bytes32ToString(hashUsername),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for username registration operations
     * @dev Constructs message from username, random number, and nonce
     *
     * Message Format: "[username],[clowNumber],[nameServiceNonce]"
     * Used in: registrationUsername function
     * Reveals the username from pre-registration commitment
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (user registering)
     * @param username The actual username being registered
     * @param clowNumber Random number used in pre-registration hash
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForRegistrationUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 clowNumber,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "registrationUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(clowNumber),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for creating marketplace offers
     * @dev Constructs message from username, expiration, amount, and nonce
     *
     * Message Format: "[username],[dateExpire],[amount],[nameServiceNonce]"
     * Used in: makeOffer function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (offerer)
     * @param username Target username for the offer
     * @param dateExpire Timestamp when the offer expires
     * @param amount Amount being offered in Principal Tokens
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForMakeOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 dateExpire,
        uint256 amount,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "makeOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(dateExpire),
                    ",",
                    AdvancedStrings.uintToString(amount),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for withdrawing marketplace offers
     * @dev Constructs message from username, offer ID, and nonce
     *
     * Message Format: "[username],[offerId],[nameServiceNonce]"
     * Used in: withdrawOffer function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (offerer withdrawing)
     * @param username Username the offer was made for
     * @param offerId Unique identifier of the offer to withdraw
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForWithdrawOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 offerId,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "withdrawOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(offerId),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for accepting marketplace offers
     * @dev Constructs message from username, offer ID, and nonce
     *
     * Message Format: "[username],[offerId],[nameServiceNonce]"
     * Used in: acceptOffer function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (username owner accepting)
     * @param username Username being sold
     * @param offerId Unique identifier of the offer to accept
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForAcceptOffer(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 offerId,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "acceptOffer",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(offerId),
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for username renewal operations
     * @dev Constructs message from username and nonce
     *
     * Message Format: "[username],[nameServiceNonce]"
     * Used in: renewUsername function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (username owner)
     * @param username Username to renew
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForRenewUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "renewUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for adding custom metadata to identity
     * @dev Constructs message from identity, metadata value, and nonce
     *
     * Message Format: "[identity],[value],[nameServiceNonce]"
     * Used in: addCustomMetadata function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (identity owner)
     * @param identity Username/identity to add metadata to
     * @param value Metadata value in format: [schema]:[subschema]>[value]
     * @param nameServiceNonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory identity,
        string memory value,
        uint256 nameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "addCustomMetadata",
                string.concat(
                    identity,
                    ",",
                    value,
                    ",",
                    AdvancedStrings.uintToString(nameServiceNonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for removing custom metadata from username
     * @dev Constructs message from username, metadata key, and nonce
     *
     * Message Format: "[username],[key],[nonce]"
     * Used in: removeCustomMetadata function
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (username owner)
     * @param username Username to remove metadata from
     * @param key Index of the metadata entry to remove
     * @param nonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 key,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "removeCustomMetadata",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(key),
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for flushing all custom metadata from identity
     * @dev Constructs message from identity and nonce
     *
     * Message Format: "[identity],[nonce]"
     * Used in: flushCustomMetadata function
     * Removes all custom metadata entries at once
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (identity owner)
     * @param identity Username/identity to flush metadata from
     * @param nonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        address signer,
        string memory identity,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "flushCustomMetadata",
                string.concat(
                    identity,
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }

    /**
     * @notice Verifies EIP-191 signature for flushing/deleting a username entirely
     * @dev Constructs message from username and nonce
     *
     * Message Format: "[username],[nonce]"
     * Used in: flushUsername function
     * Permanently removes username and all associated data
     *
     * @param evvmID Unique identifier of the EVVM instance for cross-chain safety
     * @param signer Address that signed the message (username owner)
     * @param username Username to flush/delete
     * @param nonce Transaction nonce for replay protection
     * @param signature EIP-191 signature from the signer
     * @return bool True if the signature is valid and matches the signer
     */
    function verifyMessageSignedForFlushUsername(
        uint256 evvmID,
        address signer,
        string memory username,
        uint256 nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureUtil.verifySignature(
                evvmID,
                "flushUsername",
                string.concat(
                    username,
                    ",",
                    AdvancedStrings.uintToString(nonce)
                ),
                signature,
                signer
            );
    }
}
