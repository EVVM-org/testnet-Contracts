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
 * @title NameServiceHashUtils
 * @author Mate labs
 * @notice Hash generation for NameService.sol operations (registration, marketplace, metadata)
 * @dev Deterministic keccak256 hashes for 10 NameService operations. Used with Core.validateAndConsumeNonce.
 */
library NameServiceHashUtils {
    /**
     * @notice Generates hash for username pre-registration (commit phase)
     * @dev Hash: keccak256("preRegistrationUsername", hashUsername). Prevents front-running, valid 30 minutes.
     * @param hashUsername Keccak256 of (username + lockNumber)
     * @return Hash for Core.sol validation
     */
    function hashDataForPreRegistrationUsername(
        bytes32 hashUsername
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("preRegistrationUsername", hashUsername));
    }

    /**
     * @notice Generates hash for username registration (reveal phase)
     * @dev Hash: keccak256("registrationUsername", username, lockNumber). Must match pre-reg within 30 minutes. Cost: 100x EVVM reward.
     * @param username Username being registered
     * @param lockNumber Random number from pre-registration
     * @return Hash for Core.sol validation
     */
    function hashDataForRegistrationUsername(
        string memory username,
        uint256 lockNumber
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode("registrationUsername", username, lockNumber));
    }

    /**
     * @notice Generates hash for creating marketplace offer
     * @dev Hash: keccak256("makeOffer", username, amount, expirationDate). Locks PT with 0.5% fee.
     * @param username Target username
     * @param amount Principal Tokens offered (pre-fee)
     * @param expirationDate Offer expiration timestamp
     * @return Hash for Core.sol validation
     */
    function hashDataForMakeOffer(
        string memory username,
        uint256 amount,
        uint256 expirationDate
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("makeOffer", username, amount, expirationDate)
            );
    }

    /**
     * @notice Generates hash for withdrawing marketplace offer
     * @dev Hash: keccak256("withdrawOffer", username, offerId). Only offer creator can withdraw.
     * @param username Username with the offer
     * @param offerId Offer ID to withdraw
     * @return Hash for Core.sol validation
     */
    function hashDataForWithdrawOffer(
        string memory username,
        uint256 offerId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("withdrawOffer", username, offerId));
    }

    /**
     * @notice Generates hash for accepting marketplace offer
     * @dev Hash: keccak256("acceptOffer", username, offerId). Transfers ownership to offerer.
     * @param username Username being sold
     * @param offerId Offer ID to accept
     * @return Hash for Core.sol validation
     */
    function hashDataForAcceptOffer(
        string memory username,
        uint256 offerId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("acceptOffer", username, offerId));
    }

    /**
     * @notice Generates hash for renewing username
     * @dev Hash: keccak256("renewUsername", username). Can renew up to 100 years in advance.
     * @param username Username to renew
     * @return Hash for Core.sol validation
     */
    function hashDataForRenewUsername(
        string memory username
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("renewUsername", username));
    }

    /**
     * @notice Generates hash for adding custom metadata
     * @dev Hash: keccak256("addCustomMetadata", identity, value). Cost: 10x EVVM reward.
     * @param identity Username or identity
     * @param value Metadata value to store
     * @return Hash for Core.sol validation
     */
    function hashDataForAddCustomMetadata(
        string memory identity,
        string memory value
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("addCustomMetadata", identity, value));
    }

    /**
     * @notice Generates hash for removing custom metadata
     * @dev Hash: keccak256("removeCustomMetadata", identity, key). Cost: 10x EVVM reward.
     * @param identity Username or identity
     * @param key Metadata entry key to remove
     * @return Hash for Core.sol validation
     */
    function hashDataForRemoveCustomMetadata(
        string memory identity,
        uint256 key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("removeCustomMetadata", identity, key));
    }

    /**
     * @notice Generates hash for flushing all metadata
     * @dev Hash: keccak256("flushCustomMetadata", identity). Removes ALL custom metadata entries.
     * @param identity Username or identity to flush
     * @return Hash for Core.sol validation
     */
    function hashDataForFlushCustomMetadata(
        string memory identity
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("flushCustomMetadata", identity));
    }

    /**
     * @notice Generates hash for flushing username (complete deletion)
     * @dev Hash: keccak256("flushUsername", username). Irreversible. Deletes all data and makes username available.
     * @param username Username to delete
     * @return Hash for Core.sol validation
     */
    function hashDataForFlushUsername(
        string memory username
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode("flushUsername", username));
    }
}
