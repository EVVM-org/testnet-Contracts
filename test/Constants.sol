// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title CoreStorage
 * @author jistro.eth
 * @dev Storage layout contract for EVVM proxy pattern implementation.
 *      This contract inherits all structures from CoreStructs and
 *      defines the storage layout that will be used by the proxy pattern.
 *
 * @notice This contract should not be deployed directly, it's meant to be
 *         inherited by the implementation contracts to ensure they maintain
 *         the same storage layout.
 */
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {Core} from "@evvm/testnet-contracts/contracts/core/Core.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {
    CoreStructs
} from "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import "@evvm/testnet-contracts/library/structs/P2PSwapStructs.sol";
import "@solady/tokens/ERC20.sol";
import "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import "@evvm/testnet-contracts/library/structs/CoreStructs.sol";
import "@evvm/testnet-contracts/contracts/core/lib/CoreStorage.sol";

abstract contract Constants is Test {
    Staking staking;
    Core core;

    Estimator estimator;
    NameService nameService;
    Treasury treasury;
    P2PSwap p2pSwap;

    bytes32 constant DEPOSIT_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(2));

    address constant PRINCIPAL_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;

    /*
        | ACCOUNT       |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  | 
        | ADMIN         |  X  |     |     |     |     |     |     |     |
        | Common users  |     |  X  |  X  |  X  |     |     |     |     |
        | Staker        |     |     |     |  X  |  X  |     |     |     |
        | Golden        |     |     |     |     |     |  X  |     |     |
        | Activator     |     |     |     |     |     |     |  X  |     |
        
        The 8th user is used as a WILDCARD
    */

    struct AccountData {
        address Address;
        uint256 PrivateKey;
    }

    AccountData ACCOUNT1 =
        AccountData({
            Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            PrivateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });

    AccountData ACCOUNT2 =
        AccountData({
            Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            PrivateKey: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        });

    AccountData ACCOUNT3 =
        AccountData({
            Address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            PrivateKey: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
        });

    AccountData ACCOUNT4 =
        AccountData({
            Address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            PrivateKey: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
        });

    AccountData ACCOUNT5 =
        AccountData({
            Address: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            PrivateKey: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
        });

    AccountData ACCOUNT6 =
        AccountData({
            Address: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            PrivateKey: 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
        });

    AccountData ACCOUNT7 =
        AccountData({
            Address: 0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            PrivateKey: 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
        });

    AccountData ACCOUNT8 =
        AccountData({
            Address: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            PrivateKey: 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        });

    AccountData ADMIN =
        AccountData({
            Address: ACCOUNT1.Address,
            PrivateKey: ACCOUNT1.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_1 =
        AccountData({
            Address: ACCOUNT2.Address,
            PrivateKey: ACCOUNT2.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_2 =
        AccountData({
            Address: ACCOUNT3.Address,
            PrivateKey: ACCOUNT3.PrivateKey
        });

    AccountData COMMON_USER_STAKER =
        AccountData({
            Address: ACCOUNT4.Address,
            PrivateKey: ACCOUNT4.PrivateKey
        });

    // this should be apllied only on sMATE and estimator tests
    AccountData STAKER =
        AccountData({
            Address: ACCOUNT5.Address,
            PrivateKey: ACCOUNT5.PrivateKey
        });

    AccountData GOLDEN_STAKER =
        AccountData({
            Address: ACCOUNT6.Address,
            PrivateKey: ACCOUNT6.PrivateKey
        });

    AccountData ACTIVATOR =
        AccountData({
            Address: ACCOUNT7.Address,
            PrivateKey: ACCOUNT7.PrivateKey
        });

    AccountData WILDCARD_USER =
        AccountData({
            Address: ACCOUNT8.Address,
            PrivateKey: ACCOUNT8.PrivateKey
        });

    function setUp() public virtual {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        core = new Core(
            ADMIN.Address,
            address(staking),
            CoreStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 777,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );

        estimator = new Estimator(
            ACTIVATOR.Address,
            address(core),
            address(staking),
            ADMIN.Address
        );

        nameService = new NameService(address(core), ADMIN.Address);

        staking.initializeSystemContracts(address(estimator), address(core));
        treasury = new Treasury(address(core));

        core.initializeSystemContracts(address(nameService), address(treasury));

        p2pSwap = new P2PSwap(address(core), address(staking), ADMIN.Address);
        core.setPointStaker(address(p2pSwap), 0x01);

        if (address(p2pSwap) == address(0)) revert();

        core.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        executeBeforeSetUp();
    }

    function executeBeforeSetUp() internal virtual {}

    function _executeSig_evvm_pay(
        AccountData memory user,
        address toAddress,
        string memory toIdentity,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec
    ) internal virtual returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                core.getEvvmID(),
                address(core),
                toAddress,
                toIdentity,
                tokenAddress,
                amount,
                priorityFee,
                executor,
                nonce,
                isAsyncExec
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function _executeFn_evvm_pay(
        AccountData memory user,
        address toAddress,
        string memory toIdentity,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec,
        address fisher
    ) internal virtual {
        bytes memory signature = _executeSig_evvm_pay(
            user,
            toAddress,
            toIdentity,
            tokenAddress,
            amount,
            priorityFee,
            executor,
            nonce,
            isAsyncExec
        );

        vm.startPrank(fisher);
        core.pay(
            user.Address,
            toAddress,
            toIdentity,
            tokenAddress,
            amount,
            priorityFee,
            executor,
            nonce,
            isAsyncExec,
            signature
        );
        vm.stopPrank();
    }

    function _executeSig_evvm_dispersePay(
        AccountData memory user,
        CoreStructs.DispersePayMetadata[] memory toData,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        uint256 nonce,
        bool isAsyncExec
    ) internal virtual returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForDispersePay(
                core.getEvvmID(),
                address(core),
                toData,
                tokenAddress,
                amount,
                priorityFee,
                executor,
                nonce,
                isAsyncExec
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function _executeSig_nameService_preRegistrationUsername(
        AccountData memory user,
        string memory username,
        uint256 lockNumber,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFeeAmount,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                core.getEvvmID(),
                address(nameService),
                keccak256(abi.encodePacked(username, lockNumber)),
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFeeAmount > 0
            ? _executeSig_evvm_pay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFeeAmount,
                address(nameService),
                nonceEvvm,
                true
            )
            : bytes(hex"");
    }

    function _executeFn_nameService_preRegistrationUsername(
        AccountData memory user,
        string memory username,
        uint256 lockNumber,
        address originExecutor,
        uint256 nonce
    ) internal virtual {
        (
            bytes memory signature,

        ) = _executeSig_nameService_preRegistrationUsername(
                user,
                username,
                lockNumber,
                originExecutor,
                nonce,
                0,
                0
            );

        nameService.preRegistrationUsername(
            user.Address,
            keccak256(abi.encodePacked(username, uint256(lockNumber))),
            originExecutor,
            nonce,
            signature,
            0,
            0,
            hex""
        );
    }

    function _executeSig_nameService_registrationUsername(
        AccountData memory user,
        string memory username,
        uint256 lockNumber,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                core.getEvvmID(),
                address(nameService),
                username,
                lockNumber,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeFn_nameService_registrationUsername(
        AccountData memory user,
        string memory username,
        uint256 lockNumber,
        address originExecutorPreRegister,
        uint256 noncePreRegister,
        address originExecutorRegister,
        uint256 nonceRegister,
        uint256 nonceEvvm
    ) internal virtual {
        _executeFn_nameService_preRegistrationUsername(
            user,
            username,
            lockNumber,
            originExecutorPreRegister,
            noncePreRegister
        );

        skip(30 minutes);

        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username)
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_registrationUsername(
                user,
                username,
                lockNumber,
                originExecutorRegister,
                nonceRegister,
                0,
                nonceEvvm
            );

        nameService.registrationUsername(
            user.Address,
            username,
            lockNumber,
            originExecutorRegister,
            nonceRegister,
            signatureNameService,
            0,
            nonceEvvm,
            signatureEVVM
        );
    }

    function _executeSig_nameService_makeOffer(
        AccountData memory user,
        string memory usernameToMakeOffer,
        uint256 amountToOffer,
        uint256 expirationDate,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                core.getEvvmID(),
                address(nameService),
                usernameToMakeOffer,
                amountToOffer,
                expirationDate,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            amountToOffer,
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeFn_nameService_makeOffer(
        AccountData memory user,
        string memory usernameToMakeOffer,
        uint256 amountToOffer,
        uint256 expirationDate,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm,
        AccountData memory fisher
    ) internal virtual returns (uint256 offerID) {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            amountToOffer + priorityFee
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_makeOffer(
                user,
                usernameToMakeOffer,
                amountToOffer,
                expirationDate,
                originExecutor,
                nonce,
                priorityFee,
                nonceEvvm
            );

        vm.startPrank(fisher.Address);
        offerID = nameService.makeOffer(
            user.Address,
            usernameToMakeOffer,
            amountToOffer,
            expirationDate,
            originExecutor,
            nonce,
            signatureNameService,
            priorityFee,
            nonceEvvm,
            signatureEVVM
        );
        vm.stopPrank();
    }

    function _executeSig_nameService_withdrawOffer(
        AccountData memory user,
        string memory usernameToFindOffer,
        uint256 index,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                core.getEvvmID(),
                address(nameService),
                usernameToFindOffer,
                index,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFee > 0
            ? _executeSig_evvm_pay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFee,
                address(nameService),
                nonceEvvm,
                true
            )
            : bytes(hex"");
    }

    function _executeSig_nameService_acceptOffer(
        AccountData memory user,
        string memory usernameToFindOffer,
        uint256 index,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                core.getEvvmID(),
                address(nameService),
                usernameToFindOffer,
                index,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = priorityFee > 0
            ? _executeSig_evvm_pay(
                user,
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                0,
                priorityFee,
                address(nameService),
                nonceEvvm,
                true
            )
            : bytes(hex"");
    }

    function _executeSig_nameService_renewUsername(
        AccountData memory user,
        string memory usernameToRenew,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                core.getEvvmID(),
                address(nameService),
                usernameToRenew,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.seePriceToRenew(usernameToRenew),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeFn_nameService_renewUsername(
        AccountData memory user,
        string memory usernameToRenew,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm,
        AccountData memory fisher
    ) internal virtual {
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_renewUsername(
                user,
                usernameToRenew,
                originExecutor,
                nonce,
                priorityFee,
                nonceEvvm
            );

        vm.startPrank(fisher.Address);

        nameService.renewUsername(
            user.Address,
            usernameToRenew,
            originExecutor,
            nonce,
            signatureNameService,
            priorityFee,
            nonceEvvm,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function _executeSig_nameService_addCustomMetadata(
        AccountData memory user,
        string memory username,
        string memory customMetadata,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                core.getEvvmID(),
                address(nameService),
                username,
                customMetadata,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata(),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeFn_nameService_addCustomMetadata(
        AccountData memory user,
        string memory username,
        string memory customMetadata,
        address originExecutor,
        uint256 nonce,
        uint256 nonceEvvm
    ) internal virtual {
        core.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata()
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _executeSig_nameService_addCustomMetadata(
                user,
                username,
                customMetadata,
                originExecutor,
                nonce,
                0,
                nonceEvvm
            );

        nameService.addCustomMetadata(
            user.Address,
            username,
            customMetadata,
            originExecutor,
            nonce,
            signatureNameService,
            0,
            nonceEvvm,
            signatureEVVM
        );
    }

    function _executeSig_nameService_removeCustomMetadata(
        AccountData memory user,
        string memory username,
        uint256 indexCustomMetadata,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                core.getEvvmID(),
                address(nameService),
                username,
                indexCustomMetadata,
                originExecutor,
                nonce
            )
        );

        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata(),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeSig_nameService_flushCustomMetadata(
        AccountData memory user,
        string memory username,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushCustomMetadata(
                core.getEvvmID(),
                address(nameService),
                username,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushCustomMetadata(username),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeSig_nameService_flushUsername(
        AccountData memory user,
        string memory username,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForFlushUsername(
                core.getEvvmID(),
                address(nameService),
                username,
                originExecutor,
                nonce
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(nameService),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.getPriceToFlushUsername(username),
            priorityFee,
            address(nameService),
            nonceEvvm,
            true
        );
    }

    function _executeSig_staking_goldenStaking(
        bool isStaking,
        uint256 amount
    ) internal virtual returns (bytes memory signatureEVVM) {
        signatureEVVM = isStaking
            ? _executeSig_evvm_pay(
                GOLDEN_STAKER,
                address(staking),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                (staking.priceOfStaking() * amount),
                0,
                address(staking),
                core.getNextCurrentSyncNonce(GOLDEN_STAKER.Address),
                false
            )
            : bytes(hex"");
    }

    function _executeFn_staking_goldenStaking(
        bool isStaking,
        uint256 amount
    ) internal virtual {
        vm.startPrank(GOLDEN_STAKER.Address);

        staking.goldenStaking(
            isStaking,
            amount,
            _executeSig_staking_goldenStaking(isStaking, amount)
        );

        vm.stopPrank();
    }

    function _executeSig_staking_presaleStaking(
        AccountData memory user,
        bool isStaking,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureStaking, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPresaleStaking(
                core.getEvvmID(),
                address(staking),
                isStaking,
                1,
                originExecutor,
                nonce
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            isStaking ? staking.priceOfStaking() : 0,
            priorityFee,
            address(staking),
            nonceEvvm,
            true
        );
    }

    function _executeFn_staking_presaleStaking(
        AccountData memory user,
        bool isStaking,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFee,
        uint256 nonceEvvm,
        AccountData memory fisher
    ) internal virtual {
        (
            bytes memory signatureStaking,
            bytes memory signatureEVVM
        ) = _executeSig_staking_presaleStaking(
                user,
                isStaking,
                originExecutor,
                nonce,
                priorityFee,
                nonceEvvm
            );

        vm.startPrank(fisher.Address);

        staking.presaleStaking(
            user.Address,
            isStaking,
            originExecutor,
            nonce,
            signatureStaking,
            priorityFee,
            nonceEvvm,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function _executeSig_staking_publicStaking(
        AccountData memory user,
        bool isStaking,
        uint256 amountOfStaking,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFeeEVVM,
        uint256 nonceEvvm
    )
        internal
        virtual
        returns (bytes memory signatureStaking, bytes memory signatureEVVM)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPublicStaking(
                core.getEvvmID(),
                address(staking),
                isStaking,
                amountOfStaking,
                originExecutor,
                nonce
            )
        );
        signatureStaking = Erc191TestBuilder.buildERC191Signature(v, r, s);

        signatureEVVM = _executeSig_evvm_pay(
            user,
            address(staking),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            isStaking ? staking.priceOfStaking() * amountOfStaking : 0,
            priorityFeeEVVM,
            address(staking),
            nonceEvvm,
            true
        );
    }

    function _executeFn_staking_publicStaking(
        AccountData memory user,
        bool isStaking,
        uint256 amountOfStaking,
        address originExecutor,
        uint256 nonce,
        uint256 priorityFeeEVVM,
        uint256 nonceEvvm,
        AccountData memory fisher
    ) internal virtual {
        (
            bytes memory signatureStaking,
            bytes memory signatureEVVM
        ) = _executeSig_staking_publicStaking(
                user,
                isStaking,
                amountOfStaking,
                originExecutor,
                nonce,
                priorityFeeEVVM,
                nonceEvvm
            );

        vm.startPrank(fisher.Address);

        staking.publicStaking(
            user.Address,
            isStaking,
            amountOfStaking,
            originExecutor,
            nonce,
            signatureStaking,
            priorityFeeEVVM,
            nonceEvvm,
            signatureEVVM
        );

        vm.stopPrank();
    }

    function _executeSig_state_test(
        AccountData memory user,
        address servicePointer,
        string memory testA,
        uint256 testB,
        address testC,
        bool testD,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec
    ) internal virtual returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForStateTest(
                core.getEvvmID(),
                servicePointer,
                testA,
                testB,
                testC,
                testD,
                originExecutor,
                nonce,
                isAsyncExec
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function _executeFn_state_test(
        AccountData memory user,
        address servicePointer,
        string memory testA,
        uint256 testB,
        address testC,
        bool testD,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec
    ) internal virtual {
        bytes memory signature = _executeSig_state_test(
            user,
            servicePointer,
            testA,
            testB,
            testC,
            testD,
            originExecutor,
            nonce,
            isAsyncExec
        );

        core.validateAndConsumeNonce(
            user.Address,
            keccak256(abi.encode("StateTest", testA, testB, testC, testD)),
            originExecutor,
            nonce,
            isAsyncExec,
            signature
        );
    }
}

contract MockContractToStake is StakingServiceUtils {
    constructor(address stakingAddress) StakingServiceUtils(stakingAddress) {}

    function stake(uint256 amountToStake) public {
        _makeStakeService(amountToStake);
    }

    function stakeJustInPartOne(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
    }

    function stakeJustInPartTwo(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
        Core(staking.getCoreAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStake
        );
    }

    function stakeJustConfirm() public {
        staking.confirmServiceStaking();
    }

    function stakeWithTokenAddress(
        uint256 amountToStake,
        address tokenAddress
    ) public {
        staking.prepareServiceStaking(amountToStake);
        Core(staking.getCoreAddress()).caPay(
            address(staking),
            tokenAddress,
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    function stakeWithAmountDiscrepancy(
        uint256 amountToStakeDiscrepancy,
        uint256 amountToStake
    ) public {
        staking.prepareServiceStaking(amountToStake);
        Core(staking.getCoreAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStakeDiscrepancy
        );
        staking.confirmServiceStaking();
    }

    function unstake(uint256 amountToUnstake) public {
        _makeUnstakeService(amountToUnstake);
    }

    function getBackMate(address user) public {
        Core(staking.getCoreAddress()).caPay(
            user,
            0x0000000000000000000000000000000000000001,
            Core(staking.getCoreAddress()).getBalance(
                address(this),
                0x0000000000000000000000000000000000000001
            )
        );
    }
}

contract TestERC20 is ERC20 {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function name() public view override returns (string memory) {
        return "TestToken";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return "TTK";
    }
}

contract HelperCa {
    Core core;

    constructor(address _evvm) {
        core = Core(_evvm);
    }

    function makeCaPay(address user, address token, uint256 amount) public {
        core.caPay(user, token, amount);
    }

    function makeDisperseCaPay(
        CoreStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 totalAmount
    ) public {
        core.disperseCaPay(toData, token, totalAmount);
    }
}

interface ITartarusV1 {
    function burnToken(address user, address token, uint256 amount) external;
}

contract TartarusV1 is CoreStorage {
    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;
    }
}

interface ITartarusV2 {
    function burnToken(address user, address token, uint256 amount) external;

    function fullTransfer(address from, address to, address token) external;
}

contract TartarusV2 is CoreStorage {
    function fullTransfer(address from, address to, address token) external {
        balances[to][token] += balances[from][token];
        balances[from][token] -= balances[from][token];
    }
}

interface ITartarusV3 {
    function burnToken(address user, address token, uint256 amount) external;

    function getCounter() external view returns (uint256);
}

// Primero definimos la interfaz
interface ICounter {
    function increment() external;

    function getCounter() external view returns (uint256);
}

contract TartarusV3 is CoreStorage {
    address public immutable counterAddress;

    constructor(address _counterAddress) {
        counterAddress = _counterAddress;
    }

    function burnToken(address user, address token, uint256 amount) external {
        if (balances[user][token] < amount) {
            revert();
        }

        balances[user][token] -= amount;

        ICounter(counterAddress).increment();
    }

    function getCounter() external view returns (uint256) {
        // Usamos la interfaz para la llamada
        (bool success, bytes memory data) = counterAddress.staticcall(
            abi.encodeWithSignature("getCounter()")
        );
        if (!success) {
            revert();
        }
        return abi.decode(data, (uint256));
    }
}

contract CounterDummy {
    uint256 counterNum;

    function increment() external {
        counterNum++;
    }

    function getCounter() external view returns (uint256) {
        return counterNum;
    }
}
