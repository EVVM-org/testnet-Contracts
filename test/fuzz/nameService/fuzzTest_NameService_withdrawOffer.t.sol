// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/* _______ __   __ _______ _______   _______ _______ _______ _______ 
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
        uint256 nonceNameService;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityEVVM;
        bytes signatureEVVM;
    }

    function executeBeforeSetUp() internal override {
        _execute_makeRegistrationUsername(
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

        OFFER_ID = _execute_makeMakeOffer(
            USER,
            USERNAME,
            EXPIRATION_DATE,
            AMOUNT_OFFER,
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
        uint256 nonceNameService;
        uint32 priorityFee;
        bool priorityEVVM;
        uint256 nonceAsyncEVVM;
    }

    function test__fuzz__withdrawOffer__noStaking(Input memory input) external {
        vm.assume(
            input.nonceNameService <
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
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
            params.user,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.withdrawOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expireDate,
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
            input.nonceNameService <
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
        Params memory params = Params({
            user: USER,
            username: USERNAME,
            offerID: OFFER_ID,
            nonceNameService: input.nonceNameService,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.priorityEVVM
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER.Address),
            priorityEVVM: input.priorityEVVM,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _execute_makeWithdrawOfferSignatures(
            params.user,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.withdrawOffer(
            params.user.Address,
            params.username,
            params.offerID,
            params.nonceNameService,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.priorityEVVM,
            params.signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(params.username, params.offerID);

        assertEq(
            checkData.offerer,
            address(0),
            "Error: offerer address should be zeroed out"
        );
        assertEq(
            checkData.expireDate,
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
