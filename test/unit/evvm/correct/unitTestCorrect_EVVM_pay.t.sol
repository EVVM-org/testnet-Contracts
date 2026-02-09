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
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestCorrect_EVVM_pay is Test, Constants {
    function executeBeforeSetUp() internal override {
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
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
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

    function test__unit_correct__pay__sync_noStaker_noExecutor() external {
        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__sync_noStaker_Executor() external {
        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toAddress"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User 2 does not supposed to have reward after pay with toIdentity"
        );
    }

    function test__unit_correct__pay__sync_staker_noExecutor() external {
        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (evvm.getRewardAmount() * 2),
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }

    function test__unit_correct__pay__sync_staker_Executor() external {
        uint256 syncNonce_1 = evvm.getNextCurrentSyncNonce(
            COMMON_USER_NO_STAKER_1.Address
        );
        uint256 syncNonce_2 = evvm.getNextCurrentSyncNonce(
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            false,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (evvm.getRewardAmount() * 2),
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            address(0),
            syncNonce_1,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_2 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            address(0),
            syncNonce_2,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() * 2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
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

        bytes memory signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount_1,
            priorityFee_1,
            executorAddress,
            syncNonce_1,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount_1 + priorityFee_2,
            "User 1 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1,
            "User 2 balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount(),
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1,
            "Staker balance after pay with toAddress is incorrect check if staker validation or _updateBalance is correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing toIdentity ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        signatureEVVM = _executeSig_evvm_pay(
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
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            address(0),
            "dummy",
            ETHER_ADDRESS,
            amount_2,
            priorityFee_2,
            executorAddress,
            syncNonce_2,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "User 1 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount_1 + amount_2,
            "User 2 balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            evvm.getRewardAmount() * 2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            priorityFee_1 + priorityFee_2,
            "Staker balance after pay with toIdentity is incorrect check if staker validation or _updateBalance is correct"
        );
    }
}
