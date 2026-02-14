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

contract unitTestCorrect_NameService_makeOffer is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;
    AccountData USER = COMMON_USER_NO_STAKER_2;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
        uint256 expiratonDate;
        uint256 amount;
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bytes signatureEVVM;
    }

    function _addBalance(
        AccountData memory user,
        uint256 offerAmount,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalOfferAmount, uint256 totalPriorityFeeAmount)
    {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            offerAmount + priorityFeeAmount
        );
        totalOfferAmount = offerAmount;
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function executeBeforeSetUp() internal override {
        _executeFn_nameService_registrationUsername(
            USER_USERNAME_OWNER,
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

    function test__unit_correct__preRegistrationUsername__noStaking_noPriorityFee()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_noPriorityFee()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__noStaking_priorityFee()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }

    function test__unit_correct__preRegistrationUsername__staking_priorityFee()
        external
    {
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            expiratonDate: block.timestamp + 70 days,
            amount: 1.67 ether,
            nonce: 123,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.amount, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_makeOffer(
            params.user,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.priorityFee,
            params.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.makeOffer(
            params.user.Address,
            params.username,
            params.amount,
            params.expiratonDate,
            address(0),
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        NameServiceStructs.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(USERNAME, 0);

        assertEq(
            checkData.offerer,
            params.user.Address,
            "Error: offerer address not correct"
        );
        assertEq(
            checkData.expirationDate,
            params.expiratonDate,
            "Error: offer expiration date not correct"
        );

        assertEq(
            checkData.amount,
            ((params.amount * 995) / 1000),
            "Error: offer amount not correct"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (core.getRewardAmount() +
                ((params.amount * 125) / 100_000) +
                params.priorityFee),
            "Error: fisherr balance not correct"
        );
    }
}
