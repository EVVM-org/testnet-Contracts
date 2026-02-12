// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

library ExternalChainStationStructs {
    struct AxelarConfig {
        string hostChainStationChainName;
        string hostChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    struct CrosschainConfig {
        HyperlaneConfig hyperlane;
        LayerZeroConfig layerZero;
        AxelarConfig axelar;
    }

    struct HyperlaneConfig {
        uint32 hostChainStationDomainId;
        bytes32 hostChainStationAddress;
        address mailboxAddress;
    }

    struct LayerZeroConfig {
        uint32 hostChainStationEid;
        bytes32 hostChainStationAddress;
        address endpointAddress;
    }
}

library ProposalStructs {
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }
}

interface ITreasuryExternalChainStation {
    struct EnforcedOptionParam {
        uint32 eid;
        uint16 msgType;
        bytes options;
    }

    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }

    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error AsyncNonceAlreadyUsed();
    error ChainIdNotAuthorized();
    error FailedInnerCall();
    error InsufficientBalance();
    error InvalidAddress();
    error InvalidDelegate();
    error InvalidEndpointCall();
    error InvalidOptionType(uint16 optionType);
    error InvalidOptions(bytes options);
    error InvalidSignature();
    error LzTokenUnavailable();
    error MailboxNotAuthorized();
    error NoPeer(uint32 eid);
    error NotApprovedByGateway();
    error NotEnoughNative(uint256 msgValue);
    error OnlyEndpoint(address addr);
    error OnlyPeer(uint32 eid, bytes32 sender);
    error OwnableInvalidOwner(address owner);
    error OwnableUnauthorizedAccount(address account);
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);
    error SafeERC20FailedOperation(address token);
    error SenderNotAuthorized();
    error WindowToChangeEvvmIDExpired();

    event EnforcedOptionSet(EnforcedOptionParam[] _enforcedOptions);
    event FisherBridgeSend(
        address indexed from,
        address indexed addressToReceive,
        address indexed tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PeerSet(uint32 eid, bytes32 peer);

    function _setHostChainAddress(address hostChainStationAddress, string memory hostChainStationAddressString) external;
    function acceptAdmin() external;
    function acceptFisherExecutor() external;
    function acceptHostChainAddress() external;
    function allowInitializePath(Origin memory origin) external view returns (bool);
    function combineOptions(uint32 _eid, uint16 _msgType, bytes memory _extraOptions)
        external
        view
        returns (bytes memory);
    function depositCoin(address toAddress, uint256 amount, bytes1 protocolToExecute) external payable;
    function depositERC20(address toAddress, address token, uint256 amount, bytes1 protocolToExecute) external payable;
    function endpoint() external view returns (address);
    function enforcedOptions(uint32 eid, uint16 msgType) external view returns (bytes memory enforcedOption);
    function execute(bytes32 commandId, string memory sourceChain, string memory sourceAddress, bytes memory payload)
        external;
    function fisherBridgeReceive(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
    function fisherBridgeSendCoin(
        address from,
        address addressToReceive,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external payable;
    function fisherBridgeSendERC20(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external;
    function gateway() external view returns (address);
    function getAdmin() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getAxelarConfig() external view returns (ExternalChainStationStructs.AxelarConfig memory);
    function getFisherExecutor() external view returns (ProposalStructs.AddressTypeProposal memory);
    function getHyperlaneConfig() external view returns (ExternalChainStationStructs.HyperlaneConfig memory);
    function getIfUsedAsyncNonce(address user, uint256 nonce) external view returns (bool);
    function getLayerZeroConfig() external view returns (ExternalChainStationStructs.LayerZeroConfig memory);
    function getOptions() external view returns (bytes memory);
    function getQuoteHyperlane(address toAddress, address token, uint256 amount) external view returns (uint256);
    function handle(uint32 _origin, bytes32 _sender, bytes memory _data) external payable;
    function isComposeMsgSender(Origin memory, bytes memory, address _sender) external view returns (bool);
    function lzReceive(
        Origin memory _origin,
        bytes32 _guid,
        bytes memory _message,
        address _executor,
        bytes memory _extraData
    ) external payable;
    function nextNonce(uint32, bytes32) external view returns (uint64 nonce);
    function oAppVersion() external pure returns (uint64 senderVersion, uint64 receiverVersion);
    function owner() external view returns (address);
    function peers(uint32 eid) external view returns (bytes32 peer);
    function proposeAdmin(address _newOwner) external;
    function proposeFisherExecutor(address _newFisherExecutor) external;
    function proposeHostChainAddress(address hostChainStationAddress, string memory hostChainStationAddressString)
        external;
    function quoteLayerZero(address toAddress, address token, uint256 amount) external view returns (uint256);
    function rejectProposalAdmin() external;
    function rejectProposalFisherExecutor() external;
    function rejectProposalHostChainAddress() external;
    function renounceOwnership() external;
    function setDelegate(address _delegate) external;
    function setEnforcedOptions(EnforcedOptionParam[] memory _enforcedOptions) external;
    function setEvvmID(uint256 newEvvmID) external;
    function setPeer(uint32 _eid, bytes32 _peer) external;
    function transferOwnership(address newOwner) external;
}
