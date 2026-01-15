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

contract unitTestRevert_NameService_addCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
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

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    )
        private
        returns (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        )
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );

        totalPriceToAddCustomMetadata = nameService
            .getPriceToAddCustomMetadata();
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__addCustomMetadata__InvalidSignatureOnNameService_evvmID()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                USERNAME,
                customMetadata,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata(),
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            address(nameService)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InvalidSignatureOnNameService_signer()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                customMetadata,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InvalidSignatureOnNameService_identity()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different identity 🢃 */
                "differentIdentity",
                customMetadata,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InvalidSignatureOnNameService_value()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different value 🢃 */
                string.concat(USERNAME, ">2"),
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                customMetadata,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 1,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__UserIsNotOwnerOfIdentity()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = /* 🢃 different user (not owner) 🢃 */
            addBalance(COMMON_USER_NO_STAKER_2, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                /* 🢃 different user (not owner) 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                customMetadata,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);
        nameService.addCustomMetadata(
            /* 🢃 different user (not owner) 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__EmptyCustomMetadata()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        /* 🢃 empty custom metadata 🢃 */
        string memory customMetadata = "";
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                customMetadata,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.EmptyCustomMetadata.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__AsyncNonceAlreadyUsed()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        /* 🢃 reused nonce 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
        );
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                customMetadata,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InvalidSignature_fromEvvm()
        external
    {
        (
            uint256 totalPriceToAddCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                customMetadata,
                nonceNameService,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1,
                /* 🢃 different priorityFlag 🢃 */
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceToAddCustomMetadata + totalPriorityFeeAmount
        );
    }

    function test__unit_revert__addCustomMetadata__InsufficientBalance_fromEvvm()
        external
    {
        string memory customMetadata = string.concat(USERNAME, ">1");
        uint256 nonceNameService = 100010001;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                customMetadata,
                nonceNameService,
                0,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.addCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            customMetadata,
            nonceNameService,
            signatureNameService,
            0,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadataInfo = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, 0);

        assert(
            bytes(customMetadataInfo).length == bytes("").length &&
                keccak256(bytes(customMetadataInfo)) == keccak256(bytes(""))
        );

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME), 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }
}
