// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

/// @title Counter Contract
/// @notice This contract provides functionality for counting numbers.
contract Counter {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Incrementation has overflowed.
    error IncrementOverflow(); //  0xd2727d54

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EVENTS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `number` is mutated to `newNumber`.
    event NumberSet(uint256 indexed newNumber);

    /// @dev `keccak256(bytes("NumberSet(uint256)"))`.
    uint256 private constant _NUMBER_SET_EVENT_SIGNATURE =
        0x9ec8254969d1974eac8c74afb0c03595b4ffe0a1d7ad8a7f82ed31b9c8542591;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Returns the current value of the number.
    /// @return n The current value of the number.
    function number() public view virtual returns (uint256 n) {
        /// @solidity memory-safe-assembly
        assembly {
            n := sload(address())
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(uint256 initialNumber) {
        _setNumber(initialNumber);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ACTIONS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sets the value of `number` to a new value.
    function _setNumber(uint256 newNumber) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Mutate `number` in storage.
            sstore(address(), newNumber)
            // Emit `NumberSet` event.
            log2(0x00, 0x20, _NUMBER_SET_EVENT_SIGNATURE, newNumber)
        }
    }

    /// @dev Increments the value of `number` by 1.
    function _increment() internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache free memory pointer.
            let m := mload(0x40)
            // Cache incremented `number` in memory.
            mstore(m, add(sload(address()), 1))
            // Check for addition overflow.
            if iszero(mload(m)) {
                mstore(0x00, 0xd2727d54) // `IncrementOverflow()`.
                revert(0x1c, 0x04)
            }
            // Mutate `number` in storage.
            sstore(address(), mload(m))
            // Emit `NumberSet` event.
            log2(0x00, 0x20, _NUMBER_SET_EVENT_SIGNATURE, mload(m))
        }
    }

    /// @notice Sets the value of `number` to a new value.
    /// @dev Emits a `NumberSet` event.
    /// @param newNumber The new value to set `number` to.
    function setNumber(uint256 newNumber) public virtual {
        _setNumber(newNumber);
    }

    /// @notice Increments the value of `number` by 1.
    /// @dev Emits a `NumberSet` event.
    function increment() public virtual {
        _increment();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          FALLBACK                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Sets the value of `number` to the first 32 bytes of
    /// calldata if calldata is non-zero, otherwise it increments the
    /// value of `number` by 1.
    /// @dev Emits a `NumberSet` event.
    fallback() external virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if calldatasize() {
                // Load `newNumber` from the first 32 bytes of calldata.
                let newNumber := calldataload(0x00)
                // Mutate `number` in storage.
                sstore(address(), newNumber)
                // Emit `NumberSet` event.
                log2(0x00, 0x20, _NUMBER_SET_EVENT_SIGNATURE, newNumber)
                // Return.
                return(0x00, 0x00)
            }
        }
        _increment();
    }
}
