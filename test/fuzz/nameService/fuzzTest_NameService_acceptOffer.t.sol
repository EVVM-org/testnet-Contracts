// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**

:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     


 * @title unit test for EVVM function correct behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
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
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_NameService_acceptOffer is Test, Constants {
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

    struct AcceptOfferFuzzTestInput_nPF {
        uint16 amountToOffer;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct AcceptOfferFuzzTestInput_PF {
        uint16 amountToOffer;
        uint8 nonceNameService;
        uint32 priorityFeeAmountEVVM;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    function test__fuzz__acceptOffer__nS_nPF(
        AcceptOfferFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.amountToOffer > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            10001,
            101,
            true
        );

        (
            bytes memory signatureNameService,

        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                0,
                input.nonceNameService,
                0,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            input.nonceNameService,
            signatureNameService,
            0,
            nonceEvvm,
            input.priorityFlagEVVM,
            ""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_2.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkData.amount
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }

    function test__fuzz__acceptOffer__nS_PF(
        AcceptOfferFuzzTestInput_PF memory input
    ) external {
        vm.assume(input.amountToOffer > 0 && input.priorityFeeAmountEVVM > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.priorityFeeAmountEVVM
        );

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            10001,
            101,
            true
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                0,
                input.nonceNameService,
                input.priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            input.nonceNameService,
            signatureNameService,
            amountPriorityFee,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_2.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkData.amount
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_3.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }

    function test__fuzz__acceptOffer__S_nPF(
        AcceptOfferFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.amountToOffer > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            10001,
            101,
            true
        );

        (
            bytes memory signatureNameService,

        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                0,
                input.nonceNameService,
                0,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        uint256 amountOfStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            input.nonceNameService,
            signatureNameService,
            0,
            nonceEvvm,
            input.priorityFlagEVVM,
            ""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_2.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkData.amount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                amountOfStakerBefore
        );
    }

    function test__fuzz__acceptOffer__S_PF(
        AcceptOfferFuzzTestInput_PF memory input
    ) external {
        vm.assume(input.amountToOffer > 0 && input.priorityFeeAmountEVVM > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.priorityFeeAmountEVVM
        );

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            10001,
            101,
            true
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                0,
                input.nonceNameService,
                input.priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        uint256 amountOfStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            input.nonceNameService,
            signatureNameService,
            amountPriorityFee,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_2.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            checkData.amount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                input.priorityFeeAmountEVVM +
                amountOfStakerBefore
        );
    }
}
