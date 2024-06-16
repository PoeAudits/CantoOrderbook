// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Math } from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

abstract contract Utils {
  using Math for uint256;

  uint256 internal constant SCALE_FACTOR = 1e27;

  function utilBuyToPrice(uint256 pay_amount, uint256 buy_amount) internal pure returns (uint256) {
    return buy_amount.mulDiv(SCALE_FACTOR, pay_amount);
  }

  function utilPriceToBuy(uint256 price, uint256 pay_amount) internal pure returns (uint256) {
    return price.mulDiv(pay_amount, SCALE_FACTOR);
  }

  function utilReversePrice(uint256 price) internal pure returns (uint256) {
    return SCALE_FACTOR.mulDiv(SCALE_FACTOR, price);
  }

  function seedRandom(uint256 r) internal pure returns (uint256) {
    return uint256(
      keccak256(abi.encode(uint256(keccak256(abi.encode(r))) - 1)) & ~bytes32(uint256(0xff))
    );
  }
  /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
  /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
  /// e.g. `testSomething(uint256) public`.
  /// @dev From Solady

  function _random() internal returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
      // This is the keccak256 of a very long string I randomly mashed on my keyboard.
      let sSlot := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
      let sValue := sload(sSlot)

      mstore(0x20, sValue)
      r := keccak256(0x20, 0x40)

      // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
      if iszero(sValue) {
        sValue := sSlot
        let m := mload(0x40)
        calldatacopy(m, 0, calldatasize())
        r := keccak256(m, calldatasize())
      }
      sstore(sSlot, add(r, 1))

      // Do some biased sampling for more robust tests.
      // prettier-ignore
      for { } 1 { } {
        let d := byte(0, r)
        // With a 1/256 chance, randomly set `r` to any of 0,1,2.
        if iszero(d) {
          r := and(r, 3)
          break
        }
        // With a 1/2 chance, set `r` to near a random power of 2.
        if iszero(and(2, d)) {
          // Set `t` either `not(0)` or `xor(sValue, r)`.
          let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
          // Set `r` to `t` shifted left or right by a random multiple of 8.
          switch and(8, d)
          case 0 {
            if iszero(and(16, d)) { t := 1 }
            r := add(shl(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
          }
          default {
            if iszero(and(16, d)) { t := shl(255, 1) }
            r := add(shr(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
          }
          // With a 1/2 chance, negate `r`.
          if iszero(and(0x20, d)) { r := not(r) }
          break
        }
        // Otherwise, just set `r` to `xor(sValue, r)`.
        r := xor(sValue, r)
        break
      }
    }
  }
}
