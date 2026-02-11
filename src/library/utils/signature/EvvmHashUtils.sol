// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";

library EvvmHashUtils {

    function hashDataForPay(
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "pay",
                    to_address,
                    to_identity,
                    token,
                    amount,
                    priorityFee,
                    executor
                )
            );
    }

    function hashDataForDispersePay(
        EvvmStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "dispersePay",
                    toData,
                    token,
                    amount,
                    priorityFee,
                    executor
                )
            );
    }
}
