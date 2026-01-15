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

contract unitTestCorrect_NameService_preRegistrationUsername_AsyncExecutionOnPay is
    Test,
    Constants
{
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function addBalance(
        address user,
        address token,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user, token, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    function test__unit_correct__preRegistrationUsername__nS_nPF() external {
        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                "test",
                10101,
                1001,
                false,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked("test", uint256(10101))),
            1001,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("test", uint256(10101)))
                )
            )
        );

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

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

    function test__unit_correct__preRegistrationUsername__nS_PF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                "test",
                10101,
                1001,
                true,
                totalPriorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked("test", uint256(10101))),
            1001,
            signatureNameService,
            totalPriorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("test", uint256(10101)))
                )
            )
        );
        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

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

    function test__unit_correct__preRegistrationUsername__S_nPF() external {
        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                "test",
                10101,
                1001,
                false,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked("test", uint256(10101))),
            1001,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("test", uint256(10101)))
                )
            )
        );

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount()
        );
    }

    function test__unit_correct__preRegistrationUsername__S_PF() external {
        uint256 totalPriorityFeeAmount = addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                "test",
                10101,
                1001,
                true,
                totalPriorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked("test", uint256(10101))),
            1001,
            signatureNameService,
            totalPriorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("test", uint256(10101)))
                )
            )
        );
        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + totalPriorityFeeAmount
        );
    }
}
