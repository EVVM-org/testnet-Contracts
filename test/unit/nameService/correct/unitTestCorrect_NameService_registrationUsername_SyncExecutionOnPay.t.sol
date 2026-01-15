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

contract unitTestCorrect_NameService_registrationUsername_SyncExecutionOnPay is
    Test,
    Constants
{
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function addBalance(
        address user,
        string memory username,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 registrationPrice, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username) + priorityFeeAmount
        );

        registrationPrice = nameService.getPriceOfRegistration(username);
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    modifier preparePostRegistrationAndFlush() {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "testflush", 0);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testflush",
            777,
            1
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                777,
                2,
                0,
                2,
                true
            );

        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            777,
            2,
            signatureNameService,
            0,
            2,
            true,
            signatureEVVM
        );

        evvm.addBalance(
            COMMON_USER_NO_STAKER_2.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            1.67 ether
        );

        (
            signatureNameService,
            signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "testflush",
                block.timestamp + 30 days,
                1.67 ether,
                3,
                0,
                3,
                true
            );

        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "testflush",
            block.timestamp + 30 days,
            1.67 ether,
            3,
            signatureNameService,
            0,
            3,
            true,
            signatureEVVM
        );

        evvm.addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername("testflush")
        );

        (
            signatureNameService,
            signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                4,
                0,
                4,
                true
            );

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            4,
            signatureNameService,
            0,
            4,
            true,
            signatureEVVM
        );
        _;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    function test__unit_correct__registrationUsername__noFlush__nS_nPF()
        external
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                20202,
                0,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            20202,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
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

    function test__unit_correct__registrationUsername__noFlush__nS_PF()
        external
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                20202,
                0.001 ether,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            20202,
            signatureNameService,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
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

    function test__unit_correct__registrationUsername__noFlush__S_nPF()
        external
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                20202,
                0,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            20202,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() * 50
        );
    }

    function test__unit_correct__registrationUsername__noFlush__S_PF()
        external
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                20202,
                0.001 ether,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            20202,
            signatureNameService,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 50) + 0.001 ether
        );
    }

    ////////////////////////////////////////////////////////

    function test__unit_correct__registrationUsername__Flush__nS_nPF()
        external
        preparePostRegistrationAndFlush
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "testflush", 0);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testflush",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                777,
                20202,
                0,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            777,
            20202,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("testflush");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
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

    function test__unit_correct__registrationUsername__Flush__nS_PF()
        external
        preparePostRegistrationAndFlush
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "testflush", 0.001 ether);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testflush",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                777,
                20202,
                0.001 ether,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            777,
            20202,
            signatureNameService,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("testflush");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
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

    function test__unit_correct__registrationUsername__Flush__S_nPF()
        external
        preparePostRegistrationAndFlush
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "testflush", 0);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testflush",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                777,
                20202,
                0,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            777,
            20202,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("testflush");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() * 50
        );
    }

    function test__unit_correct__registrationUsername__Flush__S_PF()
        external
        preparePostRegistrationAndFlush
    {
        addBalance(COMMON_USER_NO_STAKER_1.Address, "testflush", 0.001 ether);
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testflush",
            777,
            10101
        );

        skip(30 minutes);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "testflush",
                777,
                20202,
                0.001 ether,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "testflush",
            777,
            20202,
            signatureNameService,
            0.001 ether,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("testflush");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);
        assertEq(expirationDate, block.timestamp + 366 days);
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 50) + 0.001 ether
        );
    }
}
