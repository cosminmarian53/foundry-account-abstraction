// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SendPackedUserOp is Script {
    function run() public {}

    function generateSignedUserOperation(
        bytes memory callData,
        address sender,
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = vm.getNonce(sender);
        // Step 1. Generate the unsigned data
        PackedUserOperation memory unsignedUserOp = _generateUnsignedUserOperation(callData, sender, nonce);
        // Step 2. Sign and return it
    }

    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    ) internal returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        // Step 1. Generate the unsigned data
        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) |
                        uint256(callGasLimit)
                ),
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ),
                paymasterAndData: hex"",
                signature: hex""
            });
    }
}
