// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";

/**
 * @title EVVM Core Hash Utilities
 * @author Mate labs
 * @notice Generates deterministic hashes for Core contract payment operations.
 * @dev Reconstructs data payloads for EIP-191 signature verification within the EVVM ecosystem.
 */
library CoreHashUtils {

    /**
     * @notice Generates hash for single payment operation
     * @dev Hash: keccak256("pay", to_address, to_identity, token, amount, priorityFee, executor)
     * @param to_address Direct recipient address
     * @param to_identity Username for NameService resolution
     * @param token Token address
     * @param amount Token amount
     * @param priorityFee Fee for executor
     * @return Hash for State.sol validation
     */
    function hashDataForPay(
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "pay",
                    to_address,
                    to_identity,
                    token,
                    amount,
                    priorityFee
                )
            );
    }

    /**
     * @notice Generates hash for batch payment operation
     * @dev Hash: keccak256("dispersePay", toData, token, amount, priorityFee, executor). Single nonce for entire batch.
     * @param toData Array of recipients and amounts
     * @param token Token address
     * @param amount Total amount (must equal sum)
     * @param priorityFee Fee for executor
     * @return Hash for State.sol validation
     */
    function hashDataForDispersePay(
        CoreStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "dispersePay",
                    toData,
                    token,
                    amount,
                    priorityFee
                )
            );
    }
}
