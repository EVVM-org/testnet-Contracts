// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 _____                                                       
/__   \_ __ ___  __ _ ___ _   _ _ __ _   _                   
  / /\| '__/ _ \/ _` / __| | | | '__| | | |                  
 / /  | | |  __| (_| \__ | |_| | |  | |_| |                  
 \/   |_|  \___|\__,_|___/\__,_|_|   \__, |                  
                                     |___/                   
   ___ _           _       __ _        _   _                 
  / __| |__   __ _(_)_ __ / _| |_ __ _| |_(_) ___  _ __      
 / /  | '_ \ / _` | | '_ \\ \| __/ _` | __| |/ _ \| '_ \     
/ /___| | | | (_| | | | | _\ | || (_| | |_| | (_) | | | |    
\____/|_| |_|\__,_|_|_| |_\__/\__\__,_|\__|_|\___/|_| |_|    
                                                             
                                                             
                                                             
 _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ 
|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|
                                                             
    ______     __                        __        __          _     
   / _____  __/ /____  _________  ____ _/ /  _____/ /_  ____ _(_____ 
  / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / ___/ __ \/ __ `/ / __ \
 / /____>  </ /_/  __/ /  / / / / /_/ / /  / /__/ / / / /_/ / / / / /
/_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/   \___/_/ /_/\__,_/_/_/ /_/ 
                                                                      
 * @title EVVM External Chain Station
 * @author Mate labs
 * @notice Manages cross-chain deposits from an external chain to the EVVM host chain.
 * @dev Multi-protocol bridge supporting Hyperlane, LayerZero V2, and Axelar. 
 *      Facilitates token transfers using a sequential nonce system and ECDSA signatures.
 */
import {IERC20} from "@evvm/testnet-contracts/library/primitives/IERC20.sol";
import {
    CrossChainTreasuryError as Error
} from "@evvm/testnet-contracts/library/errors/CrossChainTreasuryError.sol";
import {
    StateError
} from "@evvm/testnet-contracts/library/errors/StateError.sol";
import {
    SignatureRecover
} from "@evvm/testnet-contracts/library/primitives/SignatureRecover.sol";
import {
    TreasuryCrossChainHashUtils as Hash
} from "@evvm/testnet-contracts/library/utils/signature/TreasuryCrossChainHashUtils.sol";
import {
    ExternalChainStationStructs
} from "@evvm/testnet-contracts/library/structs/ExternalChainStationStructs.sol";

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {
    ProposalStructs
} from "@evvm/testnet-contracts/library/utils/governance/ProposalStructs.sol";
import {
    PayloadUtils
} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/PayloadUtils.sol";

import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

import {
    MessagingParams,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {
    OApp,
    Origin,
    MessagingFee
} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {
    OAppOptionsType3
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {
    OptionsBuilder
} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {
    AxelarExecutable
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {
    IAxelarGasService
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {
    IInterchainGasEstimation
} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainGasEstimation.sol";
import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

contract TreasuryExternalChainStation is
    OApp,
    OAppOptionsType3,
    AxelarExecutable
{
    /// @notice Admin address management with time-delayed proposals
    /// @dev Stores current admin, proposed admin, and acceptance timestamp
    ProposalStructs.AddressTypeProposal admin;

    /// @notice Fisher executor address management with time-delayed proposals
    /// @dev Fisher executor can process cross-chain bridge transactions
    ProposalStructs.AddressTypeProposal fisherExecutor;

    /// @notice Hyperlane protocol configuration for cross-chain messaging
    /// @dev Contains domain ID, host chain address, and mailbox contract address
    ExternalChainStationStructs.HyperlaneConfig hyperlane;

    /// @notice LayerZero protocol configuration for omnichain messaging
    /// @dev Contains endpoint ID, host chain address, and endpoint contract address
    ExternalChainStationStructs.LayerZeroConfig layerZero;

    /// @notice Axelar protocol configuration for cross-chain communication
    /// @dev Contains chain name, host chain address, gas service, and gateway addresses
    ExternalChainStationStructs.AxelarConfig axelar;

    /// @notice Pending proposal for changing host chain addresses across all protocols
    /// @dev Used for coordinated updates to host chain addresses with time delay
    ExternalChainStationStructs.ChangeHostChainAddressParams hostChainAddress;

    /// @notice Unique identifier for the EVVM instance this station belongs to
    /// @dev Immutable value set at deployment for signature verification
    uint256 evvmID;

    uint256 windowTimeToChangeEvvmID;

    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncNonce;

    /// @notice LayerZero execution options with gas limit configuration
    /// @dev Pre-built options for LayerZero message execution (200k gas limit)
    bytes options =
        OptionsBuilder.addExecutorLzReceiveOption(
            OptionsBuilder.newOptions(),
            200_000,
            0
        );

    /// @notice One-time fuse for setting initial host chain addresses
    /// @dev Prevents multiple calls to _setHostChainAddress after initial setup
    bytes1 fuseSetHostChainAddress = 0x01;

    /// @notice Emitted when Fisher bridge sends tokens from external to host chain
    /// @param from Original sender address on external chain
    /// @param addressToReceive Recipient address on host chain
    /// @param tokenAddress Token contract address (address(0) for ETH)
    /// @param priorityFee Fee paid for priority processing
    /// @param amount Amount of tokens transferred
    /// @param nonce Sequential nonce for the Fisher bridge operation
    event FisherBridgeSend(
        address indexed from,
        address indexed addressToReceive,
        address indexed tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce
    );

    /// @notice Restricts function access to the current admin only
    /// @dev Validates caller against admin.current address
    modifier onlyAdmin() {
        if (msg.sender != admin.current) {
            revert();
        }
        _;
    }

    /// @notice Restricts function access to the current Fisher executor only
    /// @dev Validates caller against fisherExecutor.current address for bridge operations
    modifier onlyFisherExecutor() {
        if (msg.sender != fisherExecutor.current) {
            revert();
        }
        _;
    }

    /// @notice Initializes the External Chain Station with cross-chain protocol configurations
    /// @dev Sets up Hyperlane, LayerZero, and Axelar configurations for multi-protocol support
    /// @param _admin Initial admin address with full administrative privileges
    /// @param _crosschainConfig Configuration struct containing all cross-chain protocol settings
    constructor(
        address _admin,
        ExternalChainStationStructs.CrosschainConfig memory _crosschainConfig
    )
        OApp(_crosschainConfig.layerZero.endpointAddress, _admin)
        Ownable(_admin)
        AxelarExecutable(_crosschainConfig.axelar.gatewayAddress)
    {
        admin = ProposalStructs.AddressTypeProposal({
            current: _admin,
            proposal: address(0),
            timeToAccept: 0
        });
        hyperlane = ExternalChainStationStructs.HyperlaneConfig({
            hostChainStationDomainId: _crosschainConfig
                .hyperlane
                .hostChainStationDomainId,
            hostChainStationAddress: "",
            mailboxAddress: _crosschainConfig.hyperlane.mailboxAddress
        });
        layerZero = ExternalChainStationStructs.LayerZeroConfig({
            hostChainStationEid: _crosschainConfig
                .layerZero
                .hostChainStationEid,
            hostChainStationAddress: "",
            endpointAddress: _crosschainConfig.layerZero.endpointAddress
        });
        axelar = ExternalChainStationStructs.AxelarConfig({
            hostChainStationChainName: _crosschainConfig
                .axelar
                .hostChainStationChainName,
            hostChainStationAddress: "",
            gasServiceAddress: _crosschainConfig.axelar.gasServiceAddress,
            gatewayAddress: _crosschainConfig.axelar.gatewayAddress
        });
    }

    /// @notice One-time setup of host chain station address across all protocols
    /// @dev Can only be called once (protected by fuseSetHostChainAddress)
    /// @param hostChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param hostChainStationAddressString String representation for Axelar protocol
    function _setHostChainAddress(
        address hostChainStationAddress,
        string memory hostChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetHostChainAddress != 0x01) revert();

        hyperlane.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        layerZero.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        axelar.hostChainStationAddress = hostChainStationAddressString;
        _setPeer(
            layerZero.hostChainStationEid,
            layerZero.hostChainStationAddress
        );

        hostChainAddress.currentAddress = hostChainStationAddress;

        fuseSetHostChainAddress = 0x00;
    }

    /**
     * @notice Updates the EVVM ID with a new value, restricted to admin and time-limited
     * @dev Allows the admin to change the EVVM ID within a 1-day window after deployment
     */
    function setEvvmID(uint256 newEvvmID) external onlyAdmin {
        if (evvmID != 0) {
            if (block.timestamp > windowTimeToChangeEvvmID)
                revert Error.WindowToChangeEvvmIDExpired();
        }

        evvmID = newEvvmID;

        windowTimeToChangeEvvmID = block.timestamp + 24 hours;
    }

    /**
     * @notice Deposits ERC20 tokens via selected protocol
     * @dev Transfers tokens then bridges to host chain
     *
     * Process:
     * - Transfer: User → this contract (via approval)
     * - Encode: PayloadUtils.encodePayload(token, to, amt)
     * - Route: Protocol-specific message dispatch
     * - Receive: Host chain credits Core.sol balance
     *
     * Protocol Routing:
     * - 0x01: Hyperlane (mailbox.dispatch + quote fee)
     * - 0x02: LayerZero (_lzSend + quote fee)
     * - 0x03: Axelar (payNativeGas + callContract)
     *
     * Fee Payment:
     * - Hyperlane: msg.value = quote
     * - LayerZero: msg.value = quote (refund excess)
     * - Axelar: msg.value for gas service
     *
     * Host Chain Integration:
     * - Receives: handle/_lzReceive/_execute
     * - Credits: Core.sol balance for recipient
     * - Fisher Bridge: Independent from Core.sol nonces
     *
     * Security:
     * - Approval: Must approve this contract first
     * - Validation: verifyAndDepositERC20 checks balance
     * - Sender checks: Host validates origin on receive
     *
     * @param toAddress Recipient on host chain
     * @param token ERC20 token address
     * @param amount Token amount to bridge
     * @param protocolToExecute 0x01=Hyperlane, 0x02=LZ,
     * 0x03=Axelar
     */
    function depositERC20(
        address toAddress,
        address token,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        bytes memory payload = PayloadUtils.encodePayload(
            token,
            toAddress,
            amount
        );
        verifyAndDepositERC20(token, amount);
        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, token, amount);
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 quote = quoteLayerZero(toAddress, token, amount);
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                options,
                MessagingFee(quote, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    /**
     * @notice Deposits native ETH via selected protocol
     * @dev msg.value covers amount + protocol fees
     *
     * Process:
     * - Validate: msg.value >= amount + fees
     * - Encode: PayloadUtils.encodePayload(0x0, to, amt)
     * - Route: Protocol-specific message dispatch
     * - Receive: Host chain credits Core.sol balance
     *
     * Protocol Routing:
     * - 0x01: Hyperlane (dispatch w/ quote + amount)
     * - 0x02: LayerZero (_lzSend w/ fee + amount)
     * - 0x03: Axelar (payNativeGas then callContract)
     *
     * Fee Calculation:
     * - Hyperlane: msg.value = quote + amount
     * - LayerZero: msg.value = fee + amount (refund)
     * - Axelar: msg.value = gasService + amount
     *
     * Host Chain Integration:
     * - Token Representation: address(0) for native ETH
     * - Payload: Encoded with zero address
     * - Credits: Core.sol balance as native token
     * - Fisher Bridge: Independent nonce system
     *
     * Security:
     * - Balance Check: Reverts if insufficient value
     * - Excess Handling: LZ refunds, others use full
     * - Validation: Host validates origin and sender
     *
     * @param toAddress Recipient on host chain
     * @param amount ETH amount to bridge
     * @param protocolToExecute 0x01=Hyperlane, 0x02=LZ,
     * 0x03=Axelar
     */
    function depositCoin(
        address toAddress,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        if (msg.value < amount) revert Error.InsufficientBalance();

        bytes memory payload = PayloadUtils.encodePayload(
            address(0),
            toAddress,
            amount
        );

        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, address(0), amount);
            if (msg.value < quote + amount) revert Error.InsufficientBalance();
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 fee = quoteLayerZero(toAddress, address(0), amount);
            if (msg.value < fee + amount) revert Error.InsufficientBalance();
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                options,
                MessagingFee(fee, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value - amount}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    /**
     * @notice Validates Fisher bridge receive confirmation
     * @dev Confirms tokens sent FROM host TO external chain
     *
     * Purpose:
     * - Acknowledge: Confirm host sent tokens
     * - Validate: Signature from original sender
     * - Track: Mark nonce as used
     * - Security: Prevent replay attacks
     *
     * Signature Validation:
     * - Payload: AdvancedStrings.buildSignaturePayload
     * - Components: evvmID, host address, hash, nonce
     * - Hash: TreasuryCrossChainHashUtils.hashData...
     * - Recovers: Must match 'from' address
     *
     * Nonce System:
     * - Independent: asyncNonce[from][nonce] mapping
     * - Sequential: User manages nonce ordering
     * - NOT Core.sol: Fisher bridge separate system
     * - Prevention: Revert if nonce already used
     *
     * Integration Context:
     * - Core.sol: NOT used (independent nonces)
     * - Core.sol: NOT on external chain
     * - SignatureRecover: ECDSA signature validation
     * - Host Chain: Sends tokens via protocol messages
     *
     * Security Flow:
     * - Check: Nonce not already used
     * - Recover: Signer from signature payload
     * - Validate: Recovered signer == from address
     * - Mark: asyncNonce[from][nonce] = true
     *
     * @param from Original sender on host chain
     * @param addressToReceive Recipient on external chain
     * @param tokenAddress Token (address(0) for ETH)
     * @param priorityFee Fee for priority processing
     * @param amount Token amount received
     * @param nonce Sequential nonce from user
     * @param signature ECDSA signature from 'from' address
     */
    function fisherBridgeReceive(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (asyncNonce[from][nonce]) revert StateError.AsyncNonceAlreadyUsed();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    hostChainAddress.currentAddress,
                    Hash.hashDataForFisherBridge(
                        addressToReceive,
                        tokenAddress,
                        priorityFee,
                        amount
                    ),
                    fisherExecutor.current,
                    nonce,
                    true
                ),
                signature
            ) != from
        ) revert StateError.InvalidSignature();

        asyncNonce[from][nonce] = true;
    }

    /**
     * @notice Executes Fisher bridge ERC20 deposit to host
     * @dev Validates signature, deposits, emits event
     *
     * Purpose:
     * - Deposit: Transfer ERC20 from user to contract
     * - Validate: ECDSA signature from sender
     * - Track: Mark nonce as used
     * - Emit: Log for Fisher executor on host chain
     *
     * Fisher Bridge Flow:
     * - External: User signs intent + executor calls this
     * - Deposit: Tokens held in this contract
     * - Event: FisherBridgeSend logged
     * - Host: Fisher monitors events + credits balance
     * - Core.sol: Host chain credits recipient balance
     *
     * Signature Validation:
     * - Payload: evvmID + host address + hash + nonce
     * - Hash: hashDataForFisherBridge(to, token, fee,
     *   amt)
     * - Recover: SignatureRecover.recoverSigner
     * - Match: Recovered signer must equal 'from'
     *
     * Nonce System:
     * - Independent: asyncNonce[from][nonce]
     * - NOT Core.sol: Separate from EVVM nonces
     * - Sequential: User manages own nonces
     * - Replay Prevention: Mark used after validation
     *
     * Integration Context:
     * - Core.sol: NOT used (Fisher independent)
     * - Core.sol: Credits balance on host chain
     * - Fisher Executor: Monitors events + processes
     * - Host Station: Receives event + credits user
     *
     * Security:
     * - Approval: Requires token approval first
     * - Signature: ECDSA validation prevents forgery
     * - Nonce: Sequential tracking prevents replays
     * - Executor Only: onlyFisherExecutor modifier
     *
     * @param from Original sender (signer)
     * @param addressToReceive Recipient on host chain
     * @param tokenAddress ERC20 token address
     * @param priorityFee Fee for priority processing
     * @param amount Token amount to bridge
     * @param nonce Sequential nonce from user
     * @param signature ECDSA signature from 'from'
     */
    function fisherBridgeSendERC20(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (asyncNonce[from][nonce]) revert StateError.AsyncNonceAlreadyUsed();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    hostChainAddress.currentAddress,
                    Hash.hashDataForFisherBridge(
                        addressToReceive,
                        tokenAddress,
                        priorityFee,
                        amount
                    ),
                    fisherExecutor.current,
                    nonce,
                    true
                ),
                signature
            ) != from
        ) revert StateError.InvalidSignature();

        verifyAndDepositERC20(tokenAddress, amount);

        asyncNonce[from][nonce] = true;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            tokenAddress,
            priorityFee,
            amount,
            nonce
        );
    }

    /**
     * @notice Executes Fisher bridge ETH deposit to host
     * @dev Validates signature and exact payment
     *
     * Purpose:
     * - Deposit: Receive ETH from executor caller
     * - Validate: ECDSA signature from original sender
     * - Track: Mark nonce as used
     * - Emit: Log for Fisher executor on host chain
     *
     * Fisher Bridge Flow:
     * - External: User signs intent + pays executor
     * - Deposit: msg.value = amount + priorityFee
     * - Event: FisherBridgeSend with address(0)
     * - Host: Fisher monitors + credits Evvm balance
     * - Core.sol: Host chain credits recipient
     *
     * Payment Validation:
     * - Exact Match: msg.value == amount + priorityFee
     * - No Excess: Prevents overpayment mistakes
     * - Native Token: Represented as address(0)
     * - Host Credits: Full amount to recipient
     *
     * Signature Validation:
     * - Payload: evvmID + host + hash + nonce
     * - Hash: hashDataForFisherBridge(to, 0x0, fee,
     *   amt)
     * - Token: address(0) represents native ETH
     * - Recover: Must match 'from' address
     *
     * Nonce System:
     * - Independent: asyncNonce[from][nonce]
     * - NOT Core.sol: Fisher bridge separate
     * - Sequential: User-managed ordering
     * - Anti-Replay: Mark used after validation
     *
     * Integration Context:
     * - Core.sol: NOT used (independent system)
     * - Core.sol: Credits native balance on host
     * - Fisher Executor: Pays ETH + processes
     * - Host Station: Credits recipient balance
     *
     * Security:
     * - Exact Payment: Prevents partial payments
     * - Signature: ECDSA prevents unauthorized sends
     * - Nonce: Sequential tracking prevents replays
     * - Executor Only: onlyFisherExecutor modifier
     *
     * @param from Original sender (signer)
     * @param addressToReceive Recipient on host chain
     * @param priorityFee Fee for priority processing
     * @param amount ETH amount to bridge
     * @param nonce Sequential nonce from user
     * @param signature ECDSA signature from 'from'
     */
    function fisherBridgeSendCoin(
        address from,
        address addressToReceive,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external payable onlyFisherExecutor {
        if (asyncNonce[from][nonce]) revert StateError.AsyncNonceAlreadyUsed();

        if (
            SignatureRecover.recoverSigner(
                AdvancedStrings.buildSignaturePayload(
                    evvmID,
                    hostChainAddress.currentAddress,
                    Hash.hashDataForFisherBridge(
                        addressToReceive,
                        address(0),
                        priorityFee,
                        amount
                    ),
                    fisherExecutor.current,
                    nonce,
                    true
                ),
                signature
            ) != from
        ) revert StateError.InvalidSignature();

        if (msg.value != amount + priorityFee)
            revert Error.InsufficientBalance();

        asyncNonce[from][nonce] = true;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            address(0),
            priorityFee,
            amount,
            nonce
        );
    }

    // Hyperlane Specific Functions //

    /**
     * @notice Quotes Hyperlane cross-chain message fee
     * @dev Queries mailbox for accurate fee estimation
     *
     * Purpose:
     * - Estimate: Calculate native token fee for message
     * - Quote: Query Hyperlane mailbox contract
     * - Planning: Users know cost before depositERC20
     * - Payment: Fee paid in msg.value on deposit
     *
     * Hyperlane Fee Model:
     * - Calculation: mailbox.quoteDispatch
     * - Components: Destination domain + payload size
     * - Payment: Native token to mailbox
     * - Delivery: Relayers submit to destination
     *
     * Quote Components:
     * - Domain ID: hyperlane.hostChainStationDomainId
     * - Recipient: hyperlane.hostChainStationAddress
     * - Payload: PayloadUtils.encodePayload(token, to,
     *   amt)
     *
     * Usage:
     * - Pre-Deposit: Call to estimate required msg.value
     * - Display: Show users total cost
     * - Payment: depositERC20 uses quote for dispatch
     *
     * @param toAddress Recipient on host chain
     * @param token Token address (or 0x0 for ETH)
     * @param amount Token amount to bridge
     * @return Native token fee for Hyperlane message
     */
    function getQuoteHyperlane(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        return
            IMailbox(hyperlane.mailboxAddress).quoteDispatch(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                PayloadUtils.encodePayload(token, toAddress, amount)
            );
    }

    /**
     * @notice Handles incoming Hyperlane messages
     * @dev Validates origin, sender, processes payload
     *
     * Purpose:
     * - Receive: Messages from host chain via Hyperlane
     * - Validate: Origin domain + sender address
     * - Process: Decode payload + transfer tokens
     * - Security: Multi-layer validation checks
     *
     * Hyperlane Message Flow:
     * - Host: TreasuryHostChainStation dispatches
     * - Relayer: Submits message to this chain
     * - Mailbox: Calls this handle() function
     * - Process: decodeAndGive transfers tokens
     *
     * Validation Layers:
     * - Caller: Must be hyperlane.mailboxAddress
     * - Sender: Must be hyperlane.hostChainStation...
     * - Origin: Must be hyperlane.hostChainStation
     *   DomainId
     * - All checks prevent unauthorized messages
     *
     * Payload Processing:
     * - Decode: PayloadUtils.decodePayload(_data)
     * - Extract: token address, recipient, amount
     * - Transfer: ETH (address 0) or ERC20 tokens
     * - Recipient: Receives tokens on external chain
     *
     * Security:
     * - Mailbox Only: Reverts if caller not mailbox
     * - Sender Check: Reverts if not host station
     * - Domain Check: Reverts if wrong origin
     * - Three-layer validation prevents attacks
     *
     * @param _origin Source chain domain ID
     * @param _sender Sender address (host station)
     * @param _data Encoded payload (token, to, amount)
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != hyperlane.mailboxAddress)
            revert Error.MailboxNotAuthorized();

        if (_sender != hyperlane.hostChainStationAddress)
            revert Error.SenderNotAuthorized();

        if (_origin != hyperlane.hostChainStationDomainId)
            revert Error.ChainIdNotAuthorized();

        decodeAndGive(_data);
    }

    // LayerZero Specific Functions //

    /**
     * @notice Quotes LayerZero cross-chain message fee
     * @dev Queries endpoint for native fee estimation
     *
     * Purpose:
     * - Estimate: Calculate native token fee for LZ send
     * - Quote: Query LayerZero V2 endpoint
     * - Planning: Users know cost before deposit
     * - Payment: Fee paid in msg.value on deposit
     *
     * LayerZero Fee Model:
     * - Calculation: _quote (internal OApp function)
     * - Components: Destination eid + payload + options
     * - Options: 200k gas limit for execution
     * - Refund: Excess fees returned to sender
     *
     * Quote Components:
     * - Endpoint ID: layerZero.hostChainStationEid
     * - Payload: PayloadUtils.encodePayload
     * - Options: Pre-built with 200k gas limit
     * - Pay ZRO: false (only native token)
     *
     * Usage:
     * - Pre-Deposit: Call to estimate required msg.value
     * - Display: Show users total cost
     * - Payment: depositERC20/Coin uses quote
     * - Refund: LZ returns excess to sender
     *
     * @param toAddress Recipient on host chain
     * @param token Token address (or 0x0 for ETH)
     * @param amount Token amount to bridge
     * @return Native token fee for LayerZero message
     */
    function quoteLayerZero(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        MessagingFee memory fee = _quote(
            layerZero.hostChainStationEid,
            PayloadUtils.encodePayload(token, toAddress, amount),
            options,
            false
        );
        return fee.nativeFee;
    }

    /**
     * @notice Handles incoming LayerZero messages
     * @dev Validates origin + sender, processes payload
     *
     * Purpose:
     * - Receive: Messages from host via LayerZero V2
     * - Validate: Origin eid + sender address
     * - Process: Decode payload + transfer tokens
     * - Security: Multi-layer validation checks
     *
     * LayerZero Message Flow:
     * - Host: TreasuryHostChainStation.lzSend
     * - DVNs: Verify message across networks
     * - Executor: Submits message to this chain
     * - Endpoint: Calls this _lzReceive function
     *
     * Validation Layers:
     * - Origin EID: Must be layerZero.hostChainStation
     *   Eid
     * - Sender: Must be layerZero.hostChainStation
     *   Address
     * - Peer: OApp validates via _getPeerOrRevert
     * - All checks prevent unauthorized messages
     *
     * Payload Processing:
     * - Decode: PayloadUtils.decodePayload(message)
     * - Extract: token address, recipient, amount
     * - Transfer: ETH (address 0) or ERC20 tokens
     * - Recipient: Receives tokens on external chain
     *
     * Security:
     * - EID Check: Reverts if wrong source endpoint
     * - Sender Check: Reverts if not host station
     * - OApp Pattern: Peer validation built-in
     * - Two-layer validation prevents attacks
     *
     * @param _origin Origin info (srcEid, sender,
     * nonce)
     * @param message Encoded payload (token, to, amount)
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/, // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/ // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the payload to get the message
        if (_origin.srcEid != layerZero.hostChainStationEid)
            revert Error.ChainIdNotAuthorized();

        if (_origin.sender != layerZero.hostChainStationAddress)
            revert Error.SenderNotAuthorized();

        decodeAndGive(message);
    }

    /// @notice Sends LayerZero messages to the destination chain
    /// @dev Handles fee payment and message dispatch through LayerZero endpoint
    /// @param _dstEid Destination endpoint ID (target chain)
    /// @param _message Encoded message payload to send
    /// @param _options Execution options for the destination chain
    /// @param _fee Messaging fee structure (native + LZ token fees)
    /// @param _refundAddress Address to receive excess fees
    /// @return receipt Messaging receipt with transaction details
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal override returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _fee.nativeFee;
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        return
            // solhint-disable-next-line check-send-result
            endpoint.send{value: messageValue}(
                MessagingParams(
                    _dstEid,
                    _getPeerOrRevert(_dstEid),
                    _message,
                    _options,
                    _fee.lzTokenFee > 0
                ),
                _refundAddress
            );
    }

    // Axelar Specific Functions //

    /**
     * @notice Handles incoming Axelar messages
     * @dev Validates source chain/address, processes payload
     *
     * Purpose:
     * - Receive: Messages from host via Axelar Network
     * - Validate: Source chain name + sender address
     * - Process: Decode payload + transfer tokens
     * - Security: Multi-layer validation checks
     *
     * Axelar Message Flow:
     * - Host: TreasuryHostChainStation.callContract
     * - Axelar: Validates via validator network
     * - Gateway: Calls this _execute function
     * - Process: decodeAndGive transfers tokens
     *
     * Validation Layers:
     * - Source Chain: Must be axelar.hostChainStation
     *   ChainName
     * - Source Address: Must be axelar.hostChainStation
     *   Address
     * - Gateway: AxelarExecutable validates caller
     * - All checks prevent unauthorized messages
     *
     * String Comparison:
     * - AdvancedStrings.equal: Chain name validation
     * - Case-Sensitive: Exact match required
     * - Address Format: String type for Axelar
     * - Security: Double validation of source
     *
     * Payload Processing:
     * - Decode: PayloadUtils.decodePayload(_payload)
     * - Extract: token address, recipient, amount
     * - Transfer: ETH (address 0) or ERC20 tokens
     * - Recipient: Receives tokens on external chain
     *
     * Security:
     * - Chain Check: Reverts if wrong source chain
     * - Address Check: Reverts if not host station
     * - Gateway Pattern: AxelarExecutable validation
     * - Two-layer validation prevents attacks
     *
     * @param _sourceChain Source blockchain name
     * @param _sourceAddress Source contract address
     * @param _payload Encoded payload (token, to, amount)
     */
    function _execute(
        bytes32 /*commandId*/,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        if (
            !AdvancedStrings.equal(
                _sourceChain,
                axelar.hostChainStationChainName
            )
        ) revert Error.ChainIdNotAuthorized();

        if (
            !AdvancedStrings.equal(
                _sourceAddress,
                axelar.hostChainStationAddress
            )
        ) revert Error.SenderNotAuthorized();

        decodeAndGive(_payload);
    }

    /// @notice Proposes a new admin address with 1-day time delay
    /// @dev Part of the time-delayed governance system for admin changes
    /// @param _newOwner Address of the proposed new admin (cannot be zero or current admin)
    function proposeAdmin(address _newOwner) external onlyAdmin {
        if (_newOwner == address(0) || _newOwner == admin.current) revert();

        admin.proposal = _newOwner;
        admin.timeToAccept = block.timestamp + 1 minutes;
    }

    /// @notice Cancels a pending admin change proposal
    /// @dev Allows current admin to reject proposed admin changes and reset proposal state
    function rejectProposalAdmin() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /// @notice Accepts a pending admin proposal and becomes the new admin
    /// @dev Can only be called by the proposed admin after the 1-day time delay
    function acceptAdmin() external {
        if (block.timestamp < admin.timeToAccept) revert();

        if (msg.sender != admin.proposal) revert();

        admin.current = admin.proposal;

        admin.proposal = address(0);
        admin.timeToAccept = 0;

        _transferOwnership(admin.current);
    }

    /// @notice Proposes a new Fisher executor address with 1-day time delay
    /// @dev Fisher executor handles cross-chain bridge transaction processing
    /// @param _newFisherExecutor Address of the proposed new Fisher executor
    function proposeFisherExecutor(
        address _newFisherExecutor
    ) external onlyAdmin {
        if (
            _newFisherExecutor == address(0) ||
            _newFisherExecutor == fisherExecutor.current
        ) revert();

        fisherExecutor.proposal = _newFisherExecutor;
        fisherExecutor.timeToAccept = block.timestamp + 1 minutes;
    }

    /// @notice Cancels a pending Fisher executor change proposal
    /// @dev Allows current admin to reject Fisher executor changes and reset proposal state
    function rejectProposalFisherExecutor() external onlyAdmin {
        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    /// @notice Accepts a pending Fisher executor proposal
    /// @dev Can only be called by the proposed Fisher executor after the 1-day time delay
    function acceptFisherExecutor() external {
        if (block.timestamp < fisherExecutor.timeToAccept) revert();

        if (msg.sender != fisherExecutor.proposal) revert();

        fisherExecutor.current = fisherExecutor.proposal;

        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    /// @notice Proposes new host chain addresses for all protocols with 1-day time delay
    /// @dev Updates addresses across Hyperlane, LayerZero, and Axelar simultaneously
    /// @param hostChainStationAddress Address-type representation for Hyperlane and LayerZero
    /// @param hostChainStationAddressString String representation for Axelar protocol
    function proposeHostChainAddress(
        address hostChainStationAddress,
        string memory hostChainStationAddressString
    ) external onlyAdmin {
        if (fuseSetHostChainAddress == 0x01) revert();

        hostChainAddress = ExternalChainStationStructs
            .ChangeHostChainAddressParams({
                porposeAddress_AddressType: hostChainStationAddress,
                porposeAddress_StringType: hostChainStationAddressString,
                currentAddress: hostChainAddress.currentAddress,
                timeToAccept: block.timestamp + 1 minutes
            });
    }

    /// @notice Cancels a pending host chain address change proposal
    /// @dev Resets the host chain address proposal to default state
    function rejectProposalHostChainAddress() external onlyAdmin {
        hostChainAddress = ExternalChainStationStructs
            .ChangeHostChainAddressParams({
                porposeAddress_AddressType: address(0),
                porposeAddress_StringType: "",
                currentAddress: hostChainAddress.currentAddress,
                timeToAccept: 0
            });
    }

    /// @notice Accepts pending host chain address changes across all protocols
    /// @dev Updates Hyperlane, LayerZero, and Axelar configurations simultaneously
    function acceptHostChainAddress() external {
        if (block.timestamp < hostChainAddress.timeToAccept) revert();

        hyperlane.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainAddress.porposeAddress_AddressType))
        );
        layerZero.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainAddress.porposeAddress_AddressType))
        );
        axelar.hostChainStationAddress = hostChainAddress
            .porposeAddress_StringType;

        _setPeer(
            layerZero.hostChainStationEid,
            layerZero.hostChainStationAddress
        );

        hostChainAddress = ExternalChainStationStructs
            .ChangeHostChainAddressParams({
                porposeAddress_AddressType: address(0),
                porposeAddress_StringType: "",
                currentAddress: hostChainAddress.porposeAddress_AddressType,
                timeToAccept: 0
            });
    }

    // Getter functions //

    /// @notice Returns the complete admin configuration including proposals and timelock
    /// @return Current admin address, proposed admin, and acceptance timestamp
    function getAdmin()
        external
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return admin;
    }

    /// @notice Returns the complete Fisher executor configuration including proposals and timelock
    /// @return Current Fisher executor address, proposed executor, and acceptance timestamp
    function getFisherExecutor()
        external
        view
        returns (ProposalStructs.AddressTypeProposal memory)
    {
        return fisherExecutor;
    }

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncNonce[user][nonce];
    }

    /// @notice Returns the complete Hyperlane protocol configuration
    /// @return Hyperlane configuration including domain ID, host chain address, and mailbox
    function getHyperlaneConfig()
        external
        view
        returns (ExternalChainStationStructs.HyperlaneConfig memory)
    {
        return hyperlane;
    }

    /// @notice Returns the complete LayerZero protocol configuration
    /// @return LayerZero configuration including endpoint ID, host chain address, and endpoint
    function getLayerZeroConfig()
        external
        view
        returns (ExternalChainStationStructs.LayerZeroConfig memory)
    {
        return layerZero;
    }

    /// @notice Returns the complete Axelar protocol configuration
    /// @return Axelar configuration including chain name, addresses, gas service, and gateway
    function getAxelarConfig()
        external
        view
        returns (ExternalChainStationStructs.AxelarConfig memory)
    {
        return axelar;
    }

    /// @notice Returns the LayerZero execution options configuration
    /// @return Encoded options bytes for LayerZero message execution (200k gas limit)
    function getOptions() external view returns (bytes memory) {
        return options;
    }

    // Internal Functions //

    /// @notice Decodes cross-chain payload and executes the token transfer
    /// @dev Handles both ETH (address(0)) and ERC20 token transfers to recipients
    /// @param payload Encoded transfer data containing token, recipient, and amount
    function decodeAndGive(bytes memory payload) internal {
        (address token, address toAddress, uint256 amount) = PayloadUtils
            .decodePayload(payload);
        if (token == address(0))
            SafeTransferLib.safeTransferETH(toAddress, amount);
        else IERC20(token).transfer(toAddress, amount);
    }

    /// @notice Validates and deposits ERC20 tokens from the caller
    /// @dev Verifies token approval and executes transferFrom to this contract
    /// @param token ERC20 token contract address (cannot be address(0))
    /// @param amount Amount of tokens to deposit and hold in this contract
    function verifyAndDepositERC20(address token, uint256 amount) internal {
        if (token == address(0)) revert();
        if (IERC20(token).allowance(msg.sender, address(this)) < amount)
            revert Error.InsufficientBalance();

        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Disabled ownership transfer function for security
    /// @dev Ownership changes must go through the time-delayed admin proposal system
    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {}

    /// @notice Disabled ownership renouncement function for security
    /// @dev Prevents accidental loss of administrative control over the contract
    function renounceOwnership() public virtual override onlyOwner {}
}
