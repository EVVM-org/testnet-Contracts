/**
 * EVVM Registration Command Dispatcher
 *
 * Routes registration requests to either single-chain or cross-chain
 * registration workflows based on the --crossChain flag.
 *
 * @module cli/commands/register
 */

import { registerSingle } from "./registerSingle";
import { registerCross } from "./registerCross";

/**
 * Routes registration command to appropriate workflow
 *
 * Determines whether to execute a single-chain registration (registerSingle)
 * or a cross-chain registration (registerCross) based on the --crossChain flag.
 *
 * Single-chain registration: Registers Core contract only
 * Cross-chain registration: Registers Core and external treasury station
 *
 * @param {string[]} args - Command-line arguments passed to registration
 * @param {any} options - Command options including:
 *   - crossChain: Boolean flag to enable cross-chain mode
 *   - coreAddress: Address of deployed Core contract
 *   - treasuryExternalStationAddress: Address of external station (cross-chain only)
 *   - walletName/walletNameHost/walletNameExternal: Wallet accounts
 *   - useCustomEthRpc: Use custom Ethereum Sepolia RPC for registry
 * @returns {Promise<void>}
 */
export async function register(args: string[], options: any) {
  return options.crossChain || false
    ? registerCross(args, options)
    : registerSingle(args, options);
}
