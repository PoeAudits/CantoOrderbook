// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe integer casting library that reverts on overflow.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
/// @dev Reduced library to include only needed conversions
library SoladySafeCastLib {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       CUSTOM ERRORS                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  error Overflow();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*          UNSIGNED INTEGER SAFE CASTING OPERATIONS          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function toUint48(uint256 x) internal pure returns (uint48) {
    if (x >= 1 << 48) _revertOverflow();
    return uint40(x);
  }

  function toUint96(uint256 x) internal pure returns (uint96) {
    if (x >= 1 << 96) _revertOverflow();
    return uint96(x);
  }

  function toUint128(uint256 x) internal pure returns (uint128) {
    if (x >= 1 << 128) _revertOverflow();
    return uint128(x);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                      PRIVATE HELPERS                       */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function _revertOverflow() private pure {
    /// @solidity memory-safe-assembly
    assembly {
      // Store the function selector of `Overflow()`.
      mstore(0x00, 0x35278d12)
      // Revert with (offset, size).
      revert(0x1c, 0x04)
    }
  }
}
