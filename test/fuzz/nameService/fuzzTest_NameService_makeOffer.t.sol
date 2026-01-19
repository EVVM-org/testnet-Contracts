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

contract fuzzTest_NameService_makeOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

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

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101,
            20202
        );
    }

    /**
     * Function to test:
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct MakeOfferFuzzTestInput_nPF {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
        uint16 clowNumber;
        uint16 seed;
        uint128 daysForExpire;
        uint64 offerAmount;
        bool electionOne;
        bool electionTwo;
    }

    struct MakeOfferFuzzTestInput_PF {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        uint32 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
        uint16 clowNumber;
        uint16 seed;
        uint128 daysForExpire;
        uint64 offerAmount;
        bool electionOne;
        bool electionTwo;
    }

    function test__fuzz__makeOffer__nPF(
        MakeOfferFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.offerAmount > 0 && input.daysForExpire > 0);

        AccountData memory selectedUser = (input.electionOne)
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedFisher = (input.electionTwo)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_STAKER;

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        addBalance(selectedUser, input.offerAmount, 0);
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                selectedUser,
                "test",
                block.timestamp + uint256(input.daysForExpire),
                input.offerAmount,
                input.nonceNameService,
                0,
                nonce,
                input.priorityFlagEVVM
            );

        vm.startPrank(selectedFisher.Address);

        nameService.makeOffer(
            selectedUser.Address,
            "test",
            block.timestamp + input.daysForExpire,
            input.offerAmount,
            input.nonceNameService,
            signatureNameService,
            0,
            nonce,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, selectedUser.Address);
        assertEq(checkData.amount, ((uint256(input.offerAmount) * 995) / 1000));
        assertEq(
            checkData.expireDate,
            block.timestamp + uint256(input.daysForExpire)
        );

        assertEq(evvm.getBalance(selectedUser.Address, PRINCIPAL_TOKEN_ADDRESS), 0);
        assertEq(
            evvm.getBalance(selectedFisher.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (uint256(input.offerAmount) * 125) /
                100_000
        );
    }

    function test__fuzz__makeOffer__PF(
        MakeOfferFuzzTestInput_PF memory input
    ) external {
        vm.assume(input.offerAmount > 0 && input.daysForExpire > 0);

        AccountData memory selectedUser = (input.electionOne)
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedFisher = (input.electionTwo)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_STAKER;

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        addBalance(
            selectedUser,
            input.offerAmount,
            input.priorityFeeAmountEVVM
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                selectedUser,
                "test",
                block.timestamp + uint256(input.daysForExpire),
                input.offerAmount,
                input.nonceNameService,
                input.priorityFeeAmountEVVM,
                nonce,
                input.priorityFlagEVVM
            );

        vm.startPrank(selectedFisher.Address);

        nameService.makeOffer(
            selectedUser.Address,
            "test",
            block.timestamp + input.daysForExpire,
            input.offerAmount,
            input.nonceNameService,
            signatureNameService,
            input.priorityFeeAmountEVVM,
            nonce,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, selectedUser.Address);
        assertEq(checkData.amount, ((uint256(input.offerAmount) * 995) / 1000));
        assertEq(
            checkData.expireDate,
            block.timestamp + uint256(input.daysForExpire)
        );

        assertEq(evvm.getBalance(selectedUser.Address, PRINCIPAL_TOKEN_ADDRESS), 0);
        assertEq(
            evvm.getBalance(selectedFisher.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (uint256(input.offerAmount) * 125) /
                100_000 +
                input.priorityFeeAmountEVVM
        );
    }
}
