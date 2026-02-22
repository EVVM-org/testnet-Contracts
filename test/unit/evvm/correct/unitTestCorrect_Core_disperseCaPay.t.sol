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

import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {
    CoreError
} from "@evvm/testnet-contracts/library/errors/CoreError.sol";

contract unitTestCorrect_Core_disperseCaPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        core.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    ///@dev because this script behaves like a smart contract we can use caPay
    ///     and disperseCaPay without any problem

    function test__unit_correct__disperseCaPay__noStaker() external {
        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        core.disperseCaPay(toData, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ca dosent recieve rewards because is no an staker"
        );
    }

    function test__unit_correct__disperseCaPay__staker() external {
        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        core.setPointStaker(address(this), 0x01);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        core.disperseCaPay(toData, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            core.getRewardAmount(),
            "Staker ca should recieve rewards"
        );
    }

    function test__unit_correct__disperseCaPay__denyList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x02); // Activate denyList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        vm.stopPrank();

        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        core.disperseCaPay(toData, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ca dosent recieve rewards because is no an staker"
        );
    }

    function test__unit_correct__disperseCaPay__allowList()
        external
    {
        vm.startPrank(ADMIN.Address);
        core.proposeListStatus(0x01); // Activate allowList
        skip(1 days + 1); // Skip timelock
        core.acceptListStatusProposal();
        core.setTokenStatusOnAllowList(ETHER_ADDRESS, true);
        vm.stopPrank();

        (uint256 amount) = _addBalance(address(this), ETHER_ADDRESS, 0.1 ether);

        CoreStructs.DisperseCaPayMetadata[]
            memory toData = new CoreStructs.DisperseCaPayMetadata[](1);

        toData[0] = CoreStructs.DisperseCaPayMetadata({
            amount: amount,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        core.disperseCaPay(toData, ETHER_ADDRESS, amount);

        assertEq(
            core.getBalance(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS),
            amount,
            "Amount should be recibed"
        );

        assertEq(
            core.getBalance(address(this), ETHER_ADDRESS),
            0,
            "Amount should be deducted"
        );

        assertEq(
            core.getBalance(address(this), PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ca dosent recieve rewards because is no an staker"
        );
    }
}
