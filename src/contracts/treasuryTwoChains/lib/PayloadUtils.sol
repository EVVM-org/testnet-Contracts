// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

/**
 * @title PayloadUtils Library
 * @author Mate labs
 * @notice Utility library for encoding/decoding cross-chain transfer payloads
 * @dev Standardized payload format (ABI encoding) for TreasuryHostChainStation and TreasuryExternalChainStation. Used across Hyperlane, LayerZero, Axelar.
 */
library PayloadUtils {
    /// @notice Encodes transfer data into a standardized cross-chain payload
    /// @dev Uses ABI encoding for reliable cross-chain data transmission
    /// @param token Token contract address (address(0) for native ETH)
    /// @param toAddress Recipient address on the destination chain
    /// @param amount Amount of tokens to transfer (in token's native decimals)
    /// @return payload Encoded bytes containing the transfer parameters
    function encodePayload(
        address token,
        address toAddress,
        uint256 amount
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(token, toAddress, amount);
    }

    /// @notice Decodes a cross-chain payload back into transfer parameters
    /// @dev Uses ABI decoding to extract the original transfer data safely
    /// @param payload Encoded bytes received from cross-chain protocols
    /// @return token Token contract address (address(0) indicates native ETH)
    /// @return toAddress Recipient address extracted from the payload
    /// @return amount Amount of tokens to transfer in token's native decimals
    function decodePayload(
        bytes memory payload
    ) internal pure returns (address token, address toAddress, uint256 amount) {
        (token, toAddress, amount) = abi.decode(
            payload,
            (address, address, uint256)
        );
    }
}
