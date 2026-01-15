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

contract unitTestRevert_NameService_renewUsername is Test, Constants {
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

    function _addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalRenewalAmount, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.seePriceToRenew(username) + priorityFeeAmount
        );

        totalRenewalAmount = nameService.seePriceToRenew(username);
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__renewUsername__InvalidSignatureOnNameService_evvmID()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
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
            nameService.seePriceToRenew(USERNAME),
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            address(nameService)
        );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InvalidSignatureOnNameService_signer()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InvalidSignatureOnNameService_username()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 67,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__IdentityIsNotAUsername()
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
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, invalidUsername, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                invalidUsername,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.IdentityIsNotAUsername.selector);
        nameService.renewUsername(
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

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__UserIsNotOwnerOfIdentity()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_2, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__RenewalTimeLimitExceeded()
        external
    {
        uint256 nonceLoop = uint256(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
        );
        for (uint256 i = 0; i < 99; i++) {
            evvm.addBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS,
                nameService.seePriceToRenew(USERNAME)
            );

            _execute_makeRenewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceLoop + i,
                0,
                nonceLoop + i,
                true,
                COMMON_USER_NO_STAKER_3
            );
        }

        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.RenewalTimeLimitExceeded.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }


    function test__unit_revert__renewUsername__AsyncNonceAlreadyUsed() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        /* 🢃 reused nonce 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
        );
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    
    function test__unit_revert__renewUsername__InvalidSignature_fromEvvm() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
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

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InsufficientBalance_fromEvvm() external {

        uint256 nonceNameService = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonceNameService,
                0,
                nonceEVVM,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance should not change"
        );
    }
    
}
