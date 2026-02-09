// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**                                                                                                        
██  ██ ▄▄  ▄▄ ▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄ ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄ 
██  ██ ███▄██ ██   ██       ██   ██▄▄  ███▄▄   ██   
▀████▀ ██ ▀██ ██   ██       ██   ██▄▄▄ ▄▄██▀   ██   
                                                    
                                                    
                                                    
 ▄▄▄▄  ▄▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄▄  ▄▄▄▄ ▄▄▄▄▄▄          
██▀▀▀ ██▀██ ██▄█▄ ██▄█▄ ██▄▄  ██▀▀▀   ██            
▀████ ▀███▀ ██ ██ ██ ██ ██▄▄▄ ▀████   ██                                                    
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

contract unitTestCorrect_NameService_acceptOffer is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;
    AccountData USER = COMMON_USER_NO_STAKER_2;

    uint256 OFFER_ID;
    uint256 AMOUNT_OFFER = 1 ether;
    uint256 EXPIRATION_DATE = block.timestamp + 30 days;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
        uint256 offerID;
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool isAsyncExecEvvm;
        bytes signatureEVVM;
    }

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            USER_USERNAME_OWNER,
            USERNAME,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
            )
        );

        OFFER_ID = _executeFn_nameService_makeOffer(
            USER,
            USERNAME,
            AMOUNT_OFFER,
            EXPIRATION_DATE,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            true,
            GOLDEN_STAKER
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

        return priorityFeeAmount;
    }

    function test__unit_correct__acceptOffer__noStaking_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_NO_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__noStaking_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_NO_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__noStaking_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_NO_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__noStaking_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_NO_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__staking_noPriorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                params.priorityFee),
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__staking_noPriorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                params.priorityFee),
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__staking_priorityFee_sync()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                params.priorityFee),
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__acceptOffer__staking_priorityFee_async()
        external
    {
        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_acceptOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.prank(FISHER_STAKER.Address);
        nameService.acceptOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expirationDate,
            EXPIRATION_DATE,
            "Error: offer expiration date should remain the same"
        );

        assertEq(
            checkData.amount,
            ((AMOUNT_OFFER * 995) / 1000),
            "Error: offer amount should remain the same"
        );

        (address owner, ) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            owner,
            USER.Address,
            "Error: username owner not updated correctly"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount()) +
                (((checkData.amount * 1) / 199) / 4) +
                params.priorityFee),
            "Error staker: balance incorrectly changed after registration"
        );
    }
}
