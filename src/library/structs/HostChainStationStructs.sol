// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title Host Chain Station Data Structures
 * @author Mate labs
 * @notice Data structures for host to external chain bridge
 * @dev Structures for TreasuryHostChainStation: multi-protocol messaging (Hyperlane, LayerZero, Axelar). Independent from State.sol. Core.sol balance management on host only.
 */

library HostChainStationStructs {
    /**
     * @notice Hyperlane protocol configuration
     * @dev Hyperlane cross-chain messaging: domain ID + mailbox. Host → External via mailbox.dispatch.
     * @param externalChainStationDomainId Hyperlane domain for external
     * @param externalChainStationAddress External station (bytes32)
     * @param mailboxAddress Hyperlane mailbox on host chain
     */
    struct HyperlaneConfig {
        uint32 externalChainStationDomainId;
        bytes32 externalChainStationAddress;
        address mailboxAddress;
    }

    /**
     * @notice LayerZero V2 protocol configuration
     * @dev LayerZero V2 omnichain: eid + endpoint. Host → External via endpoint.send. Gas limit 200k.
     * @param externalChainStationEid LayerZero eid for external chain
     * @param externalChainStationAddress External station (bytes32)
     * @param endpointAddress LayerZero V2 endpoint address
     */
    struct LayerZeroConfig {
        uint32 externalChainStationEid;
        bytes32 externalChainStationAddress;
        address endpointAddress;
    }

    /**
     * @notice Axelar protocol configuration
     * @dev Axelar cross-chain: chainName + gateway. Host → External via gateway.callContract.
     * @param externalChainStationChainName Axelar chain name
     * @param externalChainStationAddress External station (string)
     * @param gasServiceAddress Axelar gas service
     * @param gatewayAddress Axelar gateway contract
     */
    struct AxelarConfig {
        string externalChainStationChainName;
        string externalChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    /**
     * @notice Unified deployment configuration
     * @dev Groups all protocol configs: Hyperlane, LayerZero V2, Axelar.
     */
    struct CrosschainConfig {
        HyperlaneConfig hyperlane;
        LayerZeroConfig layerZero;
        AxelarConfig axelar;
    }

    /**
     * @notice Coordinated external chain address change proposal
     * @dev 1-day delay to update external station across all protocols. AddressType for Hyperlane/LZ, StringType for Axelar.
     * @param porposeAddress_AddressType Address for Hyperlane/LZ
     * @param porposeAddress_StringType String for Axelar
     * @param timeToAccept Timestamp when acceptable
     */
    struct ChangeExternalChainAddressParams {
        address porposeAddress_AddressType;
        string porposeAddress_StringType;
        uint256 timeToAccept;
    }
}
