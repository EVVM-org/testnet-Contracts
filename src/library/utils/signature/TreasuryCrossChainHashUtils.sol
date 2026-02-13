// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

/**
 * @title Cross-Chain Treasury Hash Utilities
 * @author Mate labs
 * @notice Hash generation for Fisher bridge operations (independent from EVVM)
 * @dev EIP-191 hashes for cross-chain bridge. Uses own nonce system (NOT State.sol). Signature validation via SignatureRecover.
 */

library TreasuryCrossChainHashUtils {
    /**
     * @notice Generates hash for Fisher bridge operation
     * @dev Hash: keccak256("fisherBridge", addressToReceive, tokenAddress, amount, priorityFee). Independent nonce system (NOT State.sol).
     * @param addressToReceive Recipient on destination chain
     * @param tokenAddress Token to bridge (address(0) = ETH)
     * @param priorityFee Fee for Fisher executor
     * @param amount Token amount to bridge
     * @return Hash for ECDSA signature validation
     */
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
