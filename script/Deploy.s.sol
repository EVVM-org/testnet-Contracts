// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {BaseInputs} from "../input/BaseInputs.sol";

contract DeployScript is Script, BaseInputs {
    Staking staking;
    Core core;
    Estimator estimator;
    NameService nameService;
    Treasury treasury;
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
        treasury = new Treasury(address(core));
        core.initializeSystemContracts(
            address(nameService),
            address(treasury)
        );
        p2pSwap = new P2PSwap(
            address(core),
            address(staking),
            admin
        );

        vm.stopBroadcast();

        console2.log("Staking deployed at:", address(staking));
        console2.log("Core deployed at:", address(core));
        console2.log("Estimator deployed at:", address(estimator));
        console2.log("NameService deployed at:", address(nameService));
        console2.log("Treasury deployed at:", address(treasury));
        console2.log("P2PSwap deployed at:", address(p2pSwap));
    }
}
