// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title AdvancedStrings
 * @author Mate Labs
 * @notice Type conversion library for EIP-191 signature payload construction
 * @dev Converts uint256, address, bytes, bytes32, bool to strings. Hexadecimal output uses lowercase with "0x" prefix.
 */

import {Math} from "@evvm/testnet-contracts/library/primitives/Math.sol";

library AdvancedStrings {
    /// @dev Hexadecimal character lookup table for efficient conversion
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    /**
     * @notice Converts uint256 to decimal string
     * @dev Uses assembly for gas-efficient construction
     * @param value Unsigned integer to convert
     * @return Decimal string representation
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
     * @notice Converts address to hex string with "0x" prefix
     * @param _address Address to convert
     * @return 42-character lowercase hex string
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
     * @dev Compares lengths then keccak256 hashes
     * @param a First string
     * @param b Second string
     * @return True if identical
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
     * @notice Converts bytes array to hex string
     * @dev Returns "0x" for empty input
     * @param data Bytes array to convert
     * @return Hex string with "0x" prefix
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
     * @notice Converts bytes32 to hex string
     * @param data Bytes32 value to convert
     * @return 66-character hex string with "0x" prefix
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
     * @notice Converts boolean to string ("true"/"false")
     * @param value Boolean to convert
     * @return Lowercase string representation
     */
    function boolToString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }

    /**
     * @notice Builds EIP-191 signature payload for State.sol validation
     * @dev Format: "{evvmId},{serviceAddress},{hashPayload},{nonce},{isAsyncExec}"
     * @param evvmId Chain-specific EVVM instance identifier
     * @param serviceAddress Service contract requesting validation
     * @param hashPayload Function-specific parameter hash
     * @param nonce Sequential or async nonce
     * @param isAsyncExec Nonce type (true=async, false=sync)
     * @return Comma-separated payload string for signature
     */
    function buildSignaturePayload(
        uint256 evvmId,
        address serviceAddress,
        bytes32 hashPayload,
        address executor,
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
                addressToString(executor),
                ",",
                uintToString(nonce),
                ",",
                boolToString(isAsyncExec)
            );
    }
}
