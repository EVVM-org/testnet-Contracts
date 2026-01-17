// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function revert behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
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

contract unitTestRevert_NameService_preRegistrationUsername is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 priorityFee) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            priorityFeeAmount
        );

        priorityFee = priorityFeeAmount;
    }

    function test__unit_revert__preRegistrationUsername__InvalidSignatureOnNameService_evvmID()
        external
    {
        uint256 nonceNameService = 1001;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                keccak256(abi.encodePacked("test", uint256(10101))),
                nonceNameService
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked("test", uint256(10101))),
            nonceNameService,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("test", uint256(10101)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__InvalidSignatureOnNameService_signer()
        external
    {
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;
        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                username,
                clowNumber,
                nonceNameService,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;
        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                username,
                clowNumber,
                /* 🢃 different nonce 🢃 */
                nonceNameService + 67,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__InvalidSignatureOnNameService_hashUsername()
        external
    {
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;
        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different hash 🢃 */
                "wrongusername",
                67,
                /**************************/
                nonceNameService,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__AsyncNonceAlreadyUsed()
        external
    {
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;

        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testdifferent",
            67,
            nonceNameService
        );

        (
            bytes memory signatureNameService,

        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                username,
                clowNumber,
                /* 🢃 nonce already used 🢃 */
                nonceNameService,
                0,
                0,
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, clowNumber)),
            /* 🢃 nonce already used 🢃 */
            nonceNameService,
            signatureNameService,
            0,
            0,
            false,
            hex""
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__InvalidSignature_fromEvvm()
        external
    {
        _addBalance(COMMON_USER_NO_STAKER_2, 5 ether);
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;
        (
            bytes memory signatureNameService,
            bytes memory signature_EVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                username,
                clowNumber,
                nonceNameService,
                0.0001 ether,
                6767,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            signatureNameService,
            /* 🢃 different priority fee 🢃 */
            1 ether,
            6767,
            true,
            signature_EVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }

    function test__unit_revert__preRegistrationUsername__InsufficientBalance_fromEvvm()
        external
    {
        string memory username = "test";
        uint256 clowNumber = 10101;
        uint256 nonceNameService = 1001;
        (
            bytes memory signatureNameService,
            bytes memory signature_EVVM
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                username,
                clowNumber,
                nonceNameService,
                0.1 ether,
                676767,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        /* 🢃 insufficient balance to cover priority fee 🢃 */
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameService,
            signatureNameService,
            0.1 ether,
            676767,
            true,
            signature_EVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked(username, uint256(clowNumber)))
                )
            )
        );

        assertEq(user, address(0), "username should not be preregistered");
    }
}
