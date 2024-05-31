// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import { Test, console2 } from "forge-std/Test.sol";
import { DeployCounter, Counter } from "../script/Counter.s.sol";

contract CounterTest is Test {
    event NumberSet(uint256 indexed newNumber);

    uint256 public constant initialNumber = 420;

    Counter public counter;

    function setUp() public virtual {
        counter = new DeployCounter().run(initialNumber);
        vm.label(address(counter), "Counter");
    }
}

contract DeployTest is CounterTest {
    function test_Create2() public virtual {
        // Assert `Counter` address has at least 6 leading zeros.
        assertGt(type(uint136).max, uint160(address(counter)));
        assertEq(counter.number(), initialNumber);
        console2.log("Counter: ", address(counter));
    }
}

contract SetNumberTest is CounterTest {
    function testFuzz_SetNumber(uint256 x) public virtual {
        vm.expectEmit(true, true, false, false);
        emit NumberSet(x);
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}

contract IncrementTest is CounterTest {
    function test_Increment() public virtual {
        uint256 expected = initialNumber + 1;
        vm.expectEmit(true, true, false, false);
        emit NumberSet(expected);
        counter.increment();
        assertEq(counter.number(), expected);
    }

    function test_IncrementOverflow() public virtual {
        counter.setNumber(type(uint256).max);
        vm.expectRevert(Counter.IncrementOverflow.selector);
        counter.increment();
    }
}

contract FallbackTest is CounterTest {
    function testFuzz_SetNumber(uint256 newNumber) public virtual {
        vm.expectEmit(true, true, false, false);
        emit NumberSet(newNumber);
        (bool s, bytes memory r) = address(counter).call(abi.encodePacked(newNumber));
        assertEq(counter.number(), newNumber);
        (s, r) = (s, r); // Silence compiler warnings...
    }

    function test_Increment() public virtual {
        uint256 expected = initialNumber + 1;
        vm.expectEmit(true, true, false, false);
        emit NumberSet(expected);
        (bool s, bytes memory r) = address(counter).call("");
        assertEq(counter.number(), expected);
        (s, r) = (s, r); // Silence compiler warnings...
    }
}
