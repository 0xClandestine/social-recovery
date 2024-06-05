// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";

import { RecoveryManager } from "./../src/RecoveryManager.sol";
import { SingleUseAgent } from "./../src/SingleUseAgent.sol";

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

    function recoveryManagerInitCodeHash() internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(RecoveryManager).creationCode));
    }

    function singleUseAgentInitCodeHash() internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(SingleUseAgent).creationCode));
    }

    function run()
        public
        virtual
        returns (RecoveryManager m, SingleUseAgent a)
    {
        vm.startBroadcast();
        m = new RecoveryManager{
            salt: computeSalt(recoveryManagerInitCodeHash())
        }();
        a = new SingleUseAgent{ salt: computeSalt(singleUseAgentInitCodeHash()) }(
        );
        vm.stopBroadcast();
    }
}
