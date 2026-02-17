// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title Contract Address Verification Utilities
 * @author Mate labs
 * @notice Utilities for detecting contract addresses vs EOAs
 * @dev Uses extcodesize opcode. Returns false during contract construction and after self-destruct.
 */
library CAUtils {
    /**
     * @notice Checks if address is a contract using extcodesize
     * @dev Returns false during construction and after self-destruct. Not reliable as sole security check.
     * @param from Address to check
     * @return true if contract (codesize > 0), false if EOA
     */
    function verifyIfCA(address from) internal view returns (bool) {
        uint256 size;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        return (size != 0);
    }
}
