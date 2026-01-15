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

contract unitTestCorrect_NameService_makeOffer_AsyncExecutionOnPay is
    Test,
    Constants
{
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2)
        );
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    function addBalance(
        AccountData memory user,
        uint256 offerAmount,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalOfferAmount, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            offerAmount + priorityFeeAmount
        );

        totalOfferAmount = offerAmount;
        totalPriorityFeeAmount = priorityFeeAmount;

    }

    function test__unit_correct__makeOffer__nS_nPF() external {
        (uint256 totalOfferAmount, ) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                0,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            0,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, COMMON_USER_NO_STAKER_2.Address);
        assertEq(checkData.amount, ((totalOfferAmount * 995) / 1000));
        assertEq(checkData.expireDate, block.timestamp + 30 days);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() + (totalOfferAmount * 125) / 100_000
        );
    }

    function test__unit_correct__makeOffer__nS_PF() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, COMMON_USER_NO_STAKER_2.Address);
        assertEq(checkData.amount, ((totalOfferAmount * 995) / 1000));
        assertEq(checkData.expireDate, block.timestamp + 30 days);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() +
                ((totalOfferAmount * 125) / 100_000) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__makeOffer__S_nPF() external {
        (uint256 totalOfferAmount, ) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                0,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            0,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, COMMON_USER_NO_STAKER_2.Address);
        assertEq(checkData.amount, ((totalOfferAmount * 995) / 1000));
        assertEq(checkData.expireDate, block.timestamp + 30 days);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + (totalOfferAmount * 125) / 100_000
        );
    }

    function test__unit_correct__makeOffer__S_PF() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, COMMON_USER_NO_STAKER_2.Address);
        assertEq(checkData.amount, ((totalOfferAmount * 995) / 1000));
        assertEq(checkData.expireDate, block.timestamp + 30 days);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                ((totalOfferAmount * 125) / 100_000) +
                priorityFeeAmount
        );
    }
}
