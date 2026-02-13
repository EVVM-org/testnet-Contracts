// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title External Chain Station Data Structures
 * @author Mate labs
 * @notice Data structures for external to host chain bridge
 * @dev Structures for TreasuryExternalChainStation: multi-protocol messaging (Hyperlane, LayerZero, Axelar). Independent from State.sol/Evvm.sol.
 */
library ExternalChainStationStructs {
    /**
     * @notice Time-delayed address proposal for governance
     * @dev 1-day delay for admin/fisherExecutor changes. Only proposal address can accept.
     * @param current Currently active address
     * @param proposal Proposed new address (1 day delay)
     * @param timeToAccept Timestamp when acceptable
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @notice Hyperlane protocol configuration
     * @dev Hyperlane cross-chain messaging: domain ID + mailbox. External → Host via mailbox.dispatch.
     * @param hostChainStationDomainId Hyperlane domain for host
     * @param hostChainStationAddress Host station (bytes32)
     * @param mailboxAddress Hyperlane mailbox on this chain
     */
    struct HyperlaneConfig {
        uint32 hostChainStationDomainId;
        bytes32 hostChainStationAddress;
        address mailboxAddress;
    }

    /**
     * @notice LayerZero V2 protocol configuration
     * @dev LayerZero V2 omnichain: eid + endpoint. External → Host via endpoint.send. Gas limit 200k.
     * @param hostChainStationEid LayerZero eid for host chain
     * @param hostChainStationAddress Host station (bytes32)
     * @param endpointAddress LayerZero V2 endpoint address
     */
    struct LayerZeroConfig {
        uint32 hostChainStationEid;
        bytes32 hostChainStationAddress;
        address endpointAddress;
    }

    /**
     * @notice Axelar protocol configuration
     * @dev Axelar cross-chain: chainName + gateway. External → Host via gateway.callContract.
     * @param hostChainStationChainName Axelar chain name
     * @param hostChainStationAddress Host station (string)
     * @param gasServiceAddress Axelar gas service
     * @param gatewayAddress Axelar gateway contract
     */
    struct AxelarConfig {
        string hostChainStationChainName;
        string hostChainStationAddress;
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
     * @notice Coordinated host chain address change proposal
     * @dev 1-day delay to update host station across all protocols. AddressType for Hyperlane/LZ, StringType for Axelar.
     * @param porposeAddress_AddressType Address for Hyperlane/LZ
     * @param porposeAddress_StringType String for Axelar
     * @param currentAddress Current host station address
     * @param timeToAccept Timestamp when acceptable
     */
    struct ChangeHostChainAddressParams {
        address porposeAddress_AddressType;
        string porposeAddress_StringType;
        address currentAddress;
        uint256 timeToAccept;
    }
}

