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
import "@evvm/testnet-contracts/library/structs/StakingStructs.sol";

contract unitTestCorrect_Staking_presaleStaking is Test, Constants {
    AccountData FISHER_STAKER = COMMON_USER_STAKER;
    AccountData FISHER_NO_STAKER = COMMON_USER_NO_STAKER_2;
    AccountData USER = COMMON_USER_NO_STAKER_1;

    function executeBeforeSetUp() internal override {
        /**
         *  @dev Because presale staking is disabled by default in 
                 testnet contracts, we need to enable it here
         */
        vm.startPrank(ADMIN.Address);

        staking.prepareChangeAllowPublicStaking();
        staking.prepareChangeAllowPresaleStaking();

        skip(1 days);
        staking.confirmChangeAllowPublicStaking();
        staking.confirmChangeAllowPresaleStaking();

        assertFalse(
            staking.getAllowPublicStaking().flag,
            "public staking was not disabled in setup"
        );

        assertTrue(
            staking.getAllowPresaleStaking().flag,
            "presale staking was not enabled in setup"
        );

        ///@dev Adding a presale staker to be able to execute
        ///     presale staking tests
        staking.addPresaleStaker(USER.Address);
        vm.stopPrank();
    }

    function _addBalance(
        address user,
        uint256 priorityFee
    ) private returns (uint256 amount, uint256 amountPriorityFee) {
        evvm.addBalance(
            user,
            PRINCIPAL_TOKEN_ADDRESS,
            (staking.priceOfStaking()) + priorityFee
        );
        return (staking.priceOfStaking(), priorityFee);
    }

    struct Params {
        AccountData user;
        bool isStaking;
        uint256 nonceStake;
        uint256 _amountInPrincipal;
        bytes signatureStake;
        uint256 priorityFee;
        uint256 nonceEVVM;
        bytes signatureEVVM;
    }

    function test__unit_correct__presaleStaking__staking_noFisherStake_noPriorityfee()
        external
    {
        Params memory params1 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 420,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory params2 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1._amountInPrincipal, ) = _addBalance(
            params1.user.Address,
            params1.priorityFee
        );

        (
            params1.signatureStake,
            params1.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params1.user,
            params1.isStaking,
            params1.nonceStake,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params1.user.Address,
            params1.isStaking,
            params1.nonceStake,
            params1.signatureStake,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params1.user.Address)
            );
        historySync = staking.getAddressHistory(params1.user.Address);

        assertTrue(
            evvm.isAddressStaker(params1.user.Address),
            "ERROR [1] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [1] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [1] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [1] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [1] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [1] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2._amountInPrincipal, ) = _addBalance(
            params2.user.Address,
            params2.priorityFee
        );

        (
            params2.signatureStake,
            params2.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params2.user,
            params2.isStaking,
            params2.nonceStake,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params2.user.Address,
            params2.isStaking,
            params2.nonceStake,
            params2.signatureStake,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyAsync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params2.user.Address)
            );
        historyAsync = staking.getAddressHistory(params2.user.Address);

        assertTrue(
            evvm.isAddressStaker(params2.user.Address),
            "ERROR [2] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [2] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [2] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [2] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [2] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [2] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_noFisherStake_priorityfee()
        external
    {
        Params memory params1 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 420,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory params2 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1._amountInPrincipal, ) = _addBalance(
            params1.user.Address,
            params1.priorityFee
        );

        (
            params1.signatureStake,
            params1.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params1.user,
            params1.isStaking,
            params1.nonceStake,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params1.user.Address,
            params1.isStaking,
            params1.nonceStake,
            params1.signatureStake,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params1.user.Address)
            );
        historySync = staking.getAddressHistory(params1.user.Address);

        assertTrue(
            evvm.isAddressStaker(params1.user.Address),
            "ERROR [1] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [1] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [1] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [1] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [1] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [1] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2._amountInPrincipal, ) = _addBalance(
            params2.user.Address,
            params2.priorityFee
        );

        (
            params2.signatureStake,
            params2.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params2.user,
            params2.isStaking,
            params2.nonceStake,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params2.user.Address,
            params2.isStaking,
            params2.nonceStake,
            params2.signatureStake,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyAsync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params2.user.Address)
            );
        historyAsync = staking.getAddressHistory(params2.user.Address);

        assertTrue(
            evvm.isAddressStaker(params2.user.Address),
            "ERROR [2] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [2] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [2] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [2] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [2] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [2] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_fisherStake_noPriorityfee()
        external
    {
        Params memory params1 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 420,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory params2 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1._amountInPrincipal, ) = _addBalance(
            params1.user.Address,
            params1.priorityFee
        );

        (
            params1.signatureStake,
            params1.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params1.user,
            params1.isStaking,
            params1.nonceStake,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params1.user.Address,
            params1.isStaking,
            params1.nonceStake,
            params1.signatureStake,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params1.user.Address)
            );
        historySync = staking.getAddressHistory(params1.user.Address);

        assertTrue(
            evvm.isAddressStaker(params1.user.Address),
            "ERROR [1] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [1] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [1] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [1] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [1] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params1.priorityFee,
            "ERROR [1] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2._amountInPrincipal, ) = _addBalance(
            params2.user.Address,
            params2.priorityFee
        );

        (
            params2.signatureStake,
            params2.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params2.user,
            params2.isStaking,
            params2.nonceStake,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params2.user.Address,
            params2.isStaking,
            params2.nonceStake,
            params2.signatureStake,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyAsync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params2.user.Address)
            );
        historyAsync = staking.getAddressHistory(params2.user.Address);

        assertTrue(
            evvm.isAddressStaker(params2.user.Address),
            "ERROR [2] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [2] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [2] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [2] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [2] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                params2.priorityFee +
                params1.priorityFee,
            "ERROR [2] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__staking_fisherStake_priorityfee()
        external
    {
        Params memory params1 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 420,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory params2 = Params({
            user: USER,
            isStaking: true,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0.01 ether,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing sync ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params1._amountInPrincipal, ) = _addBalance(
            params1.user.Address,
            params1.priorityFee
        );

        (
            params1.signatureStake,
            params1.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params1.user,
            params1.isStaking,
            params1.nonceStake,
            params1.priorityFee,
            params1.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params1.user.Address,
            params1.isStaking,
            params1.nonceStake,
            params1.signatureStake,
            params1.priorityFee,
            params1.nonceEVVM,
            params1.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historySync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params1.user.Address)
            );
        historySync = staking.getAddressHistory(params1.user.Address);

        assertTrue(
            evvm.isAddressStaker(params1.user.Address),
            "ERROR [1] : presale user is not pointer as staker"
        );

        assertEq(
            historySync[0].timestamp,
            block.timestamp,
            "ERROR [1] : timestamp in history [0] is not correct"
        );
        assertEq(
            historySync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [1] : transactionType in history [0] is not correct"
        );
        assertEq(
            historySync[0].amount,
            1,
            "ERROR [1] : amount in history [0] is not correct"
        );
        assertEq(
            historySync[0].totalStaked,
            1,
            "ERROR [1] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params1.priorityFee,
            "ERROR [1] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing async ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (params2._amountInPrincipal, ) = _addBalance(
            params2.user.Address,
            params2.priorityFee
        );

        (
            params2.signatureStake,
            params2.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params2.user,
            params2.isStaking,
            params2.nonceStake,
            params2.priorityFee,
            params2.nonceEVVM
        );

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params2.user.Address,
            params2.isStaking,
            params2.nonceStake,
            params2.signatureStake,
            params2.priorityFee,
            params2.nonceEVVM,
            params2.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyAsync = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params2.user.Address)
            );
        historyAsync = staking.getAddressHistory(params2.user.Address);

        assertTrue(
            evvm.isAddressStaker(params2.user.Address),
            "ERROR [2] : presale user is not pointer as staker"
        );

        assertEq(
            historyAsync[0].timestamp,
            block.timestamp,
            "ERROR [2] : timestamp in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [2] : transactionType in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].amount,
            1,
            "ERROR [2] : amount in history [0] is not correct"
        );
        assertEq(
            historyAsync[0].totalStaked,
            1,
            "ERROR [2] : totalStaked in history [0] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            ((evvm.getRewardAmount() * 2) * 2) +
                params2.priorityFee +
                params1.priorityFee,
            "ERROR [2] : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__unstakingAndFullUnstaking_noFisherStake()
        external
    {
        for (uint256 i = 0; i < 2; i++) {
            _addBalance(USER.Address, 0);
            _executeFn_staking_presaleStaking(
                USER,
                true,
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ) + i,
                0,
                uint256(
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000
                ) + i,
                GOLDEN_STAKER
            );
        }

        Params memory paramsUnstake = Params({
            user: USER,
            isStaking: false,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 420,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        Params memory paramsFullUnstake = Params({
            user: USER,
            isStaking: false,
            nonceStake: 2000002000002,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing unstake ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        (paramsUnstake._amountInPrincipal, ) = _addBalance(
            paramsUnstake.user.Address,
            paramsUnstake.priorityFee
        );

        (
            paramsUnstake.signatureStake,
            paramsUnstake.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            paramsUnstake.user,
            paramsUnstake.isStaking,
            paramsUnstake.nonceStake,
            paramsUnstake.priorityFee,
            paramsUnstake.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsUnstake.user.Address,
            paramsUnstake.isStaking,
            paramsUnstake.nonceStake,
            paramsUnstake.signatureStake,
            paramsUnstake.priorityFee,
            paramsUnstake.nonceEVVM,
            paramsUnstake.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyUnstake = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsUnstake.user.Address)
            );
        historyUnstake = staking.getAddressHistory(paramsUnstake.user.Address);

        assertTrue(
            evvm.isAddressStaker(paramsUnstake.user.Address),
            "ERROR [unstake execution] : presale user must still point as staker"
        );

        assertEq(
            historyUnstake[2].timestamp,
            block.timestamp,
            "ERROR [unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "ERROR [unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].amount,
            1,
            "ERROR [unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyUnstake[2].totalStaked,
            1,
            "ERROR [unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [unstake execution] : balance of fisher after staking is not correct"
        );

        /*⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇ Testing full unstake ⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇⬇*/
        skip(staking.getSecondsToUnlockFullUnstaking());

        (paramsFullUnstake._amountInPrincipal, ) = _addBalance(
            paramsFullUnstake.user.Address,
            paramsFullUnstake.priorityFee
        );

        (
            paramsFullUnstake.signatureStake,
            paramsFullUnstake.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            paramsFullUnstake.user,
            paramsFullUnstake.isStaking,
            paramsFullUnstake.nonceStake,
            paramsFullUnstake.priorityFee,
            paramsFullUnstake.nonceEVVM
        );

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            paramsFullUnstake.user.Address,
            paramsFullUnstake.isStaking,
            paramsFullUnstake.nonceStake,
            paramsFullUnstake.signatureStake,
            paramsFullUnstake.priorityFee,
            paramsFullUnstake.nonceEVVM,
            paramsFullUnstake.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyFullUnstake = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(paramsFullUnstake.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(
            paramsFullUnstake.user.Address
        );

        assertFalse(
            evvm.isAddressStaker(paramsFullUnstake.user.Address),
            "ERROR [full unstake execution] : presale user must not point as staker anymore"
        );

        assertEq(
            historyFullUnstake[3].timestamp,
            block.timestamp,
            "ERROR [full unstake execution] : timestamp in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].transactionType,
            WITHDRAW_HISTORY_SMATE_IDENTIFIER,
            "ERROR [full unstake execution] : transactionType in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].amount,
            1,
            "ERROR [full unstake execution] : amount in history [3] is not correct"
        );
        assertEq(
            historyFullUnstake[3].totalStaked,
            0,
            "ERROR [full unstake execution] : totalStaked in history [3] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [full unstake execution]  : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__stakeAfterFullUnstaking_noFisherStake()
        external
    {
        _addBalance(USER.Address, 0);
        _executeFn_staking_presaleStaking(
            USER,
            true,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_presaleStaking(
            USER,
            false,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        skip(staking.getSecondsToUnlockFullUnstaking());

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM
        );

        skip(staking.getSecondsToUnlockStaking());

        vm.startPrank(FISHER_NO_STAKER.Address);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyFullUnstake = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(params.user.Address);

        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "ERROR [stake after full unstake execution] : presale user must be pointer as staker"
        );

        assertEq(
            historyFullUnstake[2].timestamp,
            block.timestamp,
            "ERROR [stake after full unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [stake after full unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].amount,
            1,
            "ERROR [stake after full unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].totalStaked,
            1,
            "ERROR [stake after full unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_NO_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0,
            "ERROR [stake after full unstake execution]  : balance of fisher after staking is not correct"
        );
    }

    function test__unit_correct__presaleStaking__stakeAfterFullUnstaking_fisherStake()
        external
    {
        _addBalance(USER.Address, 0);
        _executeFn_staking_presaleStaking(
            USER,
            true,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            GOLDEN_STAKER
        );

        skip(staking.getSecondsToUnlockFullUnstaking());

        _executeFn_staking_presaleStaking(
            USER,
            false,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            ),
            0,
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3
            ),
            GOLDEN_STAKER
        );

        Params memory params = Params({
            user: USER,
            isStaking: true,
            nonceStake: 1000001000001,
            signatureStake: "",
            priorityFee: 0,
            nonceEVVM: 67,
            signatureEVVM: "",
            _amountInPrincipal: 0
        });

        skip(staking.getSecondsToUnlockFullUnstaking());

        (params._amountInPrincipal, ) = _addBalance(
            params.user.Address,
            params.priorityFee
        );

        (
            params.signatureStake,
            params.signatureEVVM
        ) = _executeSig_staking_presaleStaking(
            params.user,
            params.isStaking,
            params.nonceStake,
            params.priorityFee,
            params.nonceEVVM
        );

        skip(staking.getSecondsToUnlockStaking());

        vm.startPrank(FISHER_STAKER.Address);
        staking.presaleStaking(
            params.user.Address,
            params.isStaking,
            params.nonceStake,
            params.signatureStake,
            params.priorityFee,
            params.nonceEVVM,
            params.signatureEVVM
        );
        vm.stopPrank();

        StakingStructs.HistoryMetadata[]
            memory historyFullUnstake = new StakingStructs.HistoryMetadata[](
                staking.getSizeOfAddressHistory(params.user.Address)
            );
        historyFullUnstake = staking.getAddressHistory(params.user.Address);

        assertTrue(
            evvm.isAddressStaker(params.user.Address),
            "ERROR [stake after full unstake execution] : presale user must be pointer as staker"
        );

        assertEq(
            historyFullUnstake[2].timestamp,
            block.timestamp,
            "ERROR [stake after full unstake execution] : timestamp in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].transactionType,
            DEPOSIT_HISTORY_SMATE_IDENTIFIER,
            "ERROR [stake after full unstake execution] : transactionType in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].amount,
            1,
            "ERROR [stake after full unstake execution] : amount in history [2] is not correct"
        );
        assertEq(
            historyFullUnstake[2].totalStaked,
            1,
            "ERROR [stake after full unstake execution] : totalStaked in history [2] is not correct"
        );

        assertEq(
            evvm.getBalance(FISHER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            (evvm.getRewardAmount() * 2) + params.priorityFee,
            "ERROR [stake after full unstake execution]  : balance of fisher after staking is not correct"
        );
    }
}
