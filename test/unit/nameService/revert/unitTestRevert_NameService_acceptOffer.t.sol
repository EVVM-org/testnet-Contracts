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

contract unitTestRevert_NameService_acceptOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    string constant USERNAME = "test";

    uint256 constant EXPIRATION_DATE_OF_OFFER = 30 days;

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

        offerID = _execute_makeMakeOffer(
            COMMON_USER_NO_STAKER_2,
            USERNAME,
            block.timestamp + EXPIRATION_DATE_OF_OFFER,
            0.001 ether,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            ),
            true,
            COMMON_USER_NO_STAKER_3
        );
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            priorityFeeAmount
        );

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_revert__acceptOffer__InvalidSignatureOnNameService_evvmID()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                /* 🢃 different evvmID 🢃 */
                evvm.getEvvmID() + 1,
                USERNAME,
                offerID,
                10000000001
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signatureEVVM = _execute_makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            0,
            amountPriorityFee,
            1001,
            true,
            address(nameService)
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InvalidSignatureOnNameService_signer()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                /* 🢃 different signer 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                offerID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InvalidSignatureOnNameService_username()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                /* 🢃 different username 🢃 */
                "diferent",
                offerID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InvalidSignatureOnNameService_offerId()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                /* 🢃 different offerId 🢃 */
                offerID + 1,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                offerID,
                /* 🢃 different nameServiceNonce 🢃 */
                67,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.InvalidSignatureOnNameService.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__OfferInactive_offerer() external {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );
        /* 🢃 different offerId 🢃 */
        uint256 diferentOfferID = offerID + 67;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                diferentOfferID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.OfferInactive.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            diferentOfferID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__OfferInactive_expireDate()
        external
    {
        /* 🢃 skip after expiration date 🢃 */
        skip(EXPIRATION_DATE_OF_OFFER * 5);

        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                offerID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.OfferInactive.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__AsyncNonceAlreadyUsed() external {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        /* 🢃 reused nonce 🢃 */
        uint256 nonceNameService = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                offerID,
                nonceNameService,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(AsyncNonce.AsyncNonceAlreadyUsed.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            nonceNameService,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__UserIsNotOwnerOfIdentity()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                /* 🢃 not the owner address 🢃 */
                COMMON_USER_NO_STAKER_2,
                USERNAME,
                offerID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(ErrorsLib.UserIsNotOwnerOfIdentity.selector);

        nameService.acceptOffer(
            /* 🢃 not the owner address 🢃 */
            COMMON_USER_NO_STAKER_2.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InvalidSignature_fromEvvm()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                offerID,
                10000000001,
                /* 🢃 different totalPriorityFee 🢃 */
                10 ether,
                /* 🢃 different nonceEVVM 🢃 */
                6767676767,
                /* 🢃 different priorityFlag 🢃 */
                false
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InvalidSignature.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }

    function test__unit_revert__acceptOffer__InsufficientBalance_fromEvvm()
        external
    {
        uint256 amountPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        /* 🢃 insufficient balance 🢃 */
        amountPriorityFee += 1 ether;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                USERNAME,
                offerID,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(EvvmErrorsLib.InsufficientBalance.selector);

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            USERNAME,
            offerID,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        amountPriorityFee -= 1 ether;

        (address user, ) = nameService.getIdentityBasicMetadata(USERNAME);

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Username ownership should not have changed"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee,
            "Balance of offer accepter should not have changed"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Balance of offer maker should not have changed"
        );
    }
    
}
