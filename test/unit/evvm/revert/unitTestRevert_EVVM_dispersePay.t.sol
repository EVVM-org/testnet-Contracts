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
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";

contract unitTestRevert_EVVM_dispersePay is Test, Constants, EvvmStructs {
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

    /**
     * Function to test: dispersePay
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     * EX: Includes executor execution
     * nEX: Does not include executor execution
     * ID: Uses a NameService identity
     * AD: Uses an address
     */

    function test__unit_revert__dispersePay__InvalidSignature_evvmID()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispersePay(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                sha256(abi.encode(toData)),
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

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_signer()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            /* 🢃 different signer 🢃 */
            COMMON_USER_NO_STAKER_3,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_hashList()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        EvvmStructs.DispersePayMetadata[]
            memory toDataFake = new EvvmStructs.DispersePayMetadata[](1);

        toDataFake[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            /* 🢃 causes different hashList 🢃 */
            toDataFake,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_token()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            /* 🢃 different token 🢃 */
            PRINCIPAL_TOKEN_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_amount()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            /* 🢃 different amount 🢃 */
            amount + 1,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_priorityFee()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            /* 🢃 different priorityFee 🢃 */
            priorityFee + 1,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_nonce()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 different nonce 🢃 */
            67,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_priorityFlag()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            /* 🢃 different priorityFlag 🢃 */
            true,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidSignature_executor()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            /* 🢃 different executor 🢃 */
            COMMON_USER_NO_STAKER_3.Address
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(ErrorsLib.InvalidSignature.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__SenderIsNotTheExecutor()
        external
    {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            COMMON_USER_NO_STAKER_3.Address
        );

        /* 🢃 executor different than msg.sender 🢃 */
        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.SenderIsNotTheExecutor.selector);
        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            COMMON_USER_NO_STAKER_3.Address,
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__AsyncNonceAlreadyUsed() external {
        _addBalance(COMMON_USER_NO_STAKER_1, ETHER_ADDRESS, 0.1 ether, 0 ether);

        _execute_makePay(
            COMMON_USER_NO_STAKER_1,
            COMMON_USER_NO_STAKER_3.Address,
            "",
            ETHER_ADDRESS,
            0.1 ether,
            0 ether,
            67,
            true,
            address(0),
            COMMON_USER_NO_STAKER_3
        );

        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 nonce already used 🢃 */
            67,
            true,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.AsyncNonceAlreadyUsed.selector);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 nonce already used 🢃 */
            67,
            true,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__SyncNonceMismatch() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 wrong nonce 🢃 */
            999999999999999999,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.SyncNonceMismatch.selector);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            /* 🢃 wrong nonce 🢃 */
            999999999999999999,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InsufficientBalance_amount() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            /* 🢃 amount for [0] too high 🢃 */
            amount: amount + priorityFee,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            /* 🢃 amount for [1] too high 🢃 */
            amount: amount + priorityFee,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            /* 🢃 amount too high 🢃 */
            (amount + priorityFee) * 2,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            /* 🢃 amount too high 🢃 */
            (amount + priorityFee) * 2,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InsufficientBalance_priorityFee() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 2,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            /* 🢃 priorityFee too high 🢃 */
            (amount + priorityFee) * 2,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            /* 🢃 priorityFee too high 🢃 */
            (amount + priorityFee) * 2,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }

    function test__unit_revert__dispersePay__InvalidAmount() external {
        (uint256 amount, uint256 priorityFee) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            ETHER_ADDRESS,
            0.10 ether,
            0.01 ether
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: amount / 5,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: amount / 5,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signature = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidAmount.selector);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            ETHER_ADDRESS,
            amount,
            priorityFee,
            0,
            false,
            address(0),
            signature
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
            "Receiver balance must be zero because pay reverted"
        );
    }
    
}
