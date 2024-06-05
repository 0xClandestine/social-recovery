// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { Deploy, RecoveryManager, SingleUseAgent } from "../script/Deploy.s.sol";

contract RecoveryManagerTest is Test {
    RecoveryManager public m;
    SingleUseAgent public a;

    function setUp() public virtual {
        (m, a) = new Deploy().run();
        vm.label(address(m), "RecoveryManager");
        vm.label(address(a), "SingleUseAgent");
    }
}

contract DeployTest is RecoveryManagerTest {
    function test_Create2() public virtual {
        assertGt(type(uint136).max, uint160(address(m)));
        assertGt(type(uint136).max, uint160(address(a)));

        console2.log("RecoveryManager: ", address(m));
        console2.log("SingleUseAgent: ", address(a));
    }
}

contract FlowTest is RecoveryManagerTest {
    function test_Flow() public virtual {
        // The account to recover.
        address account = 0xC5D2460186F7233C927e7db2dcC703C0E500b653;
        // The recovery digest to sign.
        bytes32 digest =
            0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
        // The length of time after a reveal before the signature is valid.
        uint256 timelock = 30 days;
        // A random value used for obfuscating the inputs needed to reveal a
        // recovery agent.
        bytes32 salt = keccak256("correct-horse-battery-stable");

        bytes memory initializationArgs = abi.encodePacked(digest, timelock);
        bytes memory immutableArgs = abi.encodePacked(account);

        bytes32 commitment = m.computeCommitmentHash(
            address(a), account, initializationArgs, immutableArgs, salt
        );

        m.commit(commitment);

        vm.expectRevert();
        m.reveal(address(a), account, initializationArgs, immutableArgs, salt);

        vm.warp(block.timestamp + 1 days + 1);
        SingleUseAgent agent = SingleUseAgent(
            m.reveal(
                address(a), account, initializationArgs, immutableArgs, salt
            )
        );

        assertEq(agent.expectedAccount(), account);
        assertEq(agent.expectedDigest(), digest);
        assertEq(agent.timelockMaturity(), block.timestamp + timelock);

        assertEq(bytes4(0xFFFFFFFF), agent.isValidSignature(digest, ""));

        vm.startPrank(account);
        assertEq(bytes4(0xFFFFFFFF), agent.isValidSignature(digest, ""));

        vm.warp(agent.timelockMaturity() + 1);
        assertEq(bytes4(0x1626ba7e), agent.isValidSignature(digest, ""));
    }
}
