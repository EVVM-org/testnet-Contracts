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

contract fuzzTest_NameService_renewUsername is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            1,
            0,
            1
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
            nameService.seePriceToRenew(username) + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     * nOf: No offer
     * Of: Offer
     * Ex: Expiration date passed
     */

    struct RenewUsernameFuzzTestInput_nPF_nOf {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct RenewUsernameFuzzTestInput_nPF_Of {
        uint136 amountToOffer;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct RenewUsernameFuzzTestInput_nPF_Ex {
        uint8 daysPassed;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct RenewUsernameFuzzTestInput_PF_nOf {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        uint16 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
    }

    struct RenewUsernameFuzzTestInput_PF_Of {
        uint136 amountToOffer;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        uint16 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
    }

    struct RenewUsernameFuzzTestInput_PF_Ex {
        uint8 daysPassed;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        uint16 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
    }

    function test__fuzz__renewUsername__nS_nPF_nOf(
        RenewUsernameFuzzTestInput_nPF_nOf memory input
    ) external {
        vm.assume(input.nonceNameService > 1);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

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

    function test__fuzz__renewUsername__nS_nPF_Of(
        RenewUsernameFuzzTestInput_nPF_Of memory input
    ) external {
        vm.assume(input.nonceNameService > 1 && input.amountToOffer > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            1,
            1,
            true
        );

        uint256 amountOffer = nameService
            .getSingleOfferOfUsername("test", 0)
            .amount;

        if (amountOffer != 0) {
            assertEq(
                nameService.seePriceToRenew("test"),
                ((amountOffer * 5) / 1000) > (500000 * evvm.getRewardAmount())
                    ? (500000 * evvm.getRewardAmount())
                    : ((amountOffer * 5) / 1000)
            );
        } else {
            assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);
        }

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

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

    function test__fuzz__renewUsername__nS_nPF_Ex(
        RenewUsernameFuzzTestInput_nPF_Ex memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.daysPassed < 365 &&
                input.daysPassed > 0
        );

        skip((366 + uint256(input.daysPassed)) * 1 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1000001000001,
                priorityFeeAmount,
                11111111,
                true
            );

        assertEq(
            nameService.seePriceToRenew("test"),
            500_000 * evvm.getRewardAmount()
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            priorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(
            newUsernameExpirationTime,
            block.timestamp + (366 days - (uint256(input.daysPassed) * 1 days))
        );

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

    function test__fuzz__renewUsername__nS_PF_nOf(
        RenewUsernameFuzzTestInput_PF_nOf memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 && input.priorityFeeAmountEVVM > 0
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

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

    function test__fuzz__renewUsername__nS_PF_Of(
        RenewUsernameFuzzTestInput_PF_Of memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.amountToOffer > 0 &&
                input.priorityFeeAmountEVVM > 0
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            1,
            1,
            true
        );

        uint256 amountOffer = nameService
            .getSingleOfferOfUsername("test", 0)
            .amount;

        if (amountOffer != 0) {
            assertEq(
                nameService.seePriceToRenew("test"),
                ((amountOffer * 5) / 1000) > (500000 * evvm.getRewardAmount())
                    ? (500000 * evvm.getRewardAmount())
                    : ((amountOffer * 5) / 1000)
            );
        } else {
            assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);
        }

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

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

    function test__fuzz__renewUsername__nS_PF_Ex(
        RenewUsernameFuzzTestInput_PF_Ex memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.daysPassed < 365 &&
                input.daysPassed > 0
        );

        skip((366 + uint256(input.daysPassed)) * 1 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1000001000001,
                priorityFeeAmount,
                11111111,
                true
            );

        assertEq(
            nameService.seePriceToRenew("test"),
            500_000 * evvm.getRewardAmount()
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            priorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(
            newUsernameExpirationTime,
            block.timestamp + (366 days - (uint256(input.daysPassed) * 1 days))
        );

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

    function test__fuzz__renewUsername__S_nPF_nOf(
        RenewUsernameFuzzTestInput_nPF_nOf memory input
    ) external {
        vm.assume(input.nonceNameService > 1);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }

    function test__fuzz__renewUsername__S_nPF_Of(
        RenewUsernameFuzzTestInput_nPF_Of memory input
    ) external {
        vm.assume(input.nonceNameService > 1 && input.amountToOffer > 0);

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            1,
            1,
            true
        );

        uint256 amountOffer = nameService
            .getSingleOfferOfUsername("test", 0)
            .amount;

        if (amountOffer != 0) {
            assertEq(
                nameService.seePriceToRenew("test"),
                ((amountOffer * 5) / 1000) > (500000 * evvm.getRewardAmount())
                    ? (500000 * evvm.getRewardAmount())
                    : ((amountOffer * 5) / 1000)
            );
        } else {
            assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);
        }

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }

    function test__fuzz__renewUsername__S_nPF_Ex(
        RenewUsernameFuzzTestInput_nPF_Ex memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.daysPassed < 365 &&
                input.daysPassed > 0
        );

        skip((366 + uint256(input.daysPassed)) * 1 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1000001000001,
                priorityFeeAmount,
                11111111,
                true
            );

        assertEq(
            nameService.seePriceToRenew("test"),
            500_000 * evvm.getRewardAmount()
        );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            priorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(
            newUsernameExpirationTime,
            block.timestamp + (366 days - (uint256(input.daysPassed) * 1 days))
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }

    function test__fuzz__renewUsername__S_PF_nOf(
        RenewUsernameFuzzTestInput_PF_nOf memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 && input.priorityFeeAmountEVVM > 0
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }

    function test__fuzz__renewUsername__S_PF_Of(
        RenewUsernameFuzzTestInput_PF_Of memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.amountToOffer > 0 &&
                input.priorityFeeAmountEVVM > 0
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            input.amountToOffer,
            1,
            1,
            true
        );

        uint256 amountOffer = nameService
            .getSingleOfferOfUsername("test", 0)
            .amount;

        if (amountOffer != 0) {
            assertEq(
                nameService.seePriceToRenew("test"),
                ((amountOffer * 5) / 1000) > (500000 * evvm.getRewardAmount())
                    ? (500000 * evvm.getRewardAmount())
                    : ((amountOffer * 5) / 1000)
            );
        } else {
            assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);
        }

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.nonceNameService,
                priorityFeeAmount,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmount,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(newUsernameExpirationTime, block.timestamp + ((366 days) * 2));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }

    function test__fuzz__renewUsername__S_PF_Ex(
        RenewUsernameFuzzTestInput_PF_Ex memory input
    ) external {
        vm.assume(
            input.nonceNameService > 1 &&
                input.daysPassed < 365 &&
                input.daysPassed > 0
        );

        skip((366 + uint256(input.daysPassed)) * 1 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1000001000001,
                priorityFeeAmount,
                11111111,
                true
            );

        assertEq(
            nameService.seePriceToRenew("test"),
            500_000 * evvm.getRewardAmount()
        );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");
        uint256 amountStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            priorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 newUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(
            newUsernameExpirationTime,
            block.timestamp + (366 days - (uint256(input.daysPassed) * 1 days))
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((priceOfRenewBefore * 50) / 100) + priorityFeeAmount) +
                amountStakerBefore
        );
    }
}
