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

contract unitTestRevert_NameService_removeCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";
    uint256 constant INDEX_CUSTOM_METADATA = 0;
    string constant CUSTOM_METADATA_VALUE_0 = "test>0";

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
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
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    )
        private
        returns (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        )
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata() + priorityFeeAmount
        );

        totalPriceRemovedCustomMetadata = nameService
            .getPriceToRemoveCustomMetadata();
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignatureOnNameService_evvmID()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService
            )
        );

        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata(),
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            address(nameService)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignatureOnNameService_signer()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignatureOnNameService_username()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignatureOnNameService_key()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different key 🢃 */
                INDEX_CUSTOM_METADATA + 1,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignatureOnNameService_nonce()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 1,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__UserIsNotOwnerOfIdentity()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = /* 🢃 different user 🢃 */ _addBalance(
                COMMON_USER_NO_STAKER_2,
                0.0001 ether
            );

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);
        nameService.removeCustomMetadata(
            /* 🢃 different user 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__AsyncNonceAlreadyUsed()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        /* 🢃 reused nonce 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
        );
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidKey() external {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 invalid key 🢃 */
                INDEX_CUSTOM_METADATA + 1,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidKey.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            /* 🢃 invalid key 🢃 */
            INDEX_CUSTOM_METADATA + 1,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InvalidSignature_fromEvvm()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1,
                /* 🢃 different priorityFlag 🢃 */
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount,
            "user balance should remain unchanged"
        );
    }

    function test__unit_revert__removeCustomMetadata__InsufficientBalance_fromEvvm()
        external
    {
        uint256 nonceNameService = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonceNameService,
                1 ether,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonceNameService,
            signatureNameService,
            1 ether,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity(USERNAME, INDEX_CUSTOM_METADATA);

        assertEq(
            keccak256(bytes(customMetadata)),
            keccak256(bytes(CUSTOM_METADATA_VALUE_0)),
            "custom metadata should not be removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(USERNAME),
            1,
            "max custom metadata slots should remain unchanged"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance should remain unchanged"
        );
    }
}
