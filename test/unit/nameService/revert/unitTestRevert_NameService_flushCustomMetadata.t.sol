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
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    NameServiceError
} from "@evvm/testnet-contracts/library/errors/NameServiceError.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";
import {CoreError} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestRevert_NameService_flushCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";
    string constant CUSTOM_METADATA_VALUE_0 = "test>0";
    string constant CUSTOM_METADATA_VALUE_1 = "test>1";
    string constant CUSTOM_METADATA_VALUE_2 = "test>2";

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            1,
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

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_0,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            )
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6
            )
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8
            )
        );
    }

    function _addBalance(
        AccountData memory user,
        string memory usernameToFlushCustomMetadata,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount)
    {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(
                usernameToFlushCustomMetadata
            ) + priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushCustomMetadata(
            usernameToFlushCustomMetadata
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__flushCustomMetadata__InvalidSignatureOnNameService_evvmID()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                /* 🢃 different evvmID 🢃 */
                core.getEvvmID() + 1,
                address(nameService),
                USERNAME,
                address(0),
                nonce
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(USERNAME),
            totalPriorityFeeAmount,
            address(nameService),
            nonceEVVM,
            true
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__InvalidSignatureOnNameService_signer()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__InvalidSignatureOnNameService_identity()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different identity 🢃 */
                "diferent",
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__InvalidSignatureOnNameService_nonce()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                /* 🢃 different nonce 🢃 */
                nonce + 1,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__UserIsNotOwnerOfIdentity()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                0.0001 ether
            );

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfIdentity.selector);
        nameService.flushCustomMetadata(
            /* 🢃 different user 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__EmptyCustomMetadata()
        external
    {
        /* 🢃 identity has no custom metadata 🢃 */
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testing",
            1,
            address(0),
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01
            ),
            address(0),
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
            ),
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff10
            )
        );

        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, "testing", 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                "testing",
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "testing"
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.EmptyCustomMetadata.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "testing",address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata("testing"),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata_NonceAlreadyUsed()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        /* 🢃 nonce already used 🢃 */
        uint256 nonce = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7
        );
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.AsyncNonceAlreadyUsed.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__InvalidSignature_fromEvvm()
        external
    {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_revert__flushCustomMetadata__InsufficientBalance_fromEvvm()
        external
    {
        uint256 nonce = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                0,
                nonceEVVM
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(CoreError.InsufficientBalance.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            address(0),
            nonce,
            signatureNameService,
            0,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance should remain the same after failed flush"
        );
    }
}
