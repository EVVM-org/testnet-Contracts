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

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

contract unitTestRevert_EVVM_payMultiple is Test, Constants, EvvmStructs {
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

    function test__unit_revert__payMultiple__InvalidSignature_evvmID()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signatureEVVM
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_signer()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_receiverAddress()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different receiverAddress 🢃 */
                COMMON_USER_NO_STAKER_3.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_receiverIdentity()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                address(0),
                /* 🢃 different receiver identity 🢃 */
                "tofailure",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_token()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                /* 🢃 different token address 🢃 */
                PRINCIPAL_TOKEN_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_amount()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 different amount 🢃 */
                amount + 1 ether,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_priorityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 different priority fee 🢃 */
                priorityFee + 1 ether,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_nonce()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                /* 🢃 different nonce 🢃 */
                67,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_priorityFlag()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                /* 🢃 different priority flag 🢃 */
                true,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__InvalidSignature_executor()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                /* 🢃 different executor 🢃 */
                COMMON_USER_NO_STAKER_3.Address
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__payMultiple__SKIP_SenderIsNotTheExecutor()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            COMMON_USER_STAKER.Address,
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                0,
                false,
                COMMON_USER_STAKER.Address
            )
        );

        /* 🢃 Different executor 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__payMultiple__SKIP_AsyncNonceAlreadyUsed()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.20 ether,
            0 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](2);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount / 2,
            0,
            67,
            true,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount / 2,
                0,
                67,
                true,
                address(0)
            )
        );

        payData[1] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount / 2,
            0,
            /* 🢃 same nonce as first transaction 🢃 */
            67,
            true,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount / 2,
                0,
                /* 🢃 same nonce as first transaction 🢃 */
                67,
                true,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, bool[] memory results) = evvm
            .payMultiple(payData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            1,
            "There should be 1 successful transaction"
        );

        assertFalse(results[1], "Second transaction should be skipped");

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount / 2 + priorityFee,
            "Sender balance must be half of amount + priority fee the same because pay skipped"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount / 2,
            "Receiver balance must be executed ones because next pay skipped"
        );
    }

    function test__unit_revert__payMultiple__SKIP_SyncNonceMismatch()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 sync nonce missmatch 🢃 */
            9999999,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                /* 🢃 sync nonce missmatch 🢃 */
                9999999,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__payMultiple__SKIP_InsufficientBalance_amount()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            /* 🢃 exceeds balance 🢃 */
            (amount + priorityFee) * 10,
            priorityFee,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 exceeds balance 🢃 */
                (amount + priorityFee) * 10,
                priorityFee,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }

    function test__unit_revert__payMultiple__SKIP_InsufficientBalance_priotityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        payData[0] = EvvmStructs.PayData(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            /* 🢃 exceeds balance 🢃 */
            (amount + priorityFee) * 10,
            0,
            false,
            address(0),
            _execute_makeSignaturePay(
                COMMON_USER_NO_STAKER_1,
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 exceeds balance 🢃 */
                (amount + priorityFee) * 10,
                0,
                false,
                address(0)
            )
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);
        vm.stopPrank();

        assertEq(
            successfulTransactions,
            0,
            "There should be 0 successful transactions"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee,
            "Sender balance must be the same because pay skipped"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            0,
            "Receiver balance must be 0 because pay skipped"
        );
    }
}
