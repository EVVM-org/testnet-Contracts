/**
 * Cross-Chain EVVM Deployment Command
 *
 * Comprehensive deployment wizard for EVVM ecosystem with cross-chain treasury support.
 * Handles dual-chain deployment, configuration validation, cross-chain protocol setup
 * (Hyperlane, LayerZero, Axelar), verification, and registration.
 *
 * @module cli/commands/deploy/deployCross
 */

import {
  confirmation,
  criticalError,
  customErrorWithExit,
  infoWithChainData,
  seccionTitle,
  sectionSubtitle,
  warning,
} from "../../utils/outputMesages";
import {
  verifyFoundryInstalledAndAccountSetup,
  showAllCrossChainDeployedContracts,
  forgeScript,
} from "../../utils/foundry";
import {
  configurationBasic,
  configurationCrossChain,
} from "../../utils/configurationInputs";
import { ChainData, colors } from "../../constants";
import { promptYesNo } from "../../utils/prompts";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { explorerVerification } from "../../utils/explorerVerification";
import { setUpCrossChainTreasuries } from "../setUpCrossChainTreasuries";
import { registerCross } from "../register/registerCross";

/**
 * Deploys a cross-chain EVVM instance with interactive configuration
 *
 * Executes a dual-chain deployment workflow:
 *
 * External Chain Deployment (TreasuryExternalChainStation.sol):
 * - Cross-chain messaging endpoints for asset bridging
 *
 * Host Chain Deployment:
 * - TreasuryHostChainStation.sol (cross-chain treasury coordinator)
 * - Core.sol (core protocol with cross-chain support)
 * - Staking.sol (validator staking)
 * - Estimator.sol (gas estimation)
 * - NameService.sol (domain name resolution)
 * - P2PSwap.sol (peer-to-peer token swaps)
 *
 * Process:
 * 1. Validates Foundry installation and both wallet accounts
 * 2. Collects base configuration (addresses, metadata)
 * 3. Collects cross-chain configuration (Hyperlane, LayerZero, Axelar)
 * 4. Deploys external chain station contract
 * 5. Deploys host chain contracts with cross-chain support
 * 6. Optionally connects treasury stations for bidirectional communication
 * 7. Optionally registers EVVM in registry with custom RPC support
 *
 * @param {string[]} args - Command arguments (unused, reserved for future use)
 * @param {any} options - Command options:
 *   - skipInputConfig: Skip interactive config, use input files (default: false)
 *   - walletNameHost: Foundry wallet for host chain (default: "defaultKey")
 *   - walletNameExternal: Foundry wallet for external chain (default: "defaultKey")
 * @returns {Promise<void>}
 */
export async function deployCross(args: string[], options: any) {
  // --skipInputConfig -s
  const skipInputConfig = options.skipInputConfig || false;
  // --walletNameHost
  const walletNameHost = options.walletNameHost || "defaultKey";
  // --walletNameExternal
  const walletNameExternal = options.walletNameExternal || "defaultKey";

  let externalRpcUrl: string | null = null;
  let externalChainId: number | null = null;
  let hostRpcUrl: string | null = null;
  let hostChainId: number | null = null;

  seccionTitle("Deploy EVVM Contracts", "Cross Chain Edition");

  await verifyFoundryInstalledAndAccountSetup([
    walletNameHost,
    walletNameExternal,
  ]);

  if (skipInputConfig) {
    warning(
      `Skipping input configuration`,
      `  ${colors.green}✓${colors.reset} Base inputs ${colors.darkGray}→ ./input/BaseInputs.sol${colors.reset}\n  ${colors.green}✓${colors.reset} Cross-chain inputs ${colors.darkGray}→ ./input/CrossChainInputs.sol${colors.reset}`
    );

    ({ rpcUrl: externalRpcUrl, chainId: externalChainId } =
      await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL));
    ({ rpcUrl: hostRpcUrl, chainId: hostChainId } = await getRPCUrlAndChainId(
      process.env.HOST_RPC_URL
    ));
  } else {
    sectionSubtitle("Configuration Basic Data");

    await configurationBasic();

    sectionSubtitle("Configuration Cross-Chain Data");

    const ccConfig = await configurationCrossChain();
    if (typeof ccConfig === "boolean" && ccConfig === false) return;

    externalRpcUrl = ccConfig.externalRpcUrl;
    externalChainId = ccConfig.externalChainId;
    hostRpcUrl = ccConfig.hostRpcUrl;
    hostChainId = ccConfig.hostChainId;
  }

  if (!externalRpcUrl && !externalChainId && !hostRpcUrl && !hostChainId)
    criticalError("RPC URLs and Chain IDs must be provided.");

  if (
    !promptYesNo(
      `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
    )
  ) {
    customErrorWithExit(
      "Deployment cancelled by user",
      `${colors.darkGray}Exiting deployment process.${colors.reset}`
    );
  }

  const verificationflagHost = await explorerVerification("Host Chain:");
  if (verificationflagHost === undefined)
    criticalError("Explorer verification setup failed.");

  const verificationflagExternal = await explorerVerification(
    "External Chain:"
  );

  if (verificationflagExternal === undefined)
    criticalError("Explorer verification setup failed.");

  infoWithChainData(
    `Deploying`,
    ChainData[externalChainId]?.Chain || "",
    externalChainId
  );

  await forgeScript(
    "script/DeployCrossChainExternal.s.sol:DeployCrossChainExternalScript",
    externalRpcUrl!,
    walletNameExternal,
    verificationflagExternal ? verificationflagExternal.split(" ") : []
  );

  infoWithChainData(
    `Deploying`,
    ChainData[hostChainId]?.Chain || "",
    hostChainId
  );

  console.log(
    `  ${colors.green}•${colors.reset} Treasury cross-chain contract ${colors.darkGray}(TreasuryHostChainStation.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} EVVM core contract ${colors.darkGray}(Core.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Staking contract ${colors.darkGray}(Staking.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Estimator contract ${colors.darkGray}(Estimator.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Name Service contract ${colors.darkGray}(NameService.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} P2P Swap service ${colors.darkGray}(P2PSwap.sol)${colors.reset}\n`
  );

  await forgeScript(
    "script/DeployCrossChainHost.s.sol:DeployCrossChainHostScript",
    hostRpcUrl!,
    walletNameHost,
    verificationflagHost ? verificationflagHost.split(" ") : []
  );

  confirmation(`Cross-chain EVVM deployed successfully!`);

  const {
    coreAddress,
    treasuryHostChainStationAddress,
    treasuryExternalChainStationAddress,
  } = await showAllCrossChainDeployedContracts(hostChainId!, externalChainId!);

  sectionSubtitle("Cross-chain communication setup and EVVM registration");
  console.log(`
${colors.yellow}⚠ Important:${colors.reset} Admin addresses on both chains must match each wallet used during deployment
${colors.yellow}  Host Chain Admin:     ${walletNameHost}${colors.reset}
${colors.yellow}  External Chain Admin: ${walletNameExternal}${colors.reset}

${colors.yellow}     → Mismatched admin addresses will prevent successful setup of cross-chain communication${colors.reset}

${colors.darkGray}   → If mismatched: Skip setup and run commands manually later${colors.reset}
${colors.darkGray}   → If already matching: Proceed with setup now${colors.reset}

${colors.bright}Manual setup commands:${colors.reset}
${colors.darkGray}1. Cross-chain communication:${colors.reset}
   ${colors.evvmGreen}evvm setUpCrossChainTreasuries \\${colors.reset}
   ${colors.evvmGreen}  --treasuryHostStationAddress ${treasuryHostChainStationAddress} \\${colors.reset}
   ${colors.evvmGreen}  --treasuryExternalStationAddress ${treasuryExternalChainStationAddress} \\${colors.reset}
   ${colors.evvmGreen}  --walletNameHost <wallet> --walletNameExternal <wallet>${colors.reset}

${colors.darkGray}2. EVVM registration:${colors.reset}
   ${colors.evvmGreen}evvm registerCrossChain \\${colors.reset}
   ${colors.evvmGreen}  --coreAddress ${coreAddress} \\${colors.reset}
   ${colors.evvmGreen}  --treasuryExternalStationAddress ${treasuryExternalChainStationAddress} \\${colors.reset}
   ${colors.evvmGreen}  --walletName <wallet>${colors.reset}

${colors.darkGray}More info: ${colors.blue}https://www.evvm.info/docs/QuickStart#6-register-in-registry-evvm${colors.reset}
`);

  if (
    !promptYesNo(
      `${colors.yellow}Do you want to continue with those steps? (y/n):${colors.reset}`
    )
  ) {
    customErrorWithExit(
      `Steps skipped by user choice`,
      `${colors.darkGray}You can complete setup later using the commands above.${colors.reset}`
    );
  }

  await setUpCrossChainTreasuries([], {
    treasuryHostStationAddress:
      treasuryHostChainStationAddress as `0x${string}`,
    treasuryExternalStationAddress:
      treasuryExternalChainStationAddress as `0x${string}`,
    walletNameHost: walletNameHost,
    walletNameExternal: walletNameExternal,
  });

  // If user decides, add --useCustomEthRpc flag to the registerEvvm call
  const ethRPCAns = promptYesNo(
    `${colors.yellow}Use custom Ethereum Sepolia RPC for registry calls? (y/n):${colors.reset}`
  );

  await registerCross([], {
    coreAddress: coreAddress,
    treasuryExternalStationAddress: treasuryExternalChainStationAddress,
    walletNameHost: walletNameHost,
    walletNameExternal: walletNameExternal,
    useCustomEthRpc: ethRPCAns,
  });
}
