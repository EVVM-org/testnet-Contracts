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

contract unitTestRevert_NameService_flushUsername is Test, Constants {
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
            nameService.getPriceToFlushUsername(usernameToFlushCustomMetadata) +
                priorityFeeAmount
        );

        totalAmountFlush = nameService.getPriceToFlushUsername(
            usernameToFlushCustomMetadata
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__flushUsername__InvalidSignatureOnNameService_evvmID() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                USERNAME,
                nonceNameService
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername(USERNAME),
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            address(nameService)
        );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__InvalidSignatureOnNameService_signer() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__InvalidSignatureOnNameService_username() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__InvalidSignatureOnNameService_nonce() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 1,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__UserIsNotOwnerOfIdentity() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
                        /* 🢃 non owner address 🢃 */
        ) = _addBalance(COMMON_USER_NO_STAKER_2, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                /* 🢃 non owner address 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);
        nameService.flushUsername(
            /* 🢃 non owner address 🢃 */
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }


    function test__unit_revert__flushUsername__OwnershipExpired() external {
        /* 🢃 advance time to expire ownership 🢃 */
        skip(800 days);
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.OwnershipExpired.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__IdentityIsNotAUsername()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testrevert",
            67,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffA
            )
        );

        /* 🢃 flagNotAUsername == 0x01 🢃 */
        string memory invalidUsername = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(
                keccak256(abi.encodePacked("testrevert", uint256(67)))
            )
        );

        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, invalidUsername, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                invalidUsername,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(invalidUsername);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.IdentityIsNotAUsername.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            invalidUsername,
            nonceNameService,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(invalidUsername);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }


    function test__unit_revert__flushUsername__AsyncNonceAlreadyUsed() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        /* 🢃 nonce already used 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
        );
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__InvalidSignature_fromEvvm() external {
        (
            uint256 totalAmountFlush,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.0001 ether);

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
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

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalAmountFlush + totalPriorityFeeAmount,
            "User balance should remain the same after failed flushUsername"
        );
    }

    function test__unit_revert__flushUsername__InsufficientBalance_fromEvvm() external {

        uint256 nonceNameService = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeFlushUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                0,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expireDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.flushUsername(
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

        (address user, uint256 expireDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expireDate,
            expireDateBefore,
            "Username expire date should remain the same after failed flushUsername"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "User balance should remain the same after failed flushUsername"
        );
    }
    
}
