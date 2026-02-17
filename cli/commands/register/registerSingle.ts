/**
 * Single-Chain EVVM Registration Command
 *
 * Handles registration of single-chain EVVM deployments in the EVVM Registry
 * contract on Ethereum Sepolia. Generates a unique EVVM ID and updates the
 * deployed contract with its assigned identifier.
 *
 * @module cli/commands/register/registerSingle
 */

import {
  chainIdNotSupported,
  confirmation,
  criticalError,
  infoWithChainData,
  seccionTitle,
  sectionSubtitle,
  warning,
} from "../../utils/outputMesages";
import {
  callRegisterEvvm,
  callSetEvvmID,
  isChainIdRegistered,
  verifyFoundryInstalledAndAccountSetup,
} from "../../utils/foundry";
import { ChainData, colors, EthSepoliaPublicRpc } from "../../constants";
import { promptAddress, promptString } from "../../utils/prompts";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { saveEvvmRegistrationToJson } from "../../utils/outputJson";

/**
 * Registers a single-chain EVVM instance in the EVVM Registry
 *
 * This command interacts with the EVVM Registry contract on Ethereum Sepolia
 * to obtain a globally unique EVVM ID, then updates the deployed Core contract
 * with this identifier. The registry maintains a canonical list of all EVVM
 * instances across supported chains.
 *
 * Process:
 * 1. Validates Foundry installation and wallet setup
 * 2. Prompts for Core contract address if not provided
 * 3. Validates host chain is supported (skips for local chains 31337/1337)
 * 4. Calls EVVM Registry on Ethereum Sepolia to generate EVVM ID
 * 5. Updates Core contract with assigned ID via setEvvmID()
 *
 * @param {string[]} _args - Command arguments (unused, reserved for future use)
 * @param {any} options - Command options:
 *   - coreAddress: Address of deployed Core contract
 *   - walletName: Foundry wallet account name (default: "defaultKey")
 *   - useCustomEthRpc: Use custom Ethereum Sepolia RPC instead of public (default: false)
 * @returns {Promise<void>}
 */
export async function registerSingle(_args: string[], options: any) {
  console.log(`${colors.bright}Starting EVVM registration...${colors.reset}\n`);

  // Get values from optional flags
  let coreAddress: `0x${string}` | undefined = options.coreAddress;
  let walletName: string = options.walletName || "defaultKey";
  let useCustomEthRpc: boolean = options.useCustomEthRpc || false;

  let ethRPC: string | undefined;

  seccionTitle("Register EVVM in Registry");

  await verifyFoundryInstalledAndAccountSetup([walletName]);

  // If --useCustomEthRpc is present, look for EVVM_REGISTRATION_RPC_URL in .env or prompt user
  ethRPC = useCustomEthRpc
    ? process.env.EVVM_REGISTRATION_RPC_URL ||
      (await promptString(
        `${colors.yellow}Enter the custom Ethereum Sepolia RPC URL:${colors.reset}`
      ))
    : EthSepoliaPublicRpc;

  // Validate or prompt for missing values
  coreAddress ||= await promptAddress(
    `${colors.yellow}Enter the Core Address:${colors.reset}`
  );

  let { rpcUrl, chainId } = await getRPCUrlAndChainId(process.env.RPC_URL);

  if (chainId === 31337 || chainId === 1337) {
    warning("Local blockchain detected", "Skipping registry registration");
    return;
  }

  if (!(await isChainIdRegistered(chainId))) chainIdNotSupported(chainId);

  sectionSubtitle("Registering EVVM and Obtaining EVVM ID on Ethereum Sepolia");

  const evvmID: number | undefined = await callRegisterEvvm(
    Number(chainId),
    coreAddress,
    walletName,
    ethRPC
  );

  if (!evvmID) {
    criticalError(`Failed to obtain EVVM ID for contract ${coreAddress}.`);
  }

  confirmation(`Generated EVVM ID: ${colors.bright}${evvmID}${colors.reset}`);

  infoWithChainData(
    `Setting EVVM ID on Core contract`,
    ChainData[chainId]?.Chain || "",
    chainId
  );

  await callSetEvvmID(coreAddress, evvmID!, rpcUrl, walletName);

  await saveEvvmRegistrationToJson(
    Number(evvmID),
    coreAddress,
    chainId,
    ChainData[chainId]?.Chain
  );

  confirmation(`EVVM registration completed successfully!`);

  sectionSubtitle("Registration Summary");
  console.log(
    `${colors.green}EVVM ID: ${colors.bright}${evvmID}${colors.reset}`
  );
  console.log(
    `${colors.green}Core Address: ${colors.bright}${coreAddress}${colors.reset}`
  );
  console.log(
    `${colors.darkGray}\nYour EVVM instance is now ready to use!${colors.reset}\n`
  );
}
