// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "social-recovery/AgentDeployer.sol";

contract Deploy is Script {
    function computeSalt(bytes32 initCodeHash)
        internal
        virtual
        returns (bytes32 salt)
    {
        string[] memory ffi = new string[](3);
        ffi[0] = "bash";
        ffi[1] = "create2.sh";
        ffi[2] = vm.toString(initCodeHash);
        vm.ffi(ffi);
        salt = vm.parseBytes32(vm.readLine(".temp"));
        try vm.removeFile(".temp") { } catch { }
    }

    function agentDeployerInitCodeHash() internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(AgentDeployer).creationCode));
    }

    function run() public virtual returns (AgentDeployer d) {
        vm.startBroadcast();
        d = new AgentDeployer{ salt: computeSalt(agentDeployerInitCodeHash()) }(
        );
        vm.stopBroadcast();
    }
}
