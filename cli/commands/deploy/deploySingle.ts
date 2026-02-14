/**
 * Single-Chain EVVM Deployment Command
 *
 * Comprehensive deployment wizard for EVVM ecosystem contracts on a single blockchain.
 * Handles configuration, validation, deployment, block explorer verification, and
 * optional registration in the EVVM Registry.
 *
 * @module cli/commands/deploy/deploySingle
 */

import {
  forgeScript,
  isChainIdRegistered,
  showDeployContractsAndFindEvvm,
  verifyFoundryInstalledAndAccountSetup,
} from "../../utils/foundry";
import {
  chainIdNotSupported,
  confirmation,
  criticalError,
  customErrorWithExit,
  infoWithChainData,
  seccionTitle,
  sectionSubtitle,
  showEvvmLogo,
  warning,
} from "../../utils/outputMesages";
import { ChainData, colors } from "../../constants";
import { promptYesNo } from "../../utils/prompts";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { explorerVerification } from "../../utils/explorerVerification";
import { configurationBasic } from "../../utils/configurationInputs";
import { registerSingle } from "../register/registerSingle";

/**
 * Deploys a complete EVVM instance with interactive configuration
 *
 * Executes the full deployment workflow including:
 * 1. Prerequisite validation (Foundry installation, wallet setup)
 * 2. Interactive configuration collection (addresses, metadata) or skip with flag
 * 3. Target chain support validation (skips for local chains 31337/1337)
 * 4. Block explorer verification setup (disabled for local chains)
 * 5. Forge script deployment of all EVVM contracts
 * 6. Optional registration in EVVM Registry with custom RPC support
 *
 * Deployed contracts:
 * - Core.sol (core protocol)
 * - Staking.sol (validator staking)
 * - Estimator.sol (gas estimation)
 * - NameService.sol (domain name resolution)
 * - P2PSwap.sol (peer-to-peer token swaps)
 *
 * @param {string[]} args - Command arguments (unused, reserved for future use)
 * @param {any} options - Command options:
 *   - skipInputConfig: Skip interactive config, use BaseInputs.sol file (default: false)
 *   - walletName: Foundry wallet account name to use (default: "defaultKey")
 * @returns {Promise<void>}
 */
export async function deploySingle(args: string[], options: any) {
  // --skipInputConfig -s
  const skipInputConfig = options.skipInputConfig || false;
  // --walletName -n
  const walletName = options.walletName || "defaultKey";

  let verificationflag: string | undefined = "";

  seccionTitle("Deploy EVVM Contracts");

  await verifyFoundryInstalledAndAccountSetup([walletName]);

  if (skipInputConfig) {
    warning(
      `Skipping input configuration`,
      `  ${colors.green}✓${colors.reset} Base inputs ${colors.darkGray}→ ./input/BaseInputs.sol${colors.reset}`
    );
  } else {
    await configurationBasic();

    if (
      !(await promptYesNo(
        `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
      ))
    )
      customErrorWithExit(
        "Deployment cancelled by user",
        `${colors.darkGray}Exiting deployment process.${colors.reset}`
      );
  }

  const { rpcUrl, chainId } = await getRPCUrlAndChainId(process.env.RPC_URL);

  if (chainId === 31337 || chainId === 1337) {
    warning(
      `Local blockchain detected (Chain ID: ${chainId})`,
      `${colors.darkGray}Skipping host chain verification for local development${colors.reset}`
    );
  } else {
    if (!(await isChainIdRegistered(chainId))) chainIdNotSupported(chainId);

    verificationflag = await explorerVerification();

    if (verificationflag === undefined)
      criticalError(`Explorer verification setup failed.`);
  }

  infoWithChainData(
    `Deploying EVVM instance`,
    ChainData[chainId]?.Chain || "",
    chainId
  );

  await forgeScript(
    "script/Deploy.s.sol:DeployScript",
    rpcUrl,
    walletName,
    verificationflag ? verificationflag.split(" ") : []
  );

  confirmation(`EVVM deployed successfully!`);

  const coreAddress: `0x${string}` | null =
    await showDeployContractsAndFindEvvm(chainId);

  if (!coreAddress)
    criticalError(
      `Failed to detect deployed Core contract address. Check ./broadcast/Deploy.s.sol/${chainId}/run-latest.json`
    );

  sectionSubtitle("EVVM Registration");
  console.log(`
${colors.blue}Your EVVM instance is ready to be registered.${colors.reset}

${colors.yellow}Important:${colors.reset}
   To register now, your Admin address must match the ${walletName} wallet.
   ${colors.darkGray}Otherwise, you can register later using:${colors.reset}
   ${colors.evvmGreen}evvm register --coreAddress ${coreAddress} --walletName <walletName>${colors.reset}
Or if you want to use your custom Ethereum Sepolia RPC:
   ${colors.evvmGreen}evvm register --coreAddress ${coreAddress} --walletName <walletName> --useCustomEthRpc${colors.reset}

   ${colors.darkGray}📖 For more details, visit:${colors.reset}
   ${colors.blue}https://www.evvm.info/docs/QuickStart#6-register-in-registry-evvm${colors.reset}
`);

  if (
    !(await promptYesNo(
      `${colors.yellow}Do you want to register the EVVM instance now? (y/n):${colors.reset}`
    ))
  ) {
    customErrorWithExit(
      `Steps skipped by user choice`,
      `${colors.darkGray}You can complete setup later using the commands above.${colors.reset}`
    );
  }

  // If user decides, add --useCustomEthRpc flag to the registerEvvm call
  const ethRPCAns = await promptYesNo(
    `${colors.yellow}Use custom Ethereum Sepolia RPC for registry calls? (y/n):${colors.reset}`
  );

  await registerSingle([], {
    coreAddress: coreAddress,
    walletName: walletName,
    useCustomEthRpc: ethRPCAns,
  });
}
