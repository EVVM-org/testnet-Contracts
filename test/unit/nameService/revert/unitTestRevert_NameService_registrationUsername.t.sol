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

contract unitTestRevert_NameService_registrationUsername is Test, Constants {
    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function _addBalance(
        address user,
        string memory username,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 registrationPrice, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username) + priorityFeeAmount
        );

        registrationPrice = nameService.getPriceOfRegistration(username);
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__registrationUsername__InvalidSignatureOnNameService_evvmID()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                evvm.getEvvmID(),
                "test",
                777,
                222
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                nameService.getPriceOfRegistration("test"),
                totalPriorityFeeAmount,
                222,
                true,
                address(nameService)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            222,
            signatureNameService,
            totalPriorityFeeAmount,
            222,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidSignatureOnNameService_signer()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                "test",
                777,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidSignatureOnNameService_username()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "invalid",
                777,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidSignatureOnNameService_clowNumber()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                /* 🢃 different clowNumber 🢃 */
                888,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                /* 🢃 different nameServiceNonce 🢃 */
                67,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert();
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidUsername()
        external
    {
        /* 🢂 username with invalid character '@' 🢀 */
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "@test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "@test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "@test",
                777,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert(ErrorsLib.InvalidUsername.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "@test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("@test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__UsernameAlreadyRegistered()
        external
    {
        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_2,
            "test",
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

        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert(ErrorsLib.UsernameAlreadyRegistered.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(
            owner,
            COMMON_USER_NO_STAKER_2.Address,
            "username owner should be unchanged"
        );
    }

    function test__unit_revert__registrationUsername__AsyncNonceAlreadyUsed()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                /* 🢃 reuse nonce 111 🢃 */
                111,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            /* 🢃 reuse nonce 111 🢃 */
            111,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InvalidSignature_fromEvvm()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        (
            uint256 registrationPrice,
            uint256 totalPriorityFeeAmount
        ) = _addBalance(COMMON_USER_NO_STAKER_1.Address, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                10101,
                totalPriorityFeeAmount,
                /* 🢃 different evvm nonce 🢃 */
                67,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }

    function test__unit_revert__registrationUsername__InsufficientBalance_fromEvvm()
        external
    {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            111
        );

        skip(30 minutes);

        uint256 registrationPrice = nameService.getPriceOfRegistration("test");
        uint256 totalPriorityFeeAmount = 0.001 ether;

        evvm.addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration("test") / 2 + 0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRegistrationUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                10101,
                totalPriorityFeeAmount,
                10001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);
        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);
        nameService.registrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            10001,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            registrationPrice / 2 + totalPriorityFeeAmount,
            "user balance should be the same after revert"
        );

        (address owner, uint256 expirationDate) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(owner, address(0), "username should not be reregistered");

        assertEq(expirationDate, 0, "username expiration date should be zero");
    }
}
