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

contract unitTestCorrect_NameService_addCustomMetadata is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_USERNAME_OWNER = COMMON_USER_NO_STAKER_1;

    uint256 OFFER_ID;
    uint256 EXPIRATION_DATE = block.timestamp + 30 days;

    string USERNAME = "alice";

    struct Params {
        AccountData user;
        string identity;
        string value;
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
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe
            ),
            address(0),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc
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
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function test__unit_correct__addCustomMetadata__noStaker() external {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonce: 20002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 22,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonce: 40004,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 44,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_addCustomMetadata(
            params1.user,
            params1.identity,
            params1.value,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.value,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, 0);

        assertEq(
            customMetadata1,
            params1.value,
            "Error 1: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            1,
            "Error 1: custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_addCustomMetadata(
            params2.user,
            params2.identity,
            params2.value,
            address(0),
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.addCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.value,
            address(0),
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, 1);

        assertEq(
            customMetadata2,
            params2.value,
            "Error 2: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            2,
            "Error 2: custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: fisher balance incorrectly changed after adding custom metadata"
        );
    }

    function test__unit_correct__addCustomMetadata__staker() external {
        Params memory params1 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonce: 20002,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 22,
            signatureEVVM: ""
        });

        Params memory params2 = Params({
            user: USER_USERNAME_OWNER,
            identity: USERNAME,
            value: "test>1",
            nonce: 40004,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 44,
            signatureEVVM: ""
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async no priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params1.user, params1.priorityFee);

        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_addCustomMetadata(
            params1.user,
            params1.identity,
            params1.value,
            address(0),
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        uint256 amountToReward1 = (5 * core.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params1.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params1.user.Address,
            params1.identity,
            params1.value,
            address(0),
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata1 = nameService
            .getSingleCustomMetadataOfIdentity(params1.identity, 0);

        assertEq(
            customMetadata1,
            params1.value,
            "Error 1: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params1.identity),
            1,
            "Error 1: custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 1: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward1,
            "Error 1: fisher balance incorrectly changed after adding custom metadata"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async priorityFee ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        _addBalance(params2.user, params2.priorityFee);

        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_addCustomMetadata(
            params2.user,
            params2.identity,
            params2.value,
            address(0),
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM
        );

        uint256 amountToReward2 = (5 * core.getRewardAmount()) +
            ((nameService.getPriceToAddCustomMetadata() * 50) / 100) +
            params2.priorityFee;

        vm.startPrank(FISHER_STAKER.Address);

        nameService.addCustomMetadata(
            params2.user.Address,
            params2.identity,
            params2.value,
            address(0),
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata2 = nameService
            .getSingleCustomMetadataOfIdentity(params2.identity, 1);

        assertEq(
            customMetadata2,
            params2.value,
            "Error 2: custom metadata value incorrect"
        );

        assertEq(
            nameService.getCustomMetadataMaxSlotsOfIdentity(params2.identity),
            2,
            "Error 2: custom metadata slots incorrect"
        );

        assertEq(
            core.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error 2: user balance incorrectly changed after adding custom metadata"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            amountToReward2 + amountToReward1,
            "Error 2: fisher balance incorrectly changed after adding custom metadata"
        );
    }
}
