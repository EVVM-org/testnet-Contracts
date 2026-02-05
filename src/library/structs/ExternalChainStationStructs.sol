// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title ExternalChainStationStructs
 * @author Mate labs
 * @notice Shared data structures for External Chain Station cross-chain treasury operations
 * @dev Defines all structural types used by TreasuryExternalChainStation contract
 *      These structures ensure type safety and consistency for cross-chain operations
 *      from external chains to the host chain in the EVVM ecosystem
 */
abstract contract ExternalChainStationStructs {
    /// @notice Time-delayed address change proposal structure for governance
    /// @dev Used for admin and Fisher executor address changes with 1-day delay
    /// @param current Currently active address with full privileges
    /// @param proposal Proposed new address waiting for acceptance
    /// @param timeToAccept Timestamp when the proposal becomes acceptable
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /// @notice Hyperlane protocol configuration for cross-chain messaging
    /// @dev Configuration for reliable cross-chain communication via Hyperlane
    /// @param hostChainStationDomainId Hyperlane domain identifier for the host chain
    /// @param hostChainStationAddress Host chain station address in bytes32 format
    /// @param mailboxAddress Hyperlane mailbox contract address on this chain
    struct HyperlaneConfig {
        uint32 hostChainStationDomainId;
        bytes32 hostChainStationAddress;
        address mailboxAddress;
    }

    /// @notice LayerZero protocol configuration for omnichain messaging
    /// @dev Configuration for omnichain interoperability via LayerZero V2
    /// @param hostChainStationEid LayerZero endpoint identifier for the host chain
    /// @param hostChainStationAddress Host chain station address in bytes32 format
    /// @param endpointAddress LayerZero V2 endpoint contract address on this chain
    struct LayerZeroConfig {
        uint32 hostChainStationEid;
        bytes32 hostChainStationAddress;
        address endpointAddress;
    }

    /// @notice Axelar protocol configuration for cross-chain communication
    /// @dev Configuration for secure cross-chain transfers via Axelar Network
    /// @param hostChainStationChainName Axelar chain identifier for the host chain
    /// @param hostChainStationAddress Host chain station address in string format
    /// @param gasServiceAddress Axelar gas service contract address for fee payments
    /// @param gatewayAddress Axelar gateway contract address for message routing
    struct AxelarConfig {
        string hostChainStationChainName;
        string hostChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    /// @notice Unified cross-chain configuration for all supported protocols
    /// @dev Single structure containing all protocol configurations for deployment
    struct CrosschainConfig {
        HyperlaneConfig hyperlane;
        LayerZeroConfig layerZero;
        AxelarConfig axelar;
    }

    /// @notice Parameters for coordinated host chain address changes across all protocols
    /// @dev Used to propose and execute synchronized address updates with time delay
    /// @param porposeAddress_AddressType Address format for Hyperlane and LayerZero protocols
    /// @param porposeAddress_StringType String format for Axelar protocol compatibility
    /// @param timeToAccept Timestamp when the address change proposal can be executed
    struct ChangeHostChainAddressParams {
        address porposeAddress_AddressType;
        string porposeAddress_StringType;
        uint256 timeToAccept;
    }
}

