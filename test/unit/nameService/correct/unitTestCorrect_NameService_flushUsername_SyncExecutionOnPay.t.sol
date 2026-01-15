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

contract unitTestCorrect_NameService_flushUsername_SyncExecutionOnPay is
    Test,
    Constants
{
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101,
            20202
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>1",
            11,
            11,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>2",
            22,
            22,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>3",
            33,
            33,
            true
        );
    }

    function addBalance(
        AccountData memory user,
        string memory usernameToFlushCustomMetadata,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername(usernameToFlushCustomMetadata) +
                priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushUsername(
            usernameToFlushCustomMetadata
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

    function test__unit_correct__flushUsername__nS_nPF() external {
        (, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, address(0));
        assertEq(expireDate, 0);

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
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }

    function test__unit_correct__flushUsername__nS_PF() external {
        (, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, address(0));
        assertEq(expireDate, 0);

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
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }

    function test__unit_correct__flushUsername__S_nPF() external {
        (, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, address(0));
        assertEq(expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }

    function test__unit_correct__flushUsername__S_PF() external {
        (, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                110010011,
                totalPriorityFeeAmount,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            110010011,
            signatureNameService,
            totalPriorityFeeAmount,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, address(0));
        assertEq(expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }
}
