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

contract unitTestCorrect_NameService_preRegistrationUsername is
    Test,
    Constants
{
    AccountData FISHER_NO_STAKER = WILDCARD_USER;
    AccountData FISHER_STAKER = COMMON_USER_STAKER;

    struct Params {
        AccountData user;
        string username;
        uint256 lockNumber;
        uint256 nonce;
        uint256 priorityFee;
        uint256 noncePay;
    }

    function _addBalance(
        AccountData memory user,
        uint256 priorityFee
    ) private returns (uint256 totalPriorityFeeAmount) {
        core.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFee);

        return priorityFee;
    }

    function test__unit_correct__preRegistrationUsername__noPriorityFee()
        external
    {
        Params memory params1 = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: "testfirst",
            lockNumber: 1001,
            nonce: 10101,
            priorityFee: 0,
            noncePay: 67
        });

        Params memory params2 = Params({
            user: COMMON_USER_NO_STAKER_2,
            username: "testsecond",
            lockNumber: 2002,
            nonce: 20202,
            priorityFee: 0,
            noncePay: 420
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceOne,
            bytes memory signaturePayOne
        ) = _executeSig_nameService_preRegistrationUsername(
                params1.user,
                params1.username,
                params1.lockNumber,
                address(0),
                params1.nonce,
                params1.priorityFee,
                params1.noncePay
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            params1.user.Address,
            keccak256(
                abi.encodePacked(params1.username, uint256(params1.lockNumber))
            ),
            address(0),
            params1.nonce,
            signatureNameServiceOne,
            params1.priorityFee,
            params1.noncePay,
            signaturePayOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params1.username,
                            uint256(params1.lockNumber)
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
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceTwo,
            bytes memory signaturePayTwo
        ) = _executeSig_nameService_preRegistrationUsername(
                params2.user,
                params2.username,
                params2.lockNumber,
                address(0),
                params2.nonce,
                params2.priorityFee,
                params2.noncePay
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.preRegistrationUsername(
            params2.user.Address,
            keccak256(
                abi.encodePacked(params2.username, uint256(params2.lockNumber))
            ),
            address(0),
            params2.nonce,
            signatureNameServiceTwo,
            params2.priorityFee,
            params2.noncePay,
            signaturePayTwo
        );
        vm.stopPrank();
        (user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params2.username,
                            uint256(params2.lockNumber)
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
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount(),
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }

    function test__unit_correct__preRegistrationUsername__priorityFee()
        external
    {
        Params memory params1 = Params({
            user: COMMON_USER_NO_STAKER_1,
            username: "testfirst",
            lockNumber: 1001,
            nonce: 10101,
            priorityFee: 0.001 ether,
            noncePay: 420
        });

        Params memory params2 = Params({
            user: COMMON_USER_NO_STAKER_2,
            username: "testsecond",
            lockNumber: 2002,
            nonce: 20202,
            priorityFee: 0.001 ether,
            noncePay: 67
        });

        _addBalance(params1.user, params1.priorityFee);
        _addBalance(params2.user, params2.priorityFee);

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher noStaker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceOne,
            bytes memory signaturePayOne
        ) = _executeSig_nameService_preRegistrationUsername(
                COMMON_USER_NO_STAKER_1,
                params1.username,
                params1.lockNumber,
                address(0),
                params1.nonce,
                params1.priorityFee,
                params1.noncePay
            );

        vm.startPrank(FISHER_NO_STAKER.Address);

        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_1.Address,
            keccak256(
                abi.encodePacked(params1.username, uint256(params1.lockNumber))
            ),
            address(0),
            params1.nonce,
            signatureNameServiceOne,
            params1.priorityFee,
            params1.noncePay,
            signaturePayOne
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params1.username,
                            uint256(params1.lockNumber)
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
            core.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            core.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "Error NonStaker: balance incorrectly changed after preRegistrationUsername"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing fisher staker ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/

        (
            bytes memory signatureNameServiceTwo,
            bytes memory signaturePayTwo
        ) = _executeSig_nameService_preRegistrationUsername(
                COMMON_USER_NO_STAKER_2,
                params2.username,
                params2.lockNumber,
                address(0),
                params2.nonce,
                params2.priorityFee,
                params2.noncePay
            );

        vm.startPrank(FISHER_STAKER.Address);
        nameService.preRegistrationUsername(
            COMMON_USER_NO_STAKER_2.Address,
            keccak256(
                abi.encodePacked(params2.username, uint256(params2.lockNumber))
            ),
            address(0),
            params2.nonce,
            signatureNameServiceTwo,
            params2.priorityFee,
            params2.noncePay,
            signaturePayTwo
        );
        vm.stopPrank();
        (user, ) = nameService.getIdentityBasicMetadata(
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(
                        abi.encodePacked(
                            params2.username,
                            uint256(params2.lockNumber)
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
            core.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
        assertEq(
            core.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount() + params2.priorityFee,
            "Error Staker: balance incorrectly changed after preRegistrationUsername"
        );
    }
}
