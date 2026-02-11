// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title AdvancedStrings
 * @author Mate Labs
 * @notice Library for advanced string manipulation and type conversions
 * @dev Provides utility functions for converting various Solidity types to their string
 * representations. These functions are essential for building EIP-191 signature messages
 * in the EVVM ecosystem.
 *
 * Key Features:
 * - Unsigned integer to string conversion
 * - Address to hexadecimal string conversion
 * - Bytes and bytes32 to hexadecimal string conversion
 * - Boolean to string conversion
 * - String equality comparison
 *
 * All hexadecimal outputs use lowercase letters and include the "0x" prefix where applicable.
 * This library can be used by community-developed services for message construction.
 */

import {Math} from "@evvm/testnet-contracts/library/primitives/Math.sol";

library AdvancedStrings {
    /// @dev Hexadecimal character lookup table for efficient conversion
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    /**
     * @notice Converts an unsigned integer to its decimal string representation
     * @dev Uses assembly for gas-efficient string construction. Works for any uint256 value.
     * @param value The unsigned integer to convert
     * @return The decimal string representation of the value
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @notice Converts an address to its hexadecimal string representation
     * @dev Returns a 42-character string including the "0x" prefix with lowercase hex digits
     * @param _address The address to convert
     * @return The hexadecimal string representation (e.g., "0x1234...abcd")
     */
    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX_DIGITS[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX_DIGITS[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    /**
     * @notice Compares two strings for equality
     * @dev First compares lengths, then compares keccak256 hashes for efficiency
     * @param a First string to compare
     * @param b Second string to compare
     * @return True if both strings are identical, false otherwise
     */
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /**
     * @notice Converts a dynamic bytes array to its hexadecimal string representation
     * @dev Returns a string with "0x" prefix followed by lowercase hex digits.
     *      Empty input returns "0x".
     * @param data The bytes array to convert
     * @return The hexadecimal string representation with "0x" prefix
     */
    function bytesToString(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) {
            return "0x";
        }

        bytes memory result = new bytes(2 + data.length * 2);
        result[0] = "0";
        result[1] = "x";

        for (uint256 i = 0; i < data.length; i++) {
            result[2 + i * 2] = HEX_DIGITS[uint8(data[i] >> 4)];
            result[3 + i * 2] = HEX_DIGITS[uint8(data[i] & 0x0f)];
        }

        return string(result);
    }

    /**
     * @notice Converts a bytes32 value to its hexadecimal string representation
     * @dev Returns a 66-character string ("0x" + 64 hex characters) with lowercase letters
     * @param data The bytes32 value to convert
     * @return The hexadecimal string representation with "0x" prefix
     */
    function bytes32ToString(
        bytes32 data
    ) internal pure returns (string memory) {
        bytes memory result = new bytes(66);
        result[0] = "0";
        result[1] = "x";

        for (uint256 i = 0; i < 32; i++) {
            result[2 + i * 2] = HEX_DIGITS[uint8(data[i] >> 4)];
            result[3 + i * 2] = HEX_DIGITS[uint8(data[i] & 0x0f)];
        }

        return string(result);
    }

    /**
     * @notice Converts a boolean value to its string representation
     * @dev Returns "true" or "false" as lowercase strings
     * @param value The boolean value to convert
     * @return "true" if value is true, "false" otherwise
     */
    function boolToString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }

    function buildSignaturePayload(
        uint256 evvmId,
        address serviceAddress,
        bytes32 hashPayload,
        // address executor,
        uint256 nonce,
        bool isAsyncExec
    ) internal pure returns (string memory) {
        return
            string.concat(
                uintToString(evvmId),
                ",",
                addressToString(serviceAddress),
                ",",
                bytes32ToString(hashPayload),
                ",",
                /**
                addressToString(executor),
                ",",
                 */
                uintToString(nonce),
                ",",
                boolToString(isAsyncExec)
            );
    }


}
