// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM functions
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_NameService_addCustomMetadata_SyncExecutionOnPay is
    Test,
    Constants
{
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;


    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2)
        );
    }


    function addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    function test__unit_correct__addCustomMetadata__nS_nPF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                "test>1",
                100010001,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            "test>1",
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 0);

        assert(
            bytes(customMetadata).length == bytes("test>1").length &&
                keccak256(bytes(customMetadata)) == keccak256(bytes("test>1"))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 1);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }

    function test__unit_correct__addCustomMetadata__nS_PF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                "test>1",
                100010001,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            "test>1",
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 0);

        assert(
            bytes(customMetadata).length == bytes("test>1").length &&
                keccak256(bytes(customMetadata)) == keccak256(bytes("test>1"))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 1);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }

    function test__unit_correct__addCustomMetadata__S_nPF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                "test>1",
                100010001,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            "test>1",
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 0);

        assert(
            bytes(customMetadata).length == bytes("test>1").length &&
                keccak256(bytes(customMetadata)) == keccak256(bytes("test>1"))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 1);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (5 * evvm.getRewardAmount()) +
                ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
                totalPriorityFeeAmount
        );
    }

    function test__unit_correct__addCustomMetadata__S_PF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                "test>1",
                100010001,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            "test>1",
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 0);

        assert(
            bytes(customMetadata).length == bytes("test>1").length &&
                keccak256(bytes(customMetadata)) == keccak256(bytes("test>1"))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 1);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (5 * evvm.getRewardAmount()) +
                ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
                totalPriorityFeeAmount
        );
    }
}
