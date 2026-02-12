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
import {EvvmError} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

import {
    StateError
} from "@evvm/testnet-contracts/library/errors/StateError.sol";

contract unitTestRevert_NameService_removeCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";
    uint256 constant INDEX_CUSTOM_METADATA = 0;
    string constant CUSTOM_METADATA_VALUE_0 = "test>0";

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            )
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
            )
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                address(nameService),
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce
            )
        );

        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata(),
            totalPriorityFeeAmount,
            address(nameService),
            nonceEVVM,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                INDEX_CUSTOM_METADATA,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different key 🢃 */
                INDEX_CUSTOM_METADATA + 1,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                /* 🢃 different nonce 🢃 */
                nonce + 1,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfIdentity.selector);
        nameService.removeCustomMetadata(
            /* 🢃 different user 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

    function test__unit_revert__removeCustomMetadata_NonceAlreadyUsed()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        /* 🢃 reused nonce 🢃 */
        uint256 nonce = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
        );
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 invalid key 🢃 */
                INDEX_CUSTOM_METADATA + 1,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.InvalidKey.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            /* 🢃 invalid key 🢃 */
            INDEX_CUSTOM_METADATA + 1,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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

        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
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
        uint256 nonce = 10001;
        uint256 nonceEVVM = 20002;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                INDEX_CUSTOM_METADATA,
                nonce,
                1 ether,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            INDEX_CUSTOM_METADATA,
            nonce,
            signatureNameService,
            1 ether,
            nonceEVVM,
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
