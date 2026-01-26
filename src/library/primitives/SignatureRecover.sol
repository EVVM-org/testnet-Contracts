// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title SignatureRecover
 * @author Mate Labs
 * @notice Library for recovering signer addresses from EIP-191 signed messages
 * @dev Provides utilities for signature verification following the EIP-191 standard.
 * This library is used throughout the EVVM ecosystem for gasless transaction validation.
 *
 * EIP-191 Format:
 * The signed message follows the format:
 * "\x19Ethereum Signed Message:\n" + message.length + message
 *
 * This library can be used by community-developed services to implement
 * signature verification compatible with the EVVM ecosystem.
 */

import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library SignatureRecover {

    /**
     * @notice Recovers the signer address from an EIP-191 signed message
     * @dev Uses ecrecover to extract the signer address from the signature components.
     *      The message is hashed with the EIP-191 prefix before recovery.
     * @param message The original message that was signed (without prefix)
     * @param signature 65-byte signature in the format (r, s, v)
     * @return The address that signed the message, or address(0) if invalid
     */
    function recoverSigner(
        string memory message,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                AdvancedStrings.uintToString(bytes(message).length),
                message
            )
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    /**
     * @notice Splits a 65-byte signature into its r, s, and v components
     * @dev Extracts signature components using assembly for gas efficiency.
     *      Handles both pre-EIP-155 and post-EIP-155 signature formats.
     * @param signature 65-byte signature to split
     * @return r First 32 bytes of the signature
     * @return s Second 32 bytes of the signature
     * @return v Recovery identifier (27 or 28)
     * @custom:throws "Invalid signature length" if signature is not 65 bytes
     * @custom:throws "Invalid signature value" if v is not 27 or 28
     */
    function splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Ensure signature is valid
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature value");
    }
}
