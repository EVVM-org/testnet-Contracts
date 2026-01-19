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

contract fuzzTest_NameService_removeCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 constant MAX_AMOUNT_SLOTS_REGISTERED = uint256(type(uint8).max) + 1;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
                uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2)
        );

        for (uint256 i = 0; i < MAX_AMOUNT_SLOTS_REGISTERED; i++) {
            _execute_makeAddCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                "test",
                string.concat("test>", AdvancedStrings.uintToString(i)),
                uint256(type(uint32).max) + 1 + i,
                uint256(type(uint32).max) + 1 + i,
                true
            );
        }
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct RemoveCustomMetadataFuzzTestInput_nPF {
        uint8 indexToRemove;
        uint32 nonceNameService;
        uint32 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct RemoveCustomMetadataFuzzTestInput_PF {
        uint8 indexToRemove;
        uint32 nonceNameService;
        uint32 nonceEVVM;
        uint16 priorityFeeAmountEVVM;
        bool priorityFlagEVVM;
    }

    function test__fuzz__removeCustomMetadata__nS_nPF(
        RemoveCustomMetadataFuzzTestInput_nPF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(type(uint8).max) &&
                input.nonceEVVM > uint256(type(uint8).max)
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 priorityFeeAmountEVVM = addBalance(COMMON_USER_NO_STAKER_1, 0);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.indexToRemove,
                input.nonceNameService,
                priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.indexToRemove,
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", input.indexToRemove);

        console2.log("customMetadata: ", customMetadata);

        if (input.indexToRemove != type(uint8).max) {
            assertEq(
                bytes(customMetadata).length,
                bytes(
                    string.concat(
                        "test>",
                        AdvancedStrings.uintToString(input.indexToRemove + 1)
                    )
                ).length
            );
            assertEq(
                keccak256(bytes(customMetadata)),
                keccak256(
                    bytes(
                        string.concat(
                            "test>",
                            AdvancedStrings.uintToString(
                                input.indexToRemove + 1
                            )
                        )
                    )
                )
            );
        } else {
            assertEq(bytes(customMetadata).length, bytes("").length);
            assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("")));
        }

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

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity("test"),
            MAX_AMOUNT_SLOTS_REGISTERED - 1
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

    function test__fuzz__removeCustomMetadata__nS_PF(
        RemoveCustomMetadataFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(type(uint8).max) &&
                input.nonceEVVM > uint256(type(uint8).max)
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 priorityFeeAmountEVVM = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.indexToRemove,
                input.nonceNameService,
                priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.indexToRemove,
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", input.indexToRemove);

        console2.log("customMetadata: ", customMetadata);

        if (input.indexToRemove != type(uint8).max) {
            assertEq(
                bytes(customMetadata).length,
                bytes(
                    string.concat(
                        "test>",
                        AdvancedStrings.uintToString(input.indexToRemove + 1)
                    )
                ).length
            );
            assertEq(
                keccak256(bytes(customMetadata)),
                keccak256(
                    bytes(
                        string.concat(
                            "test>",
                            AdvancedStrings.uintToString(
                                input.indexToRemove + 1
                            )
                        )
                    )
                )
            );
        } else {
            assertEq(bytes(customMetadata).length, bytes("").length);
            assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("")));
        }

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

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity("test"),
            MAX_AMOUNT_SLOTS_REGISTERED - 1
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

    function test__fuzz__removeCustomMetadata__S_nPF(
        RemoveCustomMetadataFuzzTestInput_nPF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(type(uint8).max) &&
                input.nonceEVVM > uint256(type(uint8).max)
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 priorityFeeAmountEVVM = addBalance(COMMON_USER_NO_STAKER_1, 0);

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", input.indexToRemove);

        console2.log("customMetadata: ", customMetadata);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.indexToRemove,
                input.nonceNameService,
                priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.indexToRemove,
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        customMetadata = nameService.getSingleCustomMetadataOfIdentity(
            "test",
            input.indexToRemove
        );

        console2.log("customMetadata: ", customMetadata);

        if (input.indexToRemove != type(uint8).max) {
            assertEq(
                bytes(customMetadata).length,
                bytes(
                    string.concat(
                        "test>",
                        AdvancedStrings.uintToString(input.indexToRemove + 1)
                    )
                ).length
            );
            assertEq(
                keccak256(bytes(customMetadata)),
                keccak256(
                    bytes(
                        string.concat(
                            "test>",
                            AdvancedStrings.uintToString(
                                input.indexToRemove + 1
                            )
                        )
                    )
                )
            );
        } else {
            assertEq(bytes(customMetadata).length, bytes("").length);
            assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("")));
        }

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

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity("test"),
            MAX_AMOUNT_SLOTS_REGISTERED - 1
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
            (5 * evvm.getRewardAmount()) + priorityFeeAmountEVVM
        );
    }

    function test__fuzz__removeCustomMetadata__S_PF(
        RemoveCustomMetadataFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.nonceNameService > uint256(type(uint8).max) &&
                input.nonceEVVM > uint256(type(uint8).max)
        );

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        uint256 priorityFeeAmountEVVM = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.priorityFeeAmountEVVM
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                input.indexToRemove,
                input.nonceNameService,
                priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            input.indexToRemove,
            input.nonceNameService,
            signatureNameService,
            priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", input.indexToRemove);

        console2.log("customMetadata: ", customMetadata);

        if (input.indexToRemove != type(uint8).max) {
            assertEq(
                bytes(customMetadata).length,
                bytes(
                    string.concat(
                        "test>",
                        AdvancedStrings.uintToString(input.indexToRemove + 1)
                    )
                ).length
            );
            assertEq(
                keccak256(bytes(customMetadata)),
                keccak256(
                    bytes(
                        string.concat(
                            "test>",
                            AdvancedStrings.uintToString(
                                input.indexToRemove + 1
                            )
                        )
                    )
                )
            );
        } else {
            assertEq(bytes(customMetadata).length, bytes("").length);
            assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("")));
        }

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

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity("test"),
            MAX_AMOUNT_SLOTS_REGISTERED - 1
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
            (5 * evvm.getRewardAmount()) + priorityFeeAmountEVVM
        );
    }
}
