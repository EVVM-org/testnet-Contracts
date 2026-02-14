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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestCorrect_Core_batchPay is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;
    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            444,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            address(0),
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
        core.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    function test__unit_correct__batchPay__noStaker() external {
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

        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;
        uint256 syncNonce_3 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 2;
        uint256 syncNonce_4 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 3;

        uint256 asyncNonce_1 = 67;
        uint256 asyncNonce_2 = 420;
        uint256 asyncNonce_3 = 1337;
        uint256 asyncNonce_4 = 7331;

        AccountData memory executor = COMMON_USER_NO_STAKER_3;

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            8
        );

        bytes memory signature;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Sync execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        signature = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false
        );
        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signature
        );

        /* 🢃 toAddress -- Executor 🢃 */
        batchData[1] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executor.Address,
            syncNonce_2,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_2,
                priorityFee_2,
                executor.Address,
                syncNonce_2,
                false
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        batchData[2] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_3,
            priorityFee_3,
            address(0),
            syncNonce_3,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_3,
                priorityFee_3,
                address(0),
                syncNonce_3,
                false
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        batchData[3] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_4,
            priorityFee_4,
            executor.Address,
            syncNonce_4,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_4,
                priorityFee_4,
                executor.Address,
                syncNonce_4,
                false
            )
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Async execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        batchData[4] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_5,
            priorityFee_5,
            address(0),
            syncNonce_1,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_5,
                priorityFee_5,
                address(0),
                syncNonce_1,
                true
            )
        );

        /* 🢃 toAddress -- Executor 🢃 */
        batchData[5] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_6,
            priorityFee_6,
            executor.Address,
            asyncNonce_2,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_6,
                priorityFee_6,
                executor.Address,
                asyncNonce_2,
                true
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        batchData[6] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_7,
            priorityFee_7,
            address(0),
            asyncNonce_3,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_7,
                priorityFee_7,
                address(0),
                asyncNonce_3,
                true
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        batchData[7] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_8,
            priorityFee_8,
            executor.Address,
            asyncNonce_4,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_8,
                priorityFee_8,
                executor.Address,
                asyncNonce_4,
                true
            )
        );

        vm.startPrank(executor.Address);
        (uint256 successfulTransactions, bool[] memory results) = core.batchPay(
            batchData
        );
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
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
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
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
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
            core.getBalance(executor.Address, ETHER_ADDRESS),
            0,
            "executor should not have received any priority fees because there is no fisher staker"
        );

        assertEq(
            core.getBalance(executor.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "executor should not have received any rewards because there is no fisher staker"
        );
    }

    function test__unit_correct__batchPay__staker() external {
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

        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;
        uint256 syncNonce_3 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 2;
        uint256 syncNonce_4 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 3;

        uint256 asyncNonce_1 = 67;
        uint256 asyncNonce_2 = 420;
        uint256 asyncNonce_3 = 1337;
        uint256 asyncNonce_4 = 7331;

        AccountData memory executor = COMMON_USER_STAKER;

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            8
        );

        bytes memory signature;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Sync execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        signature = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false
        );
        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signature
        );

        /* 🢃 toAddress -- Executor 🢃 */
        batchData[1] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executor.Address,
            syncNonce_2,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_2,
                priorityFee_2,
                executor.Address,
                syncNonce_2,
                false
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        batchData[2] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_3,
            priorityFee_3,
            address(0),
            syncNonce_3,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_3,
                priorityFee_3,
                address(0),
                syncNonce_3,
                false
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        batchData[3] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_4,
            priorityFee_4,
            executor.Address,
            syncNonce_4,
            false,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_4,
                priorityFee_4,
                executor.Address,
                syncNonce_4,
                false
            )
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Async execution ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        /* 🢃 toAddress -- No executor 🢃 */
        batchData[4] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_5,
            priorityFee_5,
            address(0),
            syncNonce_1,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_5,
                priorityFee_5,
                address(0),
                syncNonce_1,
                true
            )
        );

        /* 🢃 toAddress -- Executor 🢃 */
        batchData[5] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_6,
            priorityFee_6,
            executor.Address,
            asyncNonce_2,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount_6,
                priorityFee_6,
                executor.Address,
                asyncNonce_2,
                true
            )
        );

        /* 🢃 toUsername -- No executor 🢃 */
        batchData[6] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_7,
            priorityFee_7,
            address(0),
            asyncNonce_3,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_7,
                priorityFee_7,
                address(0),
                asyncNonce_3,
                true
            )
        );

        /* 🢃 toUsername -- Executor 🢃 */
        batchData[7] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_8,
            priorityFee_8,
            executor.Address,
            asyncNonce_4,
            true,
            signature = _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                "dummy",
                ETHER_ADDRESS,
                amount_8,
                priorityFee_8,
                executor.Address,
                asyncNonce_4,
                true
            )
        );

        vm.startPrank(executor.Address);
        (uint256 successfulTransactions, bool[] memory results) = core.batchPay(
            batchData
        );
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
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
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
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "sender should have send all priority fees because there is a fisher staker"
        );

        assertEq(
            core.getBalance(executor.Address, ETHER_ADDRESS),
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
            core.getBalance(executor.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount() * 8,
            "executor should have received rewards because there is a fisher staker"
        );
    }
}
