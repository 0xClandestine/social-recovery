// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "script/Deploy.s.sol";
import "social-recovery/agents/OwnableAgent.sol";

contract AgentDeployerTest is Test {
    AgentDeployer public agentDeployer;
    OwnableAgent public ownableAgentImpl;

    function setUp() public virtual {
        agentDeployer = new Deploy().run();
        ownableAgentImpl = new OwnableAgent();
        vm.label(address(agentDeployer), "AgentDeployer");
        vm.label(address(ownableAgentImpl), "OwnableAgentImpl");
    }
}

contract DeployTest is AgentDeployerTest {
    function test_Create2() public virtual {
        assertGt(type(uint136).max, uint160(address(agentDeployer)));
        console2.log("AgentDeployer: ", address(agentDeployer));
    }
}

contract FlowTest is AgentDeployerTest {
    function testFuzz_Flow(address revealer, bytes32 digest, bytes32 salt) public virtual {
        bytes32 commitment = keccak256(abi.encodePacked(revealer, address(ownableAgentImpl), salt));

        vm.startPrank(revealer);
        agentDeployer.commit(commitment);
        vm.warp(block.timestamp + 1);
        OwnableAgent agent = OwnableAgent(
            agentDeployer.reveal(address(ownableAgentImpl), salt, abi.encode(revealer))
        );

        assertEq(agent.owner(), revealer);
        assertEq(bytes4(0xFFFFFFFF), agent.isValidSignature(digest, ""));

        agent.validateDigest(digest, true);

        assertEq(bytes4(0x1626ba7e), agent.isValidSignature(digest, ""));
    }
}
