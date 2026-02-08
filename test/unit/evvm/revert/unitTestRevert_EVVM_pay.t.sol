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
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";
import {
    StateError
} from "@evvm/testnet-contracts/library/errors/StateError.sol";
contract unitTestRevert_EVVM_pay is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        AccountData memory _user,
        address _token,
        uint256 _amount,
        uint256 _priorityFee
    ) private returns (uint256 amount, uint256 priorityFee) {
        evvm.addBalance(_user.Address, _token, _amount + _priorityFee);
        return (_amount, _priorityFee);
    }

    function test__unit_revert__pay__InvalidSignature_evvmID() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 67,
                address(evvm),
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_signer() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_3.PrivateKey,
                address(evvm),
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_receiverAddress()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                /* 🢃 different receiver address 🢃 */
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
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_receiverIdentity()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
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
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_token() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
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
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_amount() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 different amount 🢃 */
                0.67 ether,
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_priorityFee() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 different priorityFee 🢃 */
                0.420 ether,
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_nonce() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
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
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_isAsyncExec() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                0,
                /* 🢃 different isAsyncExec 🢃 */
                true
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__InvalidSignature_executor() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
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
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        evvm.pay(
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

    function test__unit_revert__pay__SenderIsNotTheExecutor() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                COMMON_USER_NO_STAKER_3.Address,
                0,
                false
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        /* 🢃 different executor 🢃 */
        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert(EvvmError.SenderIsNotTheExecutor.selector);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            COMMON_USER_NO_STAKER_3.Address,
            0,
            false,
            signatureEVVM
        );

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

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Fisher balance must be 0 because pay reverted"
        );
    }

    function test__unit_revert__pay__AsyncNonceAlreadyUsed() external {
        (uint256 amountBefore, uint256 priorityFeeBefore) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.1 ether,
            0 ether
        );

        _executeFn_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amountBefore,
            priorityFeeBefore,
            address(0),
            67,
            true,
            COMMON_USER_NO_STAKER_3.Address
        );

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                address(0),
                /* 🢃 async nonce already used 🢃 */
                67,
                true
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            address(0),
            /* 🢃 async nonce already used 🢃 */
            67,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee + priorityFeeBefore,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amountBefore,
            "Receiver balance must be the same because pay reverted"
        );
    }

    function test__unit_revert__pay__SyncNonceMismatch() external {
        (uint256 amountBefore, uint256 priorityFeeBefore) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.1 ether,
            0 ether
        );

        _executeFn_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amountBefore,
            priorityFeeBefore,
            address(0),
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            COMMON_USER_NO_STAKER_3.Address
        );

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                priorityFee,
                /* 🢃 sync nonce currently on 1 🢃 */
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(StateError.SyncNonceMismatch.selector);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 sync nonce currently on 1 🢃 */
            address(0),
            0,
            false,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            amount + priorityFee + priorityFeeBefore,
            "Sender balance must be the same because pay reverted"
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amountBefore,
            "Receiver balance must be the same because pay reverted"
        );
    }

    function test__unit_revert__pay__InsufficientBalance_amount() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                /* 🢃 amount more than current balance 🢃 */
                (amount + priorityFee) * 10,
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

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            /* 🢃 amount more than current balance 🢃 */
            (amount + priorityFee) * 10,
            priorityFee,
            address(0),
            0,
            false,
            signatureEVVM
        );

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

    function test__unit_revert__pay__InsufficientBalance_priorityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                amount,
                /* 🢃 priorityFee more than current balance 🢃 */
                (amount + priorityFee) * 10,
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

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            COMMON_USER_NO_STAKER_2.Address,
            "",
            ETHER_ADDRESS,
            amount,
            /* 🢃 priorityFee more than current balance 🢃 */
            (amount + priorityFee) * 10,
            address(0),
            0,
            false,
            signatureEVVM
        );

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

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, ETHER_ADDRESS),
            0,
            "Fisher balance must be 0 because pay reverted"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Fisher does not receive principal token reward because pay reverted"
        );
    }
}
