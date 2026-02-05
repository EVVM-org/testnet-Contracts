// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Staking
} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";
import {
    TreasuryHostChainStation
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/TreasuryHostChainStation.sol";
import {
    HostChainStationStructs
} from "@evvm/testnet-contracts/library/structs/HostChainStationStructs.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/library/structs/ExternalChainStationStructs.sol";
import {
    P2PSwap
} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {BaseInputs} from "../input/BaseInputs.sol";
import {CrossChainInputs} from "../input/CrossChainInputs.sol";

contract DeployCrossChainHostScript is Script, BaseInputs, CrossChainInputs {
    Staking staking;
    Evvm evvm;
    Estimator estimator;
    NameService nameService;
    TreasuryHostChainStation treasuryHost;
    P2PSwap p2pSwap;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        staking = new Staking(admin, goldenFisher);
        evvm = new Evvm(admin, address(staking), inputMetadata);
        estimator = new Estimator(
            activator,
            address(evvm),
            address(staking),
            admin
        );

        nameService = new NameService(address(evvm), admin);

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));

        treasuryHost = new TreasuryHostChainStation(
            address(evvm),
            admin,
            crosschainConfigHost
        );

        
        evvm._setupNameServiceAndTreasuryAddress(
            address(nameService),
            address(treasuryHost)
        );

        p2pSwap = new P2PSwap(
            address(evvm),
            address(staking),
            admin
        );

        vm.stopBroadcast();
    }
}
