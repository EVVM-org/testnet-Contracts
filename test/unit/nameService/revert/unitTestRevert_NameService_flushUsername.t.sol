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
import {
    EvvmError
} from "@evvm/testnet-contracts/library/errors/EvvmError.sol";

import {
    StateError
} from "@evvm/testnet-contracts/library/errors/StateError.sol";

contract unitTestRevert_NameService_flushUsername is Test, Constants {
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
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            )
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            true
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
            ),
            true
        );

        _executeFn_nameService_addCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                address(nameService),
                USERNAME,
                nonce
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername(USERNAME),
            totalPriorityFeeAmount,
            address(nameService),
            nonceEVVM,
            true
        );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "differentUsername",
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different nonce 🢃 */
                nonce + 1,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.InvalidSignature.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                /* 🢃 non owner address 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfIdentity.selector);
        nameService.flushUsername(
            /* 🢃 non owner address 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.OwnershipExpired.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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
        _executeFn_nameService_preRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "testrevert",
            67,
            uint256(
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                invalidUsername,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(invalidUsername);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(NameServiceError.IdentityIsNotAUsername.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            invalidUsername,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(invalidUsername);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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
        uint256 nonce = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
        );
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonce,
                totalPriorityFeeAmount,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(StateError.AsyncNonceAlreadyUsed.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonce,
                /* 🢃 different totalPriorityFee 🢃 */
                totalPriorityFeeAmount + 50,
                /* 🢃 different nonceEVVM 🢃 */
                nonceEVVM + 1,
                /* 🢃 different isAsyncExec 🢃 */
                false
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmError.InvalidSignature.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            totalPriorityFeeAmount,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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

        uint256 nonce = 110010011;
        uint256 nonceEVVM = 1001;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_flushUsername(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                nonce,
                0,
                nonceEVVM,
                true
            );

        (address userBefore, uint256 expirationDateBefore) = nameService
            .getIdentityBasicMetadata(USERNAME);

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert(EvvmError.InsufficientBalance.selector);
        nameService.flushUsername(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            nonce,
            signatureNameService,
            0,
            nonceEVVM,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            userBefore,
            "Username owner should remain the same after failed flushUsername"
        );
        assertEq(
            expirationDate,
            expirationDateBefore,
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
