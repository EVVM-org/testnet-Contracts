// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";

abstract contract BaseInputs {
    address admin = 0x0000000000000000000000000000000000000000;
    address goldenFisher = 0x0000000000000000000000000000000000000000;
    address activator = 0x0000000000000000000000000000000000000000;

    EvvmStructs.EvvmMetadata inputMetadata =
        EvvmStructs.EvvmMetadata({
            EvvmName: "EVVM",
            // evvmID will be set to 0, and it will be assigned when you register the evvm
            EvvmID: 0,
            principalTokenName: "Mate Token",
            principalTokenSymbol: "MATE",
            principalTokenAddress: 0x0000000000000000000000000000000000000001,
            totalSupply: 2033333333000000000000000000,
            eraTokens: 1016666666500000000000000000,
            reward: 5000000000000000000
        });
}
