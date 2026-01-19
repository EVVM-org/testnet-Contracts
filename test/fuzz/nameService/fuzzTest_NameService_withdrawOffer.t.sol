// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/*
:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     
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
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
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

contract fuzzTest_NameService_withdrawOffer is Test, Constants {
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

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct WithdrawOfferFuzzTestInput_nPF {
        bool usingUserTwo;
        bool usingFisher;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct WithdrawOfferFuzzTestInput_PF {
        bool usingUserTwo;
        bool usingFisher;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
        uint16 priorityFeeAmountEVVM;
    }

    function test__fuzz__withdrawOffer__nPF(
        WithdrawOfferFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.nonceNameService != 10001 && input.nonceEVVM != 101);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        makeOffer(
            COMMON_USER_NO_STAKER_3,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        AccountData memory selectedUser = input.usingUserTwo
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedExecuter = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_1;

        uint256 indexSelected = input.usingUserTwo ? 0 : 1;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (
            bytes memory signatureNameService,

        ) = _execute_makeWithdrawOfferSignatures(
                selectedUser,
                "test",
                indexSelected,
                input.nonceNameService,
                0,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        vm.startPrank(selectedExecuter.Address);

        nameService.withdrawOffer(
            selectedUser.Address,
            "test",
            indexSelected,
            input.nonceNameService,
            signatureNameService,
            0,
            nonceEvvm,
            input.priorityFlagEVVM,
            ""
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(selectedUser.Address, PRINCIPAL_TOKEN_ADDRESS),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + (((checkDataBefore.amount * 1) / 796))
        );
    }

    function test__fuzz__withdrawOffer__PF(
        WithdrawOfferFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.nonceNameService != 10001 &&
                input.nonceEVVM != 101 &&
                input.priorityFeeAmountEVVM != 0
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

        makeOffer(
            COMMON_USER_NO_STAKER_3,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        AccountData memory selectedUser = input.usingUserTwo
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedExecuter = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_1;

        uint256 indexSelected = input.usingUserTwo ? 0 : 1;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        addBalance(selectedUser, input.priorityFeeAmountEVVM);
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
                selectedUser,
                "test",
                indexSelected,
                input.nonceNameService,
                input.priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        vm.startPrank(selectedExecuter.Address);

        nameService.withdrawOffer(
            selectedUser.Address,
            "test",
            indexSelected,
            input.nonceNameService,
            signatureNameService,
            input.priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(selectedUser.Address, PRINCIPAL_TOKEN_ADDRESS),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((checkDataBefore.amount * 1) / 796)) +
                input.priorityFeeAmountEVVM
        );
    }
}
