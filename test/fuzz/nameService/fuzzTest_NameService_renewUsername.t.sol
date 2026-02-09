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

contract fuzzTest_NameService_renewUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;
    AccountData USER = COMMON_USER_NO_STAKER_2;

    uint256 OFFER_ID;
    uint256 EXPIRATION_DATE = block.timestamp + 30 days;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string username;
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
    }

    function _executeMakeOffer(uint256 amount) internal {
        _executeFn_nameService_makeOffer(
            USER,
            USERNAME,
            amount,
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
        string memory username,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.seePriceToRenew(username) + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    struct Input {
        uint256 nonce;
        uint16 priorityFee;
        uint256 nonceAsyncEVVM;
        bool isAsyncExecEvvm;
        bool hasOffer;
        uint112 offerAmount;
    }

    function test__fuzz__renewUsername__noStaker(Input memory input) external {
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
        vm.assume(input.nonceAsyncEVVM != input.nonce);

        if (input.hasOffer) {
            vm.assume(input.offerAmount > 0);
            _executeMakeOffer(uint256(input.offerAmount));
        }

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "balance incorrectly changed after renewal"
        );
    }

    function test__fuzz__renewUsername__staker(Input memory input) external {
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

        vm.assume(input.nonceAsyncEVVM != input.nonce);

        if (input.hasOffer) {
            vm.assume(input.offerAmount > 0);
            _executeMakeOffer(uint256(input.offerAmount));
        }

        Params memory params = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: input.nonce,
            signatureNameService: "",
            priorityFee: input.priorityFee,
            nonceEVVM: input.isAsyncExecEvvm
                ? input.nonceAsyncEVVM
                : evvm.getNextCurrentSyncNonce(USER_USERNAME_OWNER.Address),
            isAsyncExecEvvm: input.isAsyncExecEvvm,
            signatureEVVM: ""
        });

        uint256 stakerBalance = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params.username) * 50) / 100) +
            params.priorityFee;

        _addBalance(params.user, params.username, params.priorityFee);

        (
            params.signatureNameService,
            params.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params.user,
            params.username,
            params.nonce,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params.user.Address,
            params.username,
            params.nonce,
            params.signatureNameService,
            params.priorityFee,
            params.nonceEVVM,
            params.isAsyncExecEvvm,
            params.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance,
            "balance incorrectly changed after renewal"
        );
    }
}
