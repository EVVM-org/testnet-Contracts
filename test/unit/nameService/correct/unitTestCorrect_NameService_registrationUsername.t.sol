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

contract unitTestCorrect_NameService_registrationUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_ONE = COMMON_USER_NO_STAKER_1;
    AccountData USER_TWO = COMMON_USER_NO_STAKER_2;

    string USERNAME_ONE = "alice";
    string USERNAME_TWO = "mario";
    uint256 REGISTRATION_LOCK_NUMBER_ONE = 67;
    uint256 REGISTRATION_LOCK_NUMBER_TWO = 89;

    struct Params {
        AccountData user;
        string username;
        uint256 lockNumber;
        uint256 nonce;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bytes signatureEVVM;
    }

    function _addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFee
    )
        private
        returns (uint256 registrationPrice, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username) + priorityFee
        );

        return (nameService.getPriceOfRegistration(username), priorityFee);
    }

    function executeBeforeSetUp() internal override {
        /**
         * @dev Pre-register two usernames for testing
         *      and move time forward to be able to
         *      register them inmediately
         */

        _executeFn_nameService_preRegistrationUsername(
            USER_ONE,
            USERNAME_ONE,
            REGISTRATION_LOCK_NUMBER_ONE,
            0
        );
        _executeFn_nameService_preRegistrationUsername(
            USER_TWO,
            USERNAME_TWO,
            REGISTRATION_LOCK_NUMBER_TWO,
            0
        );

        skip(30 minutes);
    }

    function test__unit_correct__preRegistrationUsername__noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            lockNumber: REGISTRATION_LOCK_NUMBER_ONE,
            nonce: 68,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 420,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            lockNumber: REGISTRATION_LOCK_NUMBER_TWO,
            nonce: 777,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_registrationUsername(
            params1.user,
            params1.username,
            params1.lockNumber,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.lockNumber,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne, ) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            ownerOne,
            params1.user.Address,
            "Error no staker: username not registered correctly"
        );

        assertEq(
            evvm.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_registrationUsername(
            params2.user,
            params2.username,
            params2.lockNumber,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.lockNumber,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo, ) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            ownerTwo,
            params2.user.Address,
            "Error staker: username not registered correctly"
        );
        assertEq(
            evvm.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * evvm.getRewardAmount()) + params2.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            lockNumber: REGISTRATION_LOCK_NUMBER_ONE,
            nonce: 67,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 420,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            lockNumber: REGISTRATION_LOCK_NUMBER_TWO,
            nonce: 777,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 89,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (
            params1.signatureNameService,
            params1.signatureEVVM
        ) = _executeSig_nameService_registrationUsername(
            params1.user,
            params1.username,
            params1.lockNumber,
            params1.nonce,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.lockNumber,
            params1.nonce,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne, ) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(
            ownerOne,
            params1.user.Address,
            "Error no staker: username not registered correctly"
        );

        assertEq(
            evvm.getBalance(params1.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (
            params2.signatureNameService,
            params2.signatureEVVM
        ) = _executeSig_nameService_registrationUsername(
            params2.user,
            params2.username,
            params2.lockNumber,
            params2.nonce,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.lockNumber,
            params2.nonce,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo, ) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(
            ownerTwo,
            params2.user.Address,
            "Error staker: username not registered correctly"
        );
        assertEq(
            evvm.getBalance(params2.user.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * evvm.getRewardAmount()) + params2.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }
}
