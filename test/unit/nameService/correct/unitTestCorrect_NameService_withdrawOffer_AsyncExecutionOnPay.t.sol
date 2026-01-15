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

contract unitTestCorrect_NameService_withdrawOffer_AsyncExecutionOnPay is
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
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    function test__unit_correct__withdrawOffer__nS_nPF() external {
        (
            bytes memory signatureNameService,

        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                0,
                100010001,
                0,
                10000001,
                true
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            0,
            100010001,
            signatureNameService,
            0,
            10000001,
            true,
            ""
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() + (((checkDataBefore.amount * 1) / 796))
        );
    }

    function test__unit_correct__withdrawOffer__nS_PF() external {
        uint256 totalPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                0,
                100010001,
                totalPriorityFee,
                10000001,
                true
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            0,
            100010001,
            signatureNameService,
            totalPriorityFee,
            10000001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() +
                (((checkDataBefore.amount * 1) / 796)) +
                totalPriorityFee
        );
    }

    function test__unit_correct__withdrawOffer__S_nPF() external {
        (
            bytes memory signatureNameService,

        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                0,
                100010001,
                0,
                10000001,
                true
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            0,
            100010001,
            signatureNameService,
            0,
            10000001,
            true,
            ""
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + (((checkDataBefore.amount * 1) / 796))
        );
    }

    function test__unit_correct__withdrawOffer__S_PF() external {
        uint256 totalPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                0,
                100010001,
                totalPriorityFee,
                10000001,
                true
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            0,
            100010001,
            signatureNameService,
            totalPriorityFee,
            10000001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((checkDataBefore.amount * 1) / 796)) +
                totalPriorityFee
        );
    }
}
