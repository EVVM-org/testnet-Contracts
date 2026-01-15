// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM functions
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/nameService/lib/ErrorsLib.sol";
import {
    ErrorsLib as EvvmErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";
import {
    AsyncNonce
} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";

contract unitTestRevert_NameService_flushCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";
    string constant CUSTOM_METADATA_VALUE_0 = "test>0";
    string constant CUSTOM_METADATA_VALUE_1 = "test>1";
    string constant CUSTOM_METADATA_VALUE_2 = "test>2";

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            )
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
            ),
            true
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            true
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            true
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
        evvm.addBalance(
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

    function test__unit_correct__flushCustomMetadata__InvalidSignatureOnNameService_evvmID()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                USERNAME,
                nonceNameService
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(USERNAME),
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            address(nameService)
        );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__InvalidSignatureOnNameService_signer()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__InvalidSignatureOnNameService_identity()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different identity 🢃 */
                "diferent",
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__InvalidSignatureOnNameService_nonce()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 1,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__UserIsNotOwnerOfIdentity()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            /* 🢃 different user 🢃 */
            COMMON_USER_NO_STAKER_2,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);
        nameService.flushCustomMetadata(
            /* 🢃 different user 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__EmptyCustomMetadata()
        external
    {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testing",
            1,
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff01
            ),
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
            )
        );

        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            "testing",
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "testing",
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            "testing"
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.EmptyCustomMetadata.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "testing",
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata("testing"),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__AsyncNonceAlreadyUsed()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
        );
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__InvalidSignature_fromEvvm()
        external
    {
        (uint256 totalAmountFlush, uint256 totalPriorityFeeAmount) = _addBalance(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            0.0001 ether
        );

        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1,
                /* 🢃 different priorityFlag 🢃 */
                false
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "user balance should remain the same after failed flush"
        );
    }

    function test__unit_correct__flushCustomMetadata__InsufficientBalance_fromEvvm()
        external
    {
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1000001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                0,
                nonceEVVM,
                true
            );

        uint256 amountOfSlotsBefore = nameService.getAmountOfCustomMetadata(
            USERNAME
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.flushCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonceNameService,
            signatureNameService,
            0,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getAmountOfCustomMetadata(USERNAME),
            amountOfSlotsBefore,
            "custom metadata slots should remain the same after failed flush"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance should remain the same after failed flush"
        );
    }
}
