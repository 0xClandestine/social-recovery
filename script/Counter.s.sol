// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { Counter } from "../src/Counter.sol";

contract DeployCounter is Script {
    function computeSalt(bytes32 initCodeHash) internal virtual returns (bytes32 salt) {
        string[] memory ffi = new string[](3);
        ffi[0] = "bash";
        ffi[1] = "create2.sh";
        ffi[2] = vm.toString(initCodeHash);
        vm.ffi(ffi);
        salt = vm.parseBytes32(vm.readLine(".temp"));
        try vm.removeFile(".temp") { } catch { }
    }

    function counterInitCodeHash(uint256 initialNumber) internal virtual returns (bytes32) {
        return keccak256(abi.encodePacked(type(Counter).creationCode, abi.encode(initialNumber)));
    }

    function run(uint256 initialNumber) public virtual returns (Counter counter) {
        vm.startBroadcast();
        counter =
            new Counter{ salt: computeSalt(counterInitCodeHash(initialNumber)) }(initialNumber);
        vm.stopBroadcast();
    }

    function run() public virtual returns (Counter counter) {
        return run(vm.envUint("INITIAL_NUMBER"));
    }
}
