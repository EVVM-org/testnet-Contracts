// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {Math} from "@evvm/testnet-contracts/library/primitives/Math.sol";

library AdvancedStrings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";

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

    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }

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

    function boolToString(bool value) internal pure returns (string memory) {
        return value ? "true" : "false";
    }
}
