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
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bytes signatureEVVM;
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

        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_1,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4
            )
        );
        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_2,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6
            )
        );
        _executeFn_nameService_addCustomMetadata(
            USER_USERNAME_OWNER,
            USERNAME,
            CUSTOM_METADATA_VALUE_3,
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8
            )
        );
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        core.addBalance(
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
            key: 0,
            nonce: 200020002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });


        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params1.user,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_2,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
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
            key: 0,
            nonce: 200020002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.priorityFee);

        uint256 amountReward1 = (5 * core.getRewardAmount()) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params1.user,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_2,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
             amountReward1,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }

    function test__unit_correct__removeCustomMetadata__noStaking_priorityFee()
        external
    {
        

        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            key: 0,
            nonce: 200020002,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

        

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params1.user,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_2,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
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
            key: 0,
            nonce: 200020002,
            signatureNameService: "",
            priorityFee: 0.0001 ether,
            nonceEVVM: 67,
            signatureEVVM: ""
        });

    

        _addBalance(params1.user, params1.priorityFee);

        uint256 amountReward1 = (5 * core.getRewardAmount()) +
            params1.priorityFee;

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_removeCustomMetadata(
            params1.user,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);

        nameService.removeCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.key,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, params1.key);

        assertEq(
            customMetadata2,
            CUSTOM_METADATA_VALUE_2,
            "Error 2: custom metadata incorrectly removed"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            2,
            "Error 2: custom metadata max slots incorrectly changed after removal"
        );

        assertEq(
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error 2: user balance incorrectly changed after removing custom metadata"
        );

        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
             amountReward1,
            "Error 2: fisher balance incorrectly changed after removing custom metadata"
        );
    }
}
