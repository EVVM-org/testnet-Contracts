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

contract unitTestCorrect_NameService_preRegistrationUsername is
    Test,
    Constants
{
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    struct Params {
        AccountData user;
        string username;
        uint256 clowNumber;
        uint256 nonceNameService;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bool priorityEVVM;
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFee
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFee);

        return priorityFee;
    }

    function test__unit_correct__preRegistrationUsername__noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: "testfirst",
            clowNumber: 1001,
            nonceNameService: 10101,
            priorityFee: 0,
            nonceEVVM: 0,
            priorityEVVM: false
        });

        Params memory params2 = Params({
            user: COMMON_USER_NO_STAKER_2,
            username: "testsecond",
            clowNumber: 2002,
            nonceNameService: 20202,
            priorityFee: 0,
            nonceEVVM: 0,
            priorityEVVM: false
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceOne,
            bytes memory signatureEvvmOne
        ) = _execute_makePreRegistrationUsernameSignature(
                params1.user,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            params1.user.Address,
            keccak256(
                abi.encodePacked(params1.username, uint256(params1.clowNumber))
            ),
            params1.nonceNameService,
            signatureNameServiceOne,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            signatureEvvmOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params1.username,
                            uint256(params1.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Error NonStaker: username not preregistered correctly"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceTwo,
            bytes memory signatureEvvmTwo
        ) = _execute_makePreRegistrationUsernameSignature(
                params2.user,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.preRegistrationUsername(
            params2.user.Address,
            keccak256(
                abi.encodePacked(params2.username, uint256(params2.clowNumber))
            ),
            params2.nonceNameService,
            signatureNameServiceTwo,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            signatureEvvmTwo
        );
        vm.stopPrank();
        (user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params2.username,
                            uint256(params2.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_2.Address,
            "Error Staker: username not preregistered correctly"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount(),
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee_sync()
        external
    {
        Params memory params1 = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: "testfirst",
            clowNumber: 1001,
            nonceNameService: 10101,
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_1.Address
            ),
            priorityEVVM: false
        });

        Params memory params2 = Params({
            user: COMMON_USER_NO_STAKER_2,
            username: "testsecond",
            clowNumber: 2002,
            nonceNameService: 20202,
            priorityFee: 0.001 ether,
            nonceEVVM: evvm.getNextCurrentSyncNonce(
                COMMON_USER_NO_STAKER_2.Address
            ),
            priorityEVVM: false
        });

        _addBalance(params1.user, params1.priorityFee);
        _addBalance(params2.user, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceOne,
            bytes memory signatureEvvmOne
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(
                abi.encodePacked(params1.username, uint256(params1.clowNumber))
            ),
            params1.nonceNameService,
            signatureNameServiceOne,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            signatureEvvmOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params1.username,
                            uint256(params1.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Error NonStaker: username not preregistered correctly"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceTwo,
            bytes memory signatureEvvmTwo
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_2,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_2.Address,
            keccak256(
                abi.encodePacked(params2.username, uint256(params2.clowNumber))
            ),
            params2.nonceNameService,
            signatureNameServiceTwo,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            signatureEvvmTwo
        );
        vm.stopPrank();
        (user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params2.username,
                            uint256(params2.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_2.Address,
            "Error Staker: username not preregistered correctly"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + params2.priorityFee,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee_async()
        external
    {
        Params memory params1 = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: "testfirst",
            clowNumber: 1001,
            nonceNameService: 10101,
            priorityFee: 0.001 ether,
            nonceEVVM: 420,
            priorityEVVM: true
        });

        Params memory params2 = Params({
            user: COMMON_USER_NO_STAKER_2,
            username: "testsecond",
            clowNumber: 2002,
            nonceNameService: 20202,
            priorityFee: 0.001 ether,
            nonceEVVM: 67,
            priorityEVVM: true
        });

        _addBalance(params1.user, params1.priorityFee);
        _addBalance(params2.user, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceOne,
            bytes memory signatureEvvmOne
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_1,
                params1.username,
                params1.clowNumber,
                params1.nonceNameService,
                params1.priorityFee,
                params1.nonceEVVM,
                params1.priorityEVVM
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(
                abi.encodePacked(params1.username, uint256(params1.clowNumber))
            ),
            params1.nonceNameService,
            signatureNameServiceOne,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.priorityEVVM,
            signatureEvvmOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params1.username,
                            uint256(params1.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_1.Address,
            "Error NonStaker: username not preregistered correctly"
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceTwo,
            bytes memory signatureEvvmTwo
        ) = _execute_makePreRegistrationUsernameSignature(
                COMMON_USER_NO_STAKER_2,
                params2.username,
                params2.clowNumber,
                params2.nonceNameService,
                params2.priorityFee,
                params2.nonceEVVM,
                params2.priorityEVVM
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_2.Address,
            keccak256(
                abi.encodePacked(params2.username, uint256(params2.clowNumber))
            ),
            params2.nonceNameService,
            signatureNameServiceTwo,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.priorityEVVM,
            signatureEvvmTwo
        );
        vm.stopPrank();
        (user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params2.username,
                            uint256(params2.clowNumber)
                        )
                    )
                )
            )
        );

        assertEq(
            user,
            COMMON_USER_NO_STAKER_2.Address,
            "Error Staker: username not preregistered correctly"
        );
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            evvm.getRewardAmount() + params2.priorityFee,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }
}
