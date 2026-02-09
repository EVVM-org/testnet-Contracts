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

contract unitTestCorrect_NameService_renewUsername is Test, Constants {
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

    function test__unit_correct__renewUsername__noStaker_noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 1001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 2002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 3003,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 4004,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 89,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params1.user, params1.username, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params1.user,
            params1.username,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params1.user.Address,
            params1.username,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm,
            params1.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "Error on 1: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params2.user, params2.username, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params2.user,
            params2.username,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params2.user.Address,
            params2.username,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm,
            params2.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime2) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            expirationTime2,
            block.timestamp + ((366 days) * 3),
            "Error on 2: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Executing offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        uint256 offerPrice = nameService.seePriceToRenew(USERNAME) * 10;
        _executeMakeOffer(offerPrice);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params3.user, params3.username, params3.priorityFee);

        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params3.user,
            params3.username,
            params3.nonce,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params3.user.Address,
            params3.username,
            params3.nonce,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm,
            params3.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime3) = nameService.getIdentityBasicMetadata(
            params3.username
        );

        assertEq(
            expirationTime3,
            block.timestamp + ((366 days) * 4),
            "Error on 3: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params4.user, params4.username, params4.priorityFee);

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params4.user,
            params4.username,
            params4.nonce,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params4.user.Address,
            params4.username,
            params4.nonce,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm,
            params4.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime4) = nameService.getIdentityBasicMetadata(
            params4.username
        );

        assertEq(
            expirationTime4,
            block.timestamp + ((366 days) * 5),
            "Error on 4: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
    }

    function test__unit_correct__renewUsername__staker_noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 1001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 2002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 3003,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 4004,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 89,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params1.user, params1.username, params1.priorityFee);

        uint256 stakerBalance1 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params1.username) * 50) / 100) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params1.user,
            params1.username,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params1.user.Address,
            params1.username,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm,
            params1.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "Error on 1: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1,
            "Error on 1: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params2.user, params2.username, params2.priorityFee);

        uint256 stakerBalance2 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params2.username) * 50) / 100) +
            params2.priorityFee;

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params2.user,
            params2.username,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params2.user.Address,
            params2.username,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm,
            params2.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime2) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            expirationTime2,
            block.timestamp + ((366 days) * 3),
            "Error on 2: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2,
            "Error on 2: balance incorrectly changed after renewal"
        );
        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Executing offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        uint256 offerPrice = nameService.seePriceToRenew(USERNAME) * 10;
        _executeMakeOffer(offerPrice);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params3.user, params3.username, params3.priorityFee);

        uint256 stakerBalance3 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params3.username) * 50) / 100) +
            params3.priorityFee;
        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params3.user,
            params3.username,
            params3.nonce,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params3.user.Address,
            params3.username,
            params3.nonce,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm,
            params3.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime3) = nameService.getIdentityBasicMetadata(
            params3.username
        );

        assertEq(
            expirationTime3,
            block.timestamp + ((366 days) * 4),
            "Error on 3: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2 + stakerBalance3,
            "Error on 3: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params4.user, params4.username, params4.priorityFee);

        uint256 stakerBalance4 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params4.username) * 50) / 100) +
            params4.priorityFee;

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params4.user,
            params4.username,
            params4.nonce,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params4.user.Address,
            params4.username,
            params4.nonce,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm,
            params4.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime4) = nameService.getIdentityBasicMetadata(
            params4.username
        );

        assertEq(
            expirationTime4,
            block.timestamp + ((366 days) * 5),
            "Error on 4: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2 + stakerBalance3 + stakerBalance4,
            "Error on 4: balance incorrectly changed after renewal"
        );
    }

    function test__unit_correct__renewUsername__noStaker_priorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 1001,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 2002,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 3003,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 4004,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 89,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params1.user, params1.username, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params1.user,
            params1.username,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params1.user.Address,
            params1.username,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm,
            params1.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "Error on 1: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params2.user, params2.username, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params2.user,
            params2.username,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params2.user.Address,
            params2.username,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm,
            params2.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime2) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            expirationTime2,
            block.timestamp + ((366 days) * 3),
            "Error on 2: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Executing offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        uint256 offerPrice = nameService.seePriceToRenew(USERNAME) * 10;
        _executeMakeOffer(offerPrice);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params3.user, params3.username, params3.priorityFee);

        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params3.user,
            params3.username,
            params3.nonce,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params3.user.Address,
            params3.username,
            params3.nonce,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm,
            params3.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime3) = nameService.getIdentityBasicMetadata(
            params3.username
        );

        assertEq(
            expirationTime3,
            block.timestamp + ((366 days) * 4),
            "Error on 3: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params4.user, params4.username, params4.priorityFee);

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params4.user,
            params4.username,
            params4.nonce,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.renewUsername(
            params4.user.Address,
            params4.username,
            params4.nonce,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm,
            params4.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime4) = nameService.getIdentityBasicMetadata(
            params4.username
        );

        assertEq(
            expirationTime4,
            block.timestamp + ((366 days) * 5),
            "Error on 4: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
    }

    function test__unit_correct__renewUsername__staker_priorityFee() external {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 1001,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ),
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 2002,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 67,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        Params memory params3 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 3003,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                USER_USERNAME_OWNER.Address
            ) + 1,
            isAsyncExecEvvm: false,
            signatureEVVM: ""
        });

        Params memory params4 = Params({
            user: USER_USERNAME_OWNER,
            username: USERNAME,
            nonce: 4004,
            signatureNameService: "",
            priorityFee: 0.001 ether,
            nonceEVVM: 89,
            isAsyncExecEvvm: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params1.user, params1.username, params1.priorityFee);

        uint256 stakerBalance1 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params1.username) * 50) / 100) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params1.user,
            params1.username,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params1.user.Address,
            params1.username,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.isAsyncExecEvvm,
            params1.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime1) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            expirationTime1,
            block.timestamp + ((366 days) * 2),
            "Error on 1: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 1: balance incorrectly changed after renewal"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1,
            "Error on 1: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params2.user, params2.username, params2.priorityFee);

        uint256 stakerBalance2 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params2.username) * 50) / 100) +
            params2.priorityFee;

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params2.user,
            params2.username,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params2.user.Address,
            params2.username,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.isAsyncExecEvvm,
            params2.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime2) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            expirationTime2,
            block.timestamp + ((366 days) * 3),
            "Error on 2: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 2: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2,
            "Error on 2: balance incorrectly changed after renewal"
        );
        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Executing offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        uint256 offerPrice = nameService.seePriceToRenew(USERNAME) * 10;
        _executeMakeOffer(offerPrice);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params3.user, params3.username, params3.priorityFee);

        uint256 stakerBalance3 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params3.username) * 50) / 100) +
            params3.priorityFee;
        (
            params3.signatureNameService,
            params3.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params3.user,
            params3.username,
            params3.nonce,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params3.user.Address,
            params3.username,
            params3.nonce,
            params3.signatureNameService,
            params3.priorityFee,
            params3.nonceEVVM,
            params3.isAsyncExecEvvm,
            params3.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime3) = nameService.getIdentityBasicMetadata(
            params3.username
        );

        assertEq(
            expirationTime3,
            block.timestamp + ((366 days) * 4),
            "Error on 3: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 3: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2 + stakerBalance3,
            "Error on 3: balance incorrectly changed after renewal"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async offer ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        _addBalance(params4.user, params4.username, params4.priorityFee);

        uint256 stakerBalance4 = evvm.getRewardAmount() +
            ((nameService.seePriceToRenew(params4.username) * 50) / 100) +
            params4.priorityFee;

        (
            params4.signatureNameService,
            params4.signatureEVVM
        ) = _executeSig_nameService_renewUsername(
            params4.user,
            params4.username,
            params4.nonce,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.renewUsername(
            params4.user.Address,
            params4.username,
            params4.nonce,
            params4.signatureNameService,
            params4.priorityFee,
            params4.nonceEVVM,
            params4.isAsyncExecEvvm,
            params4.signatureEVVM
        );

        vm.stopPrank();

        (, uint256 expirationTime4) = nameService.getIdentityBasicMetadata(
            params4.username
        );

        assertEq(
            expirationTime4,
            block.timestamp + ((366 days) * 5),
            "Error on 4: expiration date incorrectly set after renewal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error on 4: balance incorrectly changed after renewal"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            stakerBalance1 + stakerBalance2 + stakerBalance3 + stakerBalance4,
            "Error on 4: balance incorrectly changed after renewal"
        );
    }
}
