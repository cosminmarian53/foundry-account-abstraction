// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public {
        // Setup
        HelperConfig helperConfig = new HelperConfig();
        address dest = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // Arbitrum mainnet USDC address
        uint256 value = 0;

        bytes memory functionData = abi.encodeWithSelector(
            IERC20.approve.selector,
            0x9EA9b0cc1919def1A3CfAEF4F7A66eE3c36F86fC,
            1e18
        );

        bytes memory executeCalldata = abi.encodeWithSelector(
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );

        PackedUserOperation memory userOp = generateSignedUserOperation(
            executeCalldata,
            helperConfig.getConfig(),
            0x03Ad95a54f02A40180D45D76789C448024145aaF
        );
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        // Send transaction
        vm.startBroadcast();
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            ops,
            payable(helperConfig.getConfig().account)
        );
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config,
        address minimalAccount
    )
        public
        returns (PackedUserOperation memory)
    {
        uint256 nonce = vm.getNonce(minimalAccount)-1;
        // Step 1. Generate the unsigned data
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);
        // Step 2. Sign and return it
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();
        // Step 3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); //!!IMPORTANT:This is the correct order
        // Step 4. Return the signed user operation
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        // Step 1. Generate the unsigned data
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | uint256(callGasLimit)),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32((uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
