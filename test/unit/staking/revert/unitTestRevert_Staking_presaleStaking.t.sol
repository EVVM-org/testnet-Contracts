// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**
 ____ ___      .__  __      __                  __   
|    |   \____ |___/  |_  _/  |_  ____   ______/  |_ 
|    |   /    \|  \   __\ \   ___/ __ \ /  ___\   __\
|    |  |   |  |  ||  |    |  | \  ___/ \___ \ |  |  
|______/|___|  |__||__|    |__|  \___  /____  >|__|  
             \/                      \/     \/       
                                  __                 
_______  _______  __ ____________/  |_               
\_  __ _/ __ \  \/ _/ __ \_  __ \   __\              
 |  | \\  ___/\   /\  ___/|  | \/|  |                
 |__|   \___  >\_/  \___  |__|   |__|                
            \/          \/                                                                                 
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestRevert_Staking_presaleStaking is Test, Constants {

    
    
    
    

    function executeBeforeSetUp() internal override {

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        vm.startPrank(ADMIN.Address);

        staking.addPresaleStaker(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function giveMateToExecute(
        address user,
        uint256 stakingAmount,
        uint256 priorityFee
    ) private returns (uint256 totalOfMate, uint256 totalOfPriorityFee) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking() * stakingAmount) + priorityFee
        );

        totalOfMate = (staking.priceOfStaking() * stakingAmount);
        totalOfPriorityFee = priorityFee;
    }

    function getAmountOfRewardsPerExecution(
        uint256 numberOfTx
    ) private view returns (uint256) {
        return (evvm.getRewardAmount() * 2) * numberOfTx;
    }

    function makeSignature(
        bool isStaking,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityEVVM,
        uint256 nonceSmate
    )
        private
        view
        returns (bytes memory signatureEVVM, bytes memory signatureStaking)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (isStaking) {
            (v, r, s) = vm.sign(
                COMMON_USER_NO_STAKER_1.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    staking.priceOfStaking() * 1,
                    priorityFee,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        } else {
            (v, r, s) = vm.sign(
                COMMON_USER_NO_STAKER_1.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                    address(staking),
                    "",
                    PRINCIPAL_TOKEN_ADDRESS,
                    priorityFee,
                    0,
                    nonceEVVM,
                    priorityEVVM,
                    address(staking)
                )
            );
        }

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                isStaking,
                1,
                nonceSmate
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    /**
     * Function to test:
     * nGU: nonGoldenUser
     * bPaySigAt[section]: incorrect payment signature // bad signature
     * bStakeSigAt[section]: incorrect stake signature // bad signature
     * wValAt[section]: wrong value
     * some denominations on test can be explicit expleined
     */

    function test__unitRevert__presaleStaking__bPaySigAtSigner() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtToAddress() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    /*
     ! note: if staking in the future has a NameService identity, then rework
     !       this test
     */
    function test__unitRevert__presaleStaking__bPaySigAtToIdentity() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "smate",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtTokenAddress()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                ETHER_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtAmount() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                777,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtPriorityFee() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                777,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtNonce() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                11111,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtPriorityFlag()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                false,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bPaySigAtExecutor() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(0)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bStakeSigAtSigner() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bStakeSigAtIsStakingFlag()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                false,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bStakeSigAtAmount() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                10,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__bStakeSigAtNonce() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),true, 1, 111)
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    /*
    function test__unitRevert__presaleStaking__() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
                staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(
                COMMON_USER_STAKER.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            0
        );
    }
    */

    function test__unitRevert__presaleStaking__notAPresaleStakingr() external {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_2.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_2.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_2.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__nonceAlreadyUsed() external {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            100,
            true,
            1001001
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            0,
            100,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (totalOfMate / 2) + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__allowExternalStakingIsFalse()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        skip(1 days);
        staking.confirmChangeAllowPublicStaking();
        vm.stopPrank();

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            1,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__userTriesToStakeMoreThanOne()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                true,
                2,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__userStakeMoreThanTheLimit()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            3,
            0
        );

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            100,
            true,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            100,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            101,
            true,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            102,
            true,
            102
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            102,
            signatureStaking,
            totalOfPriorityFee,
            102,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (totalOfMate / 3) + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unitRevert__presaleStaking__userUnstakeWithoutStaking()
        external
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            0,
            0
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfMate,
                totalOfPriorityFee,
                10001,
                true,
                address(staking)
            )
        );

        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                evvm.getEvvmID(),
                false,
                1,
                1001001
            )
        );
        bytes memory signatureStaking = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            1001001,
            signatureStaking,
            totalOfPriorityFee,
            10001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__presaleStaking_AsyncExecution__fullUnstakeDosentRespectTimeLimit()
        external
    {
        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            100,
            true,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            100,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            101,
            true,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            102,
            true,
            102
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            102,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            103,
            true,
            103
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0,
            103,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            (totalOfMate / 2) + totalOfPriorityFee
        );
    }

    function test__unit_revert__presaleStaking_AsyncExecution__notInTimeToRestake()
        external
    {
        vm.startPrank(ADMIN.Address);
        staking.proposeSetSecondsToUnlockStaking(5 days);
        skip(1 days);
        staking.acceptSetSecondsToUnlockStaking();
        vm.stopPrank();

        (uint256 totalOfMate, uint256 totalOfPriorityFee) = giveMateToExecute(
            COMMON_USER_NO_STAKER_1.Address,
            2,
            0
        );

        bytes memory signatureEVVM;
        bytes memory signatureStaking;

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            100,
            true,
            100
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            100,
            signatureStaking,
            0,
            100,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            101,
            true,
            101
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            101,
            signatureStaking,
            0,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            102,
            true,
            102
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            102,
            signatureStaking,
            0,
            102,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            false,
            0,
            103,
            true,
            103
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            false,
            103,
            signatureStaking,
            0,
            103,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        (signatureEVVM, signatureStaking) = makeSignature(
            true,
            0,
            104,
            true,
            104
        );

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        staking.presaleStaking(
            COMMON_USER_NO_STAKER_1.Address,
            true,
            104,
            signatureStaking,
            0,
            104,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        assert(!evvm.isAddressStaker(COMMON_USER_NO_STAKER_1.Address));
        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfMate + totalOfPriorityFee
        );
    }
}
