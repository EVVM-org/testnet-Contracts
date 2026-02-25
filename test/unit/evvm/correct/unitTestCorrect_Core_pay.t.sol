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

contract unitTestCorrect_Core_pay is Test, Constants {
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

    function test__unit_correct__pay__sync_noStaker_noExecutor() external {
        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
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

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__sync_noStaker_Executor() external {
        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        address executorAddress = COMMON_USER_NO_STAKER_2.Address;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__async_noStaker_noExecutor() external {
        uint256 syncNonce_1 = 67;
        uint256 syncNonce_2 = 89; //🗣️🗣️

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__async_noStaker_Executor() external {
        uint256 syncNonce_1 = 67;
        uint256 syncNonce_2 = 89; //🗣️🗣️

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        address executorAddress = COMMON_USER_NO_STAKER_2.Address;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__sync_staker_noExecutor() external {
        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
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

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (core.getRewardAmount() * 2),
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__sync_staker_Executor() external {
        uint256 syncNonce_1 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = core.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        ) + 1;

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        address executorAddress = COMMON_USER_STAKER.Address;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (core.getRewardAmount() * 2),
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__async_staker_noExecutor() external {
        uint256 syncNonce_1 = 67;
        uint256 syncNonce_2 = 89; //🗣️🗣️

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount() * 2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__async_staker_Executor() external {
        uint256 syncNonce_1 = 67;
        uint256 syncNonce_2 = 89; //🗣️🗣️

        (uint256 amount_1, uint256 priorityFee_1) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        (uint256 amount_2, uint256 priorityFee_2) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.5 ether,
            0.1 ether
        );

        address executorAddress = COMMON_USER_STAKER.Address;

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toAddress ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            core.getRewardAmount() * 2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__denyList() external {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x02); // Activate denyList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        vm.stopPrank();

        _addBalance(COMMON_USER_NO_STAKER_1, ETHER_ADDRESS, 100, 0);

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true
        );

        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true,
            signaturePay
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            100,
            "User 2 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__allowList() external {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01); // Activate allowList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        core.setTokenStatusOnAllowList(ETHER_ADDRESS, true);
        vm.stopPrank();

        _addBalance(COMMON_USER_NO_STAKER_1, ETHER_ADDRESS, 100, 0);

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true
        );

        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true,
            signaturePay
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            100,
            "User 2 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__RewardFlowDistribution_false() external {
        uint256 currentSupply = core.getCurrentSupply();
        uint256 totalSupply = core.getEvvmMetadata().totalSupply;
        uint256 remainingSupply = totalSupply - currentSupply;
        core.addBalance(
            address(this),
            PRINCIPAL_TOKEN_ADDRESS,
            remainingSupply - 1
        );

        vm.startPrank(ADMIN.Address);
        core.proposeChangeRewardFlowDistribution();
        skip(1 days);
        core.acceptChangeRewardFlowDistribution();
        vm.stopPrank();

        _addBalance(COMMON_USER_NO_STAKER_1, ETHER_ADDRESS, 100, 0);

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true
        );

        vm.startPrank(COMMON_USER_STAKER.Address);
        core.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            100,
            0,
            address(0),
            777,
            true,
            signaturePay
        );
        vm.stopPrank();

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            100,
            "User 2 balance after pay is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Staker does not supposed to have reward after pay when reward flow distribution is false"
        );
    }
}
