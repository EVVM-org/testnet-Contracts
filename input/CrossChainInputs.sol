// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";
import {
    HostChainStationStructs
} from "@evvm/testnet-contracts/library/structs/HostChainStationStructs.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/library/structs/ExternalChainStationStructs.sol";

abstract contract CrossChainInputs {
    address constant adminExternal = 0x0000000000000000000000000000000000000000;

    HostChainStationStructs.CrosschainConfig crosschainConfigHost =
        HostChainStationStructs.CrosschainConfig({
            hyperlane: HostChainStationStructs.HyperlaneConfig({
                externalChainStationDomainId: 0, //Domain ID for External on Hyperlane
                externalChainStationAddress: bytes32(0), //External Chain Station Address on Hyperlane
                mailboxAddress: 0x0000000000000000000000000000000000000000 //Mailbox for Host on Hyperlane
            }),
            layerZero: HostChainStationStructs.LayerZeroConfig({
                externalChainStationEid: 0, //EID for External on LayerZero
                externalChainStationAddress: bytes32(0), //External Chain Station Address on LayerZero
                endpointAddress: 0x0000000000000000000000000000000000000000 //Endpoint for Host on LayerZero
            }),
            axelar: HostChainStationStructs.AxelarConfig({
                externalChainStationChainName: "", //Chain Name for External on Axelar
                externalChainStationAddress: "", //External Chain Station Address on Axelar
                gasServiceAddress: 0x0000000000000000000000000000000000000000, //Gas Service for External on Axelar
                gatewayAddress: 0x0000000000000000000000000000000000000000 //Gateway for Host on Axelar
            })
        });

    ExternalChainStationStructs.CrosschainConfig crosschainConfigExternal =
        ExternalChainStationStructs.CrosschainConfig({
            hyperlane: ExternalChainStationStructs.HyperlaneConfig({
                hostChainStationDomainId: 0, //Domain ID for Host on Hyperlane
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on Hyperlane
                mailboxAddress: 0x0000000000000000000000000000000000000000 //Mailbox for External on Hyperlane
            }),
            layerZero: ExternalChainStationStructs.LayerZeroConfig({
                hostChainStationEid: 0, //EID for Host on LayerZero
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on LayerZero
                endpointAddress: 0x0000000000000000000000000000000000000000 //Endpoint for External on LayerZero
            }),
            axelar: ExternalChainStationStructs.AxelarConfig({
                hostChainStationChainName: "", //Chain Name for Host on Axelar
                hostChainStationAddress: "", //Host Chain Station Address on Axelar
                gasServiceAddress: 0x0000000000000000000000000000000000000000, //Gas Service for External on Axelar
                gatewayAddress: 0x0000000000000000000000000000000000000000 //Gateway for External on Axelar
            })
        });
}
