// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;


library TreasuryCrossChainHashUtils {
    function hashDataForFisherBridge(
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    "fisherBridge",
                    addressToReceive,
                    tokenAddress,
                    amount,
                    priorityFee
                )
            );
    }
            
}
