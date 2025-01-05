// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";

import { AgentFactory, DeployAgentFactory } from "script/Deploy.s.sol";
import { OwnableAgent } from "src/agents/OwnableAgent.sol";

contract AgentFactoryTest is Test {
    AgentFactory public agentFactory;
    OwnableAgent ownableAgentImpl;

    function setUp() public virtual {
        agentFactory = new DeployAgentFactory().run();
        ownableAgentImpl = new OwnableAgent();
        vm.label(address(agentFactory), "AgentFactory");
        vm.label(address(ownableAgentImpl), "OwnableAgentImpl");
    }

    function _computeCommitment(address owner, address agent, bytes32 salt)
        internal
        virtual
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, agent, salt));
    }
}

contract DeployTest is AgentFactoryTest {
    function test_Create2() public virtual {
        assertGt(type(uint136).max, uint160(address(agentFactory)));
        console2.log("AgentFactory: ", address(agentFactory));
    }
}

contract FlowTest is AgentFactoryTest {
    function testFuzz_Flow(address revealer, bytes32 digest, bytes32 salt) public virtual {
        vm.startPrank(revealer);
        agentFactory.commit(_computeCommitment(revealer, address(ownableAgentImpl), salt));
        vm.warp(block.timestamp + 1 hours);
        OwnableAgent agent =
            OwnableAgent(agentFactory.reveal(address(ownableAgentImpl), salt, abi.encode(revealer)));

        assertEq(agent.owner(), revealer);
        assertEq(bytes4(0xFFFFFFFF), agent.isValidSignature(digest, ""));
        agent.validateDigest(digest, true);
        assertEq(bytes4(0x1626ba7e), agent.isValidSignature(digest, ""));
    }
}
