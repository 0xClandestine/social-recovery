// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";

import { AgentFactory } from "src/AgentFactory.sol";

contract DeployAgentFactory is Script {
    function computeSalt(bytes32 initCodeHash) internal virtual returns (bytes32 salt) {
        string[] memory ffi = new string[](3);
        ffi[0] = "bash";
        ffi[1] = "create2.sh";
        ffi[2] = vm.toString(initCodeHash);
        vm.ffi(ffi);
        salt = vm.parseBytes32(vm.readLine(".temp"));
        try vm.removeFile(".temp") { } catch { }
    }

    function agentDeployerInitCodeHash() internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(AgentFactory).creationCode));
    }

    function run() public virtual returns (AgentFactory d) {
        vm.startBroadcast();
        d = new AgentFactory{ salt: computeSalt(agentDeployerInitCodeHash()) }();
        vm.stopBroadcast();
    }
}
