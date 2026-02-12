// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library CAUtils {
    function verifyIfCA(address from) internal view returns (bool) {
        uint256 size;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        return (size != 0);
    }
}
