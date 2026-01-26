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

contract unitTestCorrect_NameService_removeCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    string CUSTOM_METADATA_VALUE_1 = "test>1";
    string CUSTOM_METADATA_VALUE_2 = "test>2";
    string CUSTOM_METADATA_VALUE_3 = "test>3";

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
        uint256 key;
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

        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb
            ),
            true
        );
        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa
            ),
            true
        );
        _execute_makeAddCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_3,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9
            ),
            true
        );
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_correct__removeCustomMetadata__noStaking_noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 1,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 0,
            nonceNameService: 200020002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata1,
            CUSTOM_METADATA_VALUE_3,
            "Error 1: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 1: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 1: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: fisher balance incorrectly changed after removing custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, params2.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_3,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            1,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }

    function test__unit_correct__removeCustomMetadata__staking_noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 1,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 0,
            nonceNameService: 200020002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        uint256 amountReward1 = (5 * evvm.getRewardAmount()) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata1,
            CUSTOM_METADATA_VALUE_3,
            "Error 1: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 1: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 1: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountReward1,
            "Error 1: fisher balance incorrectly changed after removing custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        uint256 amountReward2 = (5 * evvm.getRewardAmount()) +
            params2.priorityFee;

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, params2.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_3,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            1,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountReward1 + amountReward2,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }

    function test__unit_correct__removeCustomMetadata__noStaking_priorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 1,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 0,
            nonceNameService: 200020002,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata1,
            CUSTOM_METADATA_VALUE_3,
            "Error 1: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 1: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 1: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: fisher balance incorrectly changed after removing custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, params2.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_3,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            1,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }

    function test__unit_correct__removeCustomMetadata__staking_priorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 1,
            nonceNameService: 100010001,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 0,
            nonceNameService: 200020002,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        uint256 amountReward1 = (5 * evvm.getRewardAmount()) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params1.user,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata1,
            CUSTOM_METADATA_VALUE_3,
            "Error 1: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 1: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 1: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountReward1,
            "Error 1: fisher balance incorrectly changed after removing custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        uint256 amountReward2 = (5 * evvm.getRewardAmount()) +
            params2.priorityFee;

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
            params2.user,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.key,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, params2.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_3,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            1,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountReward1 + amountReward2,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }
}
