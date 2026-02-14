// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {
    TreasuryHostChainStation
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/TreasuryHostChainStation.sol";
import {
    HostChainStationStructs
} from "@evvm/testnet-contracts/library/structs/HostChainStationStructs.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/library/structs/ExternalChainStationStructs.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {BaseInputs} from "../input/BaseInputs.sol";
import {CrossChainInputs} from "../input/CrossChainInputs.sol";

contract DeployCrossChainHostScript is Script, BaseInputs, CrossChainInputs {
    Staking staking;
    Core core;
    
    Estimator estimator;
    NameService nameService;
    TreasuryHostChainStation treasuryHost;
    P2PSwap p2pSwap;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        staking = new Staking(admin, goldenFisher);
        core = new Core(admin, address(staking), inputMetadata);
        
        estimator = new Estimator(
            activator,
            address(core),
            address(staking),
            admin
        );

        nameService = new NameService(address(core), admin);

        staking.initializeSystemContracts(
            address(estimator),
            address(core)
        );

        treasuryHost = new TreasuryHostChainStation(
            address(core),
            admin,
            crosschainConfigHost
        );

        core.initializeSystemContracts(
            address(nameService),
            address(treasuryHost)
        );

        p2pSwap = new P2PSwap(
            address(core),
            address(staking),
            admin
        );

        vm.stopBroadcast();
    }
}
