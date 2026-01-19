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

contract fuzzTest_NameService_preRegistrationUsername is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

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

    function makeUsername(
        uint16 seed
    ) private pure returns (string memory username) {
        /// creas un nombre de usuario aleatorio de seed/2 caracteres
        /// este debe ser de la A-Z y a-z
        bytes memory usernameBytes = new bytes(seed / 2);
        for (uint256 i = 0; i < seed / 2; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(seed, i))) % 52;
            if (random < 26) {
                usernameBytes[i] = bytes1(uint8(random + 65));
            } else {
                usernameBytes[i] = bytes1(uint8(random + 71));
            }
        }
        username = string(usernameBytes);
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct PreRegistrationUsernameFuzzTestInput_nPF {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
        uint16 clowNumber;
        uint16 seed;
    }

    struct PreRegistrationUsernameFuzzTestInput_PF {
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
        uint16 priorityFeeAmount;
        uint16 clowNumber;
        uint16 seed;
    }

    function test__fuzz__preRegistrationUsername__nS_nPF(
        PreRegistrationUsernameFuzzTestInput_nPF memory input
    ) external {
        AccountData memory selectedUser = (input.seed % 2 == 0)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_NO_STAKER_2;

        vm.assume((input.seed / 2) >= 4);
        string memory username = makeUsername(input.seed);

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                selectedUser,
                username,
                input.clowNumber,
                input.nonceNameService,
                0,
                nonce,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.preRegistrationUsername(
            selectedUser.Address,
            keccak256(abi.encodePacked(username, uint256(input.clowNumber))),
            input.nonceNameService,
            signatureNameService,
            0,
            nonce,
            input.priorityFlagEVVM,
            hex""
        );

        vm.stopPrank();

        (address ownerAddress, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(username, uint256(input.clowNumber))
                    )
                )
            )
        );

        assertEq(ownerAddress, selectedUser.Address);

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

    function test__fuzz__preRegistrationUsername__nS_PF(
        PreRegistrationUsernameFuzzTestInput_PF memory input
    ) external {
        vm.assume((input.seed / 2) >= 4);

        AccountData memory selectedUser = (input.seed % 2 == 0)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_NO_STAKER_2;

        addBalance(
            selectedUser.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            input.priorityFeeAmount
        );

        string memory username = makeUsername(input.seed);

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                selectedUser,
                username,
                input.clowNumber,
                input.nonceNameService,
                input.priorityFeeAmount,
                nonce,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        nameService.preRegistrationUsername(
            selectedUser.Address,
            keccak256(abi.encodePacked(username, uint256(input.clowNumber))),
            input.nonceNameService,
            signatureNameService,
            input.priorityFeeAmount,
            nonce,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (address ownerAddress, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(username, uint256(input.clowNumber))
                    )
                )
            )
        );

        assertEq(ownerAddress, selectedUser.Address);

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

    function test__fuzz__preRegistrationUsername__S_nPF(
        PreRegistrationUsernameFuzzTestInput_nPF memory input
    ) external {
        AccountData memory selectedUser = (input.seed % 2 == 0)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_NO_STAKER_2;

        vm.assume((input.seed / 2) >= 4);
        string memory username = makeUsername(input.seed);

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                selectedUser,
                username,
                input.clowNumber,
                input.nonceNameService,
                0,
                nonce,
                input.priorityFlagEVVM
            );

        uint256 balanceStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.preRegistrationUsername(
            selectedUser.Address,
            keccak256(abi.encodePacked(username, uint256(input.clowNumber))),
            input.nonceNameService,
            signatureNameService,
            0,
            nonce,
            input.priorityFlagEVVM,
            hex""
        );

        vm.stopPrank();

        (address ownerAddress, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(username, uint256(input.clowNumber))
                    )
                )
            )
        );

        assertEq(ownerAddress, selectedUser.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + balanceStakerBefore
        );
    }

    function test__fuzz__preRegistrationUsername__S_PF(
        PreRegistrationUsernameFuzzTestInput_PF memory input
    ) external {
        vm.assume((input.seed / 2) >= 4);

        AccountData memory selectedUser = (input.seed % 2 == 0)
            ? COMMON_USER_NO_STAKER_1
            : COMMON_USER_NO_STAKER_2;

        addBalance(
            selectedUser.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            input.priorityFeeAmount
        );

        string memory username = makeUsername(input.seed);

        uint256 nonce = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                selectedUser,
                username,
                input.clowNumber,
                input.nonceNameService,
                input.priorityFeeAmount,
                nonce,
                input.priorityFlagEVVM
            );

        uint256 balanceStakerBefore = evvm.getBalance(
            COMMON_USER_STAKER.Address,
            PRINCIPAL_TOKEN_ADDRESS
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.preRegistrationUsername(
            selectedUser.Address,
            keccak256(abi.encodePacked(username, uint256(input.clowNumber))),
            input.nonceNameService,
            signatureNameService,
            input.priorityFeeAmount,
            nonce,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        (address ownerAddress, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(username, uint256(input.clowNumber))
                    )
                )
            )
        );

        assertEq(ownerAddress, selectedUser.Address);

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
                balanceStakerBefore +
                input.priorityFeeAmount
        );
    }
}
