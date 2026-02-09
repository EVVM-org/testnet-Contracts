// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/** 
 _______ __   __ _______ _______   _______ _______ _______ _______ 
|       |  | |  |       |       | |       |       |       |       |
|    ___|  | |  |____   |____   | |_     _|    ___|  _____|_     _|
|   |___|  |_|  |____|  |____|  |   |   | |   |___| |_____  |   |  
|    ___|       | ______| ______|   |   | |    ___|_____  | |   |  
|   |   |       | |_____| |_____    |   | |   |___ _____| | |   |  
|___|   |_______|_______|_______|   |___| |_______|_______| |___|  
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import "@evvm/testnet-contracts/library/structs/NameServiceStructs.sol";

contract fuzzTest_NameService_withdrawOffer is Test, Constants {
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

    struct Input {
        uint256 nonce;
        uint32 priorityFee;
        bool isAsyncExecEvvm;
        uint256 nonceAsyncEVVM;
    }

    function test__fuzz__withdrawOffer__noStaking(Input memory input) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(input.nonce != input.nonceAsyncEVVM);
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_withdrawOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.withdrawOffer(
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

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((checkData.amount * 1) / 796) +
                params.priorityFee),
            "Error: fisher balance not correct"
        );
    }


    function test__fuzz__withdrawOffer__staking(Input memory input) external {
        vm.assume(
            input.nonce <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );

        vm.assume(
            input.nonceAsyncEVVM <
                uint256(
                    0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
                )
        );
        vm.assume(input.nonce != input.nonceAsyncEVVM);
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_withdrawOffer(
            params.user,
            params.username,
            params.offerID,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.withdrawOffer(
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

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() +
                ((checkData.amount * 1) / 796) +
                params.priorityFee),
            "Error: fisher balance not correct"
        );
    }
}
