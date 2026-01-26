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

contract unitTestCorrect_NameService_registrationUsername is Test, Constants {
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    AccountData USER_ONE = COMMON_USER_NO_STAKER_1;
    AccountData USER_TWO = COMMON_USER_NO_STAKER_2;

    string USERNAME_ONE = "alice";
    string USERNAME_TWO = "mario";
    uint256 REGISTRATION_CLOW_NUMBER_ONE = 67;
    uint256 REGISTRATION_CLOW_NUMBER_TWO = 89;

    struct Params {
        AccountData user;
        string username;
        uint256 clowNumber;
        uint256 nonceNameService;
        bytes signatureNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityEVVM;
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

        _execute_makePreRegistrationUsername(
            USER_ONE,
            USERNAME_ONE,
            REGISTRATION_CLOW_NUMBER_ONE,
            0
        );
        _execute_makePreRegistrationUsername(
            USER_TWO,
            USERNAME_TWO,
            REGISTRATION_CLOW_NUMBER_TWO,
            0
        );

        skip(30 minutes);
    }

    function test__unit_correct__preRegistrationUsername__noPriorityFee_sync()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            clowNumber: REGISTRATION_CLOW_NUMBER_ONE,
            nonceNameService: 67,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER_ONE.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            clowNumber: REGISTRATION_CLOW_NUMBER_TWO,
            nonceNameService: 89,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER_TWO.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1.signatureNameService, params1.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params1.user,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.clowNumber,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne,) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(ownerOne, params1.user.Address, "Error no staker: username not registered correctly");

        assertEq(
            evvm.getBalance(
                params1.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );


        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2.signatureNameService, params2.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params2.user,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.clowNumber,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo,) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(ownerTwo, params2.user.Address, "Error staker: username not registered correctly");
        assertEq(
            evvm.getBalance(
                params2.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * evvm.getRewardAmount()) + params2.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__preRegistrationUsername__noPriorityFee_async()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            clowNumber: REGISTRATION_CLOW_NUMBER_ONE,
            nonceNameService: 67,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            clowNumber: REGISTRATION_CLOW_NUMBER_TWO,
            nonceNameService: 89,
            signatureNameService: "",
            priorityFee: 0,
            nonceEVVM: 89,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1.signatureNameService, params1.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params1.user,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.clowNumber,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne,) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(ownerOne, params1.user.Address, "Error no staker: username not registered correctly");

        assertEq(
            evvm.getBalance(
                params1.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );


        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2.signatureNameService, params2.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params2.user,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.clowNumber,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo,) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(ownerTwo, params2.user.Address, "Error staker: username not registered correctly");
        assertEq(
            evvm.getBalance(
                params2.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * evvm.getRewardAmount()) + params2.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee_sync()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            clowNumber: REGISTRATION_CLOW_NUMBER_ONE,
            nonceNameService: 67,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER_ONE.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            clowNumber: REGISTRATION_CLOW_NUMBER_TWO,
            nonceNameService: 89,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(USER_TWO.Address),
            priorityEVVM: false,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1.signatureNameService, params1.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params1.user,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.clowNumber,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne,) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(ownerOne, params1.user.Address, "Error no staker: username not registered correctly");

        assertEq(
            evvm.getBalance(
                params1.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );


        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2.signatureNameService, params2.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params2.user,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.clowNumber,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo,) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(ownerTwo, params2.user.Address, "Error staker: username not registered correctly");
        assertEq(
            evvm.getBalance(
                params2.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (50 * evvm.getRewardAmount()) + params2.priorityFee,
            "Error staker: balance incorrectly changed after registration"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee_async()
        external
    {
        Params memory params1 = Params({
            user: USER_ONE,
            username: USERNAME_ONE,
            clowNumber: REGISTRATION_CLOW_NUMBER_ONE,
            nonceNameService: 67,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 67,
            priorityEVVM: true,
            signatureEVVM: ""
        });
        Params memory params2 = Params({
            user: USER_TWO,
            username: USERNAME_TWO,
            clowNumber: REGISTRATION_CLOW_NUMBER_TWO,
            nonceNameService: 89,
            signatureNameService: "",
            priorityFee: 0.00001 ether,
            nonceEVVM: 89,
            priorityEVVM: true,
            signatureEVVM: ""
        });

        _addBalance(params1.user, params1.username, params1.priorityFee);
        _addBalance(params2.user, params2.username, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1.signatureNameService, params1.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params1.user,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);
        nameService.registrationUsername(
            params1.user.Address,
            params1.username,
            params1.clowNumber,
            params1.nonceNameService,
            params1.signatureNameService,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        (address ownerOne,) = nameService.getIdentityBasicMetadata(
            params1.username
        );

        assertEq(ownerOne, params1.user.Address, "Error no staker: username not registered correctly");

        assertEq(
            evvm.getBalance(
                params1.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error no staker: balance incorrectly changed after registration"
        );


        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2.signatureNameService, params2.signatureEVVM) =
            _execute_makeRegistrationUsernameSignatures(
                params2.user,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.registrationUsername(
            params2.user.Address,
            params2.username,
            params2.clowNumber,
            params2.nonceNameService,
            params2.signatureNameService,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        (address ownerTwo,) = nameService.getIdentityBasicMetadata(
            params2.username
        );

        assertEq(ownerTwo, params2.user.Address, "Error staker: username not registered correctly");
        assertEq(
            evvm.getBalance(
                params2.user.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
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
