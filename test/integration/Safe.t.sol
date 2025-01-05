// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { LibClone } from "solady/utils/LibClone.sol";

import { AgentFactoryTest, OwnableAgent } from "test/AgentFactory.t.sol";
import { OwnerManager, Safe, SimpleSafeLib } from "test/utils/SimpleSafeLib.sol";

contract SafeIntegrationTest is AgentFactoryTest {
    using SimpleSafeLib for Safe;

    Safe safe;

    function setUp() public virtual override {
        AgentFactoryTest.setUp();
        safe = Safe(payable(LibClone.clone(address(new Safe()))));
        vm.label(address(safe), "Safe");
    }

    function testFuzz_Flow(address oldOwner, address newOwner, bytes32 salt) public virtual {
        // Given a list of owners, including the counterfactual address of a recovery agent,
        // the user sets up a new Gnosis Safe.
        address[] memory owners = new address[](2);
        owners[0] = oldOwner;
        owners[1] = LibClone.predictDeterministicAddress(
            address(ownableAgentImpl), salt, address(agentFactory)
        );

        // Set up the Gnosis Safe with the specified owners and a single-signature threshold.
        safe.setup({ owners: owners, threshold: 1 });

        // Imagine the private key of the first owner (`owners[0]`) is lost or compromised...
        vm.startPrank(newOwner);

        // As the affected user, I want to commit to deploying a recovery agent using another
        // private key.
        agentFactory.commit(_computeCommitment(newOwner, address(ownableAgentImpl), salt));

        // As a user, I wait for the commitment period to elapse to ensure the integrity of the
        // recovery process.
        vm.warp(block.timestamp + 1 hours);

        // As a user, I reveal the recovery agent, completing its deployment.
        OwnableAgent agent =
            OwnableAgent(agentFactory.reveal(address(ownableAgentImpl), salt, abi.encode(newOwner)));
        assertEq(address(agent), owners[1], "sanity check");

        // As a user, I want to replace the compromised owner with a new owner by using the recovery
        // agent's validated signature.
        bytes memory data =
            abi.encodeWithSelector(OwnerManager.swapOwner.selector, address(1), oldOwner, newOwner);

        // As a user, I validate the signature of the data for owner replacement using the recovery
        // agent.
        agent.validateDigest(
            keccak256(safe.getSignableData({ to: address(safe), value: 0, data: data, nonce: 0 })),
            true
        );

        // As a user, I execute the call on the Safe contract to swap the owner.
        safe.executeCall({
            to: address(safe),
            value: 0,
            data: data,
            signatures: safe.getContractSignature(address(agent))
        });

        assertEq(safe.getOwners().length, 2, "sanity check");

        // Verify that the ownership swap has been completed successfully.
        assertTrue(!safe.isOwner(oldOwner), "old owner not removed");
        assertTrue(safe.isOwner(newOwner), "new owner not added");
    }
}
