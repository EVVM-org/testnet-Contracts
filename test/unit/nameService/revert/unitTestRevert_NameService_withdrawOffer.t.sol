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

contract unitTestRevert_NameService_withdrawOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    uint256 offerID;

    uint256 totalPriorityFee ;

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
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

        offerID = _executeFn_nameService_makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            0.001 ether,
            block.timestamp + 30 days,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            ),
            COMMON_USER_NO_STAKER_3
        );

         totalPriorityFee = _addBalance(
            COMMON_USER_NO_STAKER_2,
            0.0001 ether
        );
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            priorityFeeAmount
        );

        return priorityFeeAmount;
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_evvmID()
        external
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                // 🢃 different evvmID 🢃
                core.getEvvmID() + 1,
                address(nameService),
                "test",
                offerID,
                address(0),
                1001
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        bytes memory signaturePay = _executeSig_evvm_pay(
            COMMON_USER_NO_STAKER_2,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            0,
            totalPriorityFee,
            address(nameService),
            2002,
            true
        );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            1001,
            signatureNameService,
            totalPriorityFee,
            2002,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }
    
    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_signer()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                // 🢃 different signer 🢃
                COMMON_USER_NO_STAKER_3,
                "test",
                offerID,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_username()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                // 🢃 different username 🢃
                "differentTest",
                offerID,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_offerId()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                "test",
                // 🢃 different offerId 🢃
                offerID + 1,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignatureOnNameService_nameServiceNonce()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                address(0),
                // 🢃 different nameServiceNonce 🢃
                nonce + 1,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__UserIsNotOwnerOfOffer()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                // 🢃 non owner address 🢃
                COMMON_USER_NO_STAKER_3,
                "test",
                offerID,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(NameServiceError.UserIsNotOwnerOfOffer.selector);
        nameService.withdrawOffer(
            // 🢃 non owner address 🢃
            COMMON_USER_NO_STAKER_3.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer_NonceAlreadyUsed() external {
        

        // 🢃 reused nonce 🢃
        uint256 nonce = uint256(
            0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
        );
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.AsyncNonceAlreadyUsed.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InvalidSignature_fromEvvm()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                address(0),
                nonce,
                // 🢃 different totalPriorityFee 🢃
                totalPriorityFee + 50,
                // 🢃 different noncePay 🢃
                noncePay + 1
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InvalidSignature.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }

    function test__unit_revert__withdrawOffer__InsufficientBalance_fromEvvm()
        external
    {
        

        uint256 nonce = 1001;
        uint256 noncePay = 2002;
        // 🢃 insufficient balance 🢃
        totalPriorityFee += 1 ether;

        (
            bytes memory signatureNameService,
            bytes memory signaturePay
        ) = _executeSig_nameService_withdrawOffer(
                COMMON_USER_NO_STAKER_2,
                "test",
                offerID,
                address(0),
                nonce,
                totalPriorityFee,
                noncePay
            );

        vm.startPrank(COMMON_USER_NO_STAKER_3.Address);

        vm.expectRevert(CoreError.InsufficientBalance.selector);
        nameService.withdrawOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            offerID,
            address(0),
            nonce,
            signatureNameService,
            totalPriorityFee,
            noncePay,
            signaturePay
        );

        vm.stopPrank();

        totalPriorityFee -= 1 ether;

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalPriorityFee,
            "User balance after withdraw offer reverted is incorrect"
        );

        assertEq(
            nameService.getSingleOfferOfUsername("test", offerID).offerer,
            COMMON_USER_NO_STAKER_2.Address,
            "Offer should remain active after withdraw offer reverted"
        );
    }
    
}
