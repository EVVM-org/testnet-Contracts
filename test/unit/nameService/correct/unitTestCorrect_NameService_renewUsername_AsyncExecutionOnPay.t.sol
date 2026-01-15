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

contract unitTestCorrect_NameService_renewUsername_AsyncExecutionOnPay is
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
     * EDPass: Expiration date passed
     */

    function test__unit_correct__renewUsername__nS_nPF_nOf() external {
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

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

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

    function test__unit_correct__renewUsername__nS_nPF_Of() external {
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.01 ether,
            10001,
            101,
            true
        );

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
            ((nameService.getSingleOfferOfUsername("test", 0).amount * 5) /
                1000) > (500000 * evvm.getRewardAmount())
                ? (500000 * evvm.getRewardAmount())
                : ((nameService.getSingleOfferOfUsername("test", 0).amount *
                    5) / 1000)
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

    function test__unit_correct__renewUsername__nS_nPF_EDPass() external {
        skip(370 days);
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

        assertEq(newUsernameExpirationTime, block.timestamp + ((362 days)));

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

    function test__unit_correct__renewUsername__nS_PF_nOf() external {
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

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

    function test__unit_correct__renewUsername__nS_PF_Of() external {
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.01 ether,
            10001,
            101,
            true
        );

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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
            ((nameService.getSingleOfferOfUsername("test", 0).amount * 5) /
                1000) > (500000 * evvm.getRewardAmount())
                ? (500000 * evvm.getRewardAmount())
                : ((nameService.getSingleOfferOfUsername("test", 0).amount *
                    5) / 1000)
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

    function test__unit_correct__renewUsername__nS_PF_EDPass() external {
        skip(370 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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

        assertEq(newUsernameExpirationTime, block.timestamp + ((362 days)));

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

    function test__unit_correct__renewUsername__S_nPF_nOf() external {
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

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__renewUsername__S_nPF_Of() external {
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.01 ether,
            10001,
            101,
            true
        );

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
            ((nameService.getSingleOfferOfUsername("test", 0).amount * 5) /
                1000) > (500000 * evvm.getRewardAmount())
                ? (500000 * evvm.getRewardAmount())
                : ((nameService.getSingleOfferOfUsername("test", 0).amount *
                    5) / 1000)
        );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__renewUsername__S_nPF_EDPass() external {
        skip(370 days);
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

        assertEq(newUsernameExpirationTime, block.timestamp + ((362 days)));

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__renewUsername__S_PF_nOf() external {
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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

        assertEq(nameService.seePriceToRenew("test"), 500 * 10 ** 18);

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__renewUsername__S_PF_Of() external {
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.01 ether,
            10001,
            101,
            true
        );

        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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
            ((nameService.getSingleOfferOfUsername("test", 0).amount * 5) /
                1000) > (500000 * evvm.getRewardAmount())
                ? (500000 * evvm.getRewardAmount())
                : ((nameService.getSingleOfferOfUsername("test", 0).amount *
                    5) / 1000)
        );

        uint256 priceOfRenewBefore = nameService.seePriceToRenew("test");

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }

    function test__unit_correct__renewUsername__S_PF_EDPass() external {
        skip(370 days);
        uint256 priorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1,
            "test",
            0.001 ether
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

        assertEq(newUsernameExpirationTime, block.timestamp + ((362 days)));

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
                ((priceOfRenewBefore * 50) / 100) +
                priorityFeeAmount
        );
    }
}
