// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */
pragma solidity ^0.8.0;
pragma abicoder v2;
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/library/structs/EvvmStructs.sol";

contract fuzzTest_EVVM_batchPay is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            )
        );
    }

    function addBalance(
        AccountData memory user,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee
    ) private returns (uint256 totalAmount, uint256 totalPriorityFee) {
        evvm.addBalance(user.Address, tokenAddress, amount + priorityFee);

        totalAmount = amount;
        totalPriorityFee = priorityFee;
    }

    /**
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nPF: No priority fee
     * EX: Includes executor execution
     * nEX: Does not include executor execution
     * ID: Uses a NameService identity
     * AD: Uses an address
     */

    struct PayMultipleFuzzTestInput {
        bool useStaker;
        bool[2] useToAddress;
        bool[2] useExecutor;
        address[2] token;
        uint16[2] amount;
        uint16[2] priorityFee;
        uint176[2] nonce;
        bool[2] isAsyncExec;
    }

    function test__fuzz__batchPay(
        PayMultipleFuzzTestInput memory input
    ) external {
        vm.assume(
            input.amount[0] > 0 &&
                input.amount[1] > 0 &&
                input.token[0] != input.token[1] &&
                input.token[0] != PRINCIPAL_TOKEN_ADDRESS &&
                input.token[1] != PRINCIPAL_TOKEN_ADDRESS &&
                !(input.isAsyncExec[0] &&
                    input.isAsyncExec[1] &&
                    input.nonce[0] == input.nonce[1])
        );

        EvvmStructs.BatchData[] memory batchData = new EvvmStructs.BatchData[](
            2
        );

        AccountData memory FISHER = input.useStaker
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_3;

        bytes[3] memory signature;

        signature[0] = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            input.useToAddress[0]
                ? COMMON_USER_NO_STAKER_2.Address
                : address(0),
            input.useToAddress[0] ? "" : "dummy",
            input.token[0],
            input.amount[0],
            input.priorityFee[0],
            input.useExecutor[0] ? FISHER.Address : address(0),
            input.isAsyncExec[0]
                ? input.nonce[0]
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            input.isAsyncExec[0]
        );

        signature[1] = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            input.useToAddress[1]
                ? COMMON_USER_NO_STAKER_2.Address
                : address(0),
            input.useToAddress[1] ? "" : "dummy",
            input.token[1],
            input.amount[1],
            input.priorityFee[1],
            input.useExecutor[1] ? FISHER.Address : address(0),
            input.isAsyncExec[1]
                ? input.nonce[1]
                : (
                    input.isAsyncExec[0] == false
                        ? evvm.getNextCurrentSyncNonce(
                            COMMON_USER_NO_STAKER_1.Address
                        ) + 1
                        : evvm.getNextCurrentSyncNonce(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                ),
            input.isAsyncExec[1]
        );

        for (uint256 i = 0; i < 2; i++) {
            addBalance(
                COMMON_USER_NO_STAKER_1,
                input.token[i],
                input.amount[i],
                input.priorityFee[i]
            );

            batchData[i] = EvvmStructs.BatchData({
                from: COMMON_USER_NO_STAKER_1.Address,
                to_address: input.useToAddress[i]
                    ? COMMON_USER_NO_STAKER_2.Address
                    : address(0),
                to_identity: input.useToAddress[i] ? "" : "dummy",
                token: input.token[i],
                amount: input.amount[i],
                priorityFee: input.priorityFee[i],
                nonce: input.isAsyncExec[i]
                    ? input.nonce[i]
                    : (
                        input.isAsyncExec[0] == false && i == 1
                            ? evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            ) + 1
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                isAsyncExec: input.isAsyncExec[i],
                executor: input.useExecutor[i] ? FISHER.Address : address(0),
                signature: signature[i]
            });
        }

        vm.startPrank(FISHER.Address);
        (uint256 successfulTransactions, bool[] memory status) = evvm.batchPay(
            batchData
        );
        vm.stopPrank();

        assertEq(successfulTransactions, 2);
        assertEq(status[0], true);
        assertEq(status[1], true);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    input.token[i]
                ),
                input.amount[i],
                "balance incorrect for recipient"
            );
        }

        if (FISHER.Address == COMMON_USER_STAKER.Address) {
            for (uint256 i = 0; i < 2; i++) {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, input.token[i]),
                    input.priorityFee[i],
                    "balance incorrect for staker"
                );
            }

            assertEq(
                evvm.getBalance(FISHER.Address, PRINCIPAL_TOKEN_ADDRESS),
                evvm.getRewardAmount() * 2,
                "executor did not receive correct reward"
            );
        } else {
            for (uint256 i = 0; i < 2; i++) {
                assertEq(
                    evvm.getBalance(
                        COMMON_USER_NO_STAKER_1.Address,
                        input.token[i]
                    ),
                    input.priorityFee[i]
                );
            }

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_3.Address,
                    PRINCIPAL_TOKEN_ADDRESS
                ),
                0
            );
        }

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    input.token[i]
                ),
                input.amount[i]
            );
        }
    }
}
