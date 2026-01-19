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

contract fuzzTest_NameService_flushUsername is Test, Constants {
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

    function setAmountOfCustomMetadata(
        AccountData memory user,
        string memory username,
        uint256 amount
    ) private {
        for (uint256 i = 0; i < amount; i++) {
            _execute_makeAddCustomMetadata(
                user,
                username,
                string.concat("test>", AdvancedStrings.uintToString(i)),
                i,
                i,
                true
            );
        }
    }

    /**
     * Function to test:
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct FlushUsernameFuzzTestInput_nPF {
        bool usingFisher;
        uint8 amountOfCustomMetadata;
        uint32 nonceNameService;
        uint32 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct FlushUsernameFuzzTestInput_PF {
        bool usingFisher;
        uint8 amountOfCustomMetadata;
        uint32 nonceNameService;
        uint32 nonceEVVM;
        uint16 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
    }

    function test__fuzz__flushUsername__nPF(
        FlushUsernameFuzzTestInput_nPF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(input.amountOfCustomMetadata) &&
                input.nonceEVVM > uint256(input.amountOfCustomMetadata) &&
                input.nonceNameService != 10101 &&
                input.nonceEVVM != 10101 &&
                input.nonceNameService != 20202 &&
                input.nonceEVVM != 20202 &&
                uint256(input.amountOfCustomMetadata) > 0
        );

        AccountData memory userToExecuteTx = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_2;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        setAmountOfCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.amountOfCustomMetadata
        );

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
                input.nonceNameService,
                totalPriorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(userToExecuteTx.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
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
            evvm.getBalance(userToExecuteTx.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }

    function test__fuzz__flushUsername__PF(
        FlushUsernameFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(input.amountOfCustomMetadata) &&
                input.nonceEVVM > uint256(input.amountOfCustomMetadata) &&
                input.nonceNameService != 10101 &&
                input.nonceEVVM != 10101 &&
                input.nonceNameService != 20202 &&
                input.nonceEVVM != 20202 &&
                uint256(input.amountOfCustomMetadata) > 0 &&
                input.priorityFeeAmountEVVM > 0
        );

        AccountData memory userToExecuteTx = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_2;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        setAmountOfCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.amountOfCustomMetadata
        );

        (, uint256 totalPriorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                totalPriorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "test"
        );

        vm.startPrank(userToExecuteTx.Address);

        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
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
            evvm.getBalance(userToExecuteTx.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((5 * evvm.getRewardAmount()) * amountOfSlotsBefore) +
                totalPriorityFeeAmount
        );
    }
}
