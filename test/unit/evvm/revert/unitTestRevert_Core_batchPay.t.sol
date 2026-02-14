// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   ___/ __ \ /  ___\   __\
|    |  |   |  |  ||  |    |  | \  ___/ \___ \ |  |  
|______/|___|  |__||__|    |__|  \___  /____  >|__|  
             \/                      \/     \/       
                                  __                 
_______  _______  __ ____________/  |_               
\_  __ _/ __ \  \/ _/ __ \_  __ \   __\              
 |  | \\  ___/\   /\  ___/|  | \/|  |                
 |__|   \___  >\_/  \___  |__|   |__|                
            \/          \/                                                                                 
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_Core_batchPay is Test, Constants {
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

    function test__unit_revert__batchPay__InvalidSignature_evvmID() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                /* 🢃 different evvmID 🢃 */
                core.getEvvmID() + 1,
                address(core),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                false
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            signatureEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_signer() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_receiverAddress()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different receiverAddress 🢃 */
                COMMON_USER_NO_STAKER_3.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_receiverIdentity()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                /* 🢃 different receiver identity 🢃 */
                "tofailure",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_token() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                /* 🢃 different token address 🢃 */
                PRINCIPAL_TOKEN_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_amount() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 different amount 🢃 */
                amount + 1 ether,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_priorityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 different priority fee 🢃 */
                priorityFee + 1 ether,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_nonce() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                /* 🢃 different nonce 🢃 */
                67,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_isAsyncExec()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                /* 🢃 different priority flag 🢃 */
                true
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__InvalidSignature_executor() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                /* 🢃 different executor 🢃 */
                COMMON_USER_NO_STAKER_3.Address,
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__batchPay__SKIP_SenderIsNotTheExecutor()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            COMMON_USER_STAKER.Address,
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                COMMON_USER_STAKER.Address,
                0,
                false
            )
        );

        /* 🢃 Different executor 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__batchPay__SKIP_AsyncNonceAlreadyUsed()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.20 ether,
            0 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            2
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount / 2,
            0,
            address(0),
            67,
            true,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount / 2,
                0,
                address(0),
                67,
                true
            )
        );

        batchData[1] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount / 2,
            0,
            address(0),
            /* 🢃 same nonce as first transaction 🢃 */
            67,
            true,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount / 2,
                0,
                address(0),
                /* 🢃 same nonce as first transaction 🢃 */
                67,
                true
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, bool[] memory results) = core.batchPay(
            batchData
        );
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            1,
            "There should be 1 successful transaction"
        );

        assertFalse(results[1], "Second transaction should be skipped");

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount / 2 + priorityFee,
            "Sender balance must be half of amount + priority fee the same because pay skipped"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount / 2,
            "Receiver balance must be executed ones because next pay skipped"
        );
    }

    function test__unit_revert__batchPay__SKIP_SyncNonceMismatch() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            /* 🢃 sync nonce missmatch 🢃 */
            9999999,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                /* 🢃 sync nonce missmatch 🢃 */
                9999999,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__batchPay__SKIP_InsufficientBalance_amount()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            /* 🢃 exceeds balance 🢃 */
            (amount + priorityFee) * 10,
            priorityFee,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 exceeds balance 🢃 */
                (amount + priorityFee) * 10,
                priorityFee,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__batchPay__SKIP_InsufficientBalance_priotityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        CoreStructs.BatchData[] memory batchData = new CoreStructs.BatchData[](
            1
        );

        batchData[0] = CoreStructs.BatchData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            /* 🢃 exceeds balance 🢃 */
            (amount + priorityFee) * 10,
            address(0),
            0,
            false,
            _executeSig_evvm_pay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 exceeds balance 🢃 */
                (amount + priorityFee) * 10,
                address(0),
                0,
                false
            )
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        (uint256 successfulTransactions, ) = core.batchPay(batchData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }
}
