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

contract unitTestRevert_NameService_renewUsername is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            444,
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
    }

    function _addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalRenewalAmount, uint256 totalPriorityFeeAmount)
    {
        core.addBalance(
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
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
            nameService.seePriceToRenew(USERNAME),
            totalPriorityFeeAmount,
            address(nameService),
            nonceEVVM,
            true
        );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                /* 🢃 different nonce 🢃 */
                nonce + 67,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
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
        _executeFn_nameService_preRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testrevert",
            67,
            address(0),
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                invalidUsername,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.IdentityIsNotAUsername.selector);
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            invalidUsername,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
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

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                /* 🢃 different user 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfIdentity.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
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
        uint256 nonceLoopA = uint256(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
        );
        uint256 nonceLoopB = uint256(
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000
        );
        for (uint256 i = 0; i < 99; i++) {
            core.addBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS,
                nameService.seePriceToRenew(USERNAME)
            );

            _executeFn_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonceLoopA + i,
                0,
                nonceLoopB + i,
                COMMON_USER_NO_STAKER_3
            );
        }

        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonce = 11;
        uint256 nonceEVVM = 22;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.RenewalTimeLimitExceeded.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername_NonceAlreadyUsed() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        /* 🢃 reused nonce 🢃 */
        uint256 nonce = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
        );
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.AsyncNonceAlreadyUsed.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InvalidSignature_fromEvvm()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1, USERNAME, 0.001 ether);

        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount,
            "user balance should not change"
        );
    }

    function test__unit_revert__renewUsername__InsufficientBalance_fromEvvm()
        external
    {
        uint256 nonce = 11111111;
        uint256 nonceEVVM = 22222222;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                address(0),
                nonce,
                0,
                nonceEVVM
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InsufficientBalance.selector);
        nameService.renewUsername(
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

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            afterUsernameExpirationTime,
            beforeUsernameExpirationTime,
            "username expiration time should not change"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "user balance should not change"
        );
    }
}
