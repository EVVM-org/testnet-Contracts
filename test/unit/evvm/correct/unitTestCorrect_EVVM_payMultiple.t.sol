// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**                                                                                                        
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄ 
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██   
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██   
                                                    
                                                    
                                                    
 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄          
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██            
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██                                                    
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestCorrect_EVVM_payMultiple is Test, Constants, EvvmStructs {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;
    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
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

    function _addBalance(
        AccountData memory _user,
        address _token,
        uint256 _amount,
        uint256 _priorityFee
    ) private returns (uint256 amount, uint256 priorityFee) {
        evvm.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    function test__unit_correct__payMultiple__noStaker() external {
        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_3, uint256 priorityFee_3) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_4, uint256 priorityFee_4) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_5, uint256 priorityFee_5) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_6, uint256 priorityFee_6) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_7, uint256 priorityFee_7) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_8, uint256 priorityFee_8) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;
        uint256 syncNonce_3 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 2;
        uint256 syncNonce_4 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 3;

        uint256 asyncNonce_1 = 67;
        uint256 asyncNonce_2 = 420;
        uint256 asyncNonce_3 = 1337;
        uint256 asyncNonce_4 = 7331;

        AccountData memory executor = COMMON_USER_NO_STAKER_3;

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](8);

        bytes memory signature;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Sync execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        signature = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            syncNonce_1,
            false,
            address(0)
        );
        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            syncNonce_1,
            false,
            address(0),
            signature
        );

        /* 🢃 toAddress -- Executor 🢃 */
        payData[1] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            syncNonce_2,
            false,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_2,
                priorityFee_2,
                syncNonce_2,
                false,
                executor.Address
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        payData[2] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_3,
            priorityFee_3,
            syncNonce_3,
            false,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_3,
                priorityFee_3,
                syncNonce_3,
                false,
                address(0)
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        payData[3] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_4,
            priorityFee_4,
            syncNonce_4,
            false,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_4,
                priorityFee_4,
                syncNonce_4,
                false,
                executor.Address
            )
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Async execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        payData[4] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_5,
            priorityFee_5,
            asyncNonce_1,
            true,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_5,
                priorityFee_5,
                asyncNonce_1,
                true,
                address(0)
            )
        );

        /* 🢃 toAddress -- Executor 🢃 */
        payData[5] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_6,
            priorityFee_6,
            asyncNonce_2,
            true,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_6,
                priorityFee_6,
                asyncNonce_2,
                true,
                executor.Address
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        payData[6] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_7,
            priorityFee_7,
            asyncNonce_3,
            true,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_7,
                priorityFee_7,
                asyncNonce_3,
                true,
                address(0)
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        payData[7] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_8,
            priorityFee_8,
            asyncNonce_4,
            true,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_8,
                priorityFee_8,
                asyncNonce_4,
                true,
                executor.Address
            )
        );

        vm.startPrank(executor.Address);
        (uint256 successfulTransactions, bool[] memory results) = evvm
            .payMultiple(payData);
        vm.stopPrank();

        assertEq(successfulTransactions, 8, "all transactions should succeed");

        assertTrue(results[0], "tx 1 should succeed");
        assertTrue(results[1], "tx 2 should succeed");
        assertTrue(results[2], "tx 3 should succeed");
        assertTrue(results[3], "tx 4 should succeed");
        assertTrue(results[4], "tx 5 should succeed");
        assertTrue(results[5], "tx 6 should succeed");
        assertTrue(results[6], "tx 7 should succeed");
        assertTrue(results[7], "tx 8 should succeed");

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 +
                amount_2 +
                amount_3 +
                amount_4 +
                amount_5 +
                amount_6 +
                amount_7 +
                amount_8,
            "COMMON_USER_NO_STAKER_2 should have received 8 payments"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 +
                priorityFee_2 +
                priorityFee_3 +
                priorityFee_4 +
                priorityFee_5 +
                priorityFee_6 +
                priorityFee_7 +
                priorityFee_8,
            "sender should have all priority fees back because there is no fisher staker"
        );

        assertEq(
            evvm.getBalance(executor.Address, ETHER_ADDRESS),
            0,
            "executor should not have received any priority fees because there is no fisher staker"
        );

        assertEq(
            evvm.getBalance(executor.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "executor should not have received any rewards because there is no fisher staker"
        );
    }

    function test__unit_correct__payMultiple__staker() external {
        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_3, uint256 priorityFee_3) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_4, uint256 priorityFee_4) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_5, uint256 priorityFee_5) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_6, uint256 priorityFee_6) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_7, uint256 priorityFee_7) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint256 amount_8, uint256 priorityFee_8) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;
        uint256 syncNonce_3 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 2;
        uint256 syncNonce_4 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 3;

        uint256 asyncNonce_1 = 67;
        uint256 asyncNonce_2 = 420;
        uint256 asyncNonce_3 = 1337;
        uint256 asyncNonce_4 = 7331;

        AccountData memory executor = COMMON_USER_STAKER;

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](8);

        bytes memory signature;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Sync execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        signature = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            syncNonce_1,
            false,
            address(0)
        );
        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            syncNonce_1,
            false,
            address(0),
            signature
        );

        /* 🢃 toAddress -- Executor 🢃 */
        payData[1] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            syncNonce_2,
            false,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_2,
                priorityFee_2,
                syncNonce_2,
                false,
                executor.Address
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        payData[2] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_3,
            priorityFee_3,
            syncNonce_3,
            false,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_3,
                priorityFee_3,
                syncNonce_3,
                false,
                address(0)
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        payData[3] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_4,
            priorityFee_4,
            syncNonce_4,
            false,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_4,
                priorityFee_4,
                syncNonce_4,
                false,
                executor.Address
            )
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Async execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        payData[4] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_5,
            priorityFee_5,
            asyncNonce_1,
            true,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_5,
                priorityFee_5,
                asyncNonce_1,
                true,
                address(0)
            )
        );

        /* 🢃 toAddress -- Executor 🢃 */
        payData[5] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_6,
            priorityFee_6,
            asyncNonce_2,
            true,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_6,
                priorityFee_6,
                asyncNonce_2,
                true,
                executor.Address
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        payData[6] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_7,
            priorityFee_7,
            asyncNonce_3,
            true,
            address(0),
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_7,
                priorityFee_7,
                asyncNonce_3,
                true,
                address(0)
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        payData[7] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_8,
            priorityFee_8,
            asyncNonce_4,
            true,
            executor.Address,
            signature = _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_8,
                priorityFee_8,
                asyncNonce_4,
                true,
                executor.Address
            )
        );

        vm.startPrank(executor.Address);
        (uint256 successfulTransactions, bool[] memory results) = evvm
            .payMultiple(payData);
        vm.stopPrank();

        assertEq(successfulTransactions, 8, "all transactions should succeed");

        assertTrue(results[0], "tx 1 should succeed");
        assertTrue(results[1], "tx 2 should succeed");
        assertTrue(results[2], "tx 3 should succeed");
        assertTrue(results[3], "tx 4 should succeed");
        assertTrue(results[4], "tx 5 should succeed");
        assertTrue(results[5], "tx 6 should succeed");
        assertTrue(results[6], "tx 7 should succeed");
        assertTrue(results[7], "tx 8 should succeed");

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 +
                amount_2 +
                amount_3 +
                amount_4 +
                amount_5 +
                amount_6 +
                amount_7 +
                amount_8,
            "COMMON_USER_NO_STAKER_2 should have received 8 payments"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "sender should have send all priority fees because there is a fisher staker"
        );

        assertEq(
            evvm.getBalance(executor.Address, ETHER_ADDRESS),
            priorityFee_1 +
                priorityFee_2 +
                priorityFee_3 +
                priorityFee_4 +
                priorityFee_5 +
                priorityFee_6 +
                priorityFee_7 +
                priorityFee_8,
            "executor should have received all priority fees because is a fisher staker"
        );

        assertEq(
            evvm.getBalance(executor.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() * 8,
            "executor should have received rewards because there is a fisher staker"
        );
    }
}
