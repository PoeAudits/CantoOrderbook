// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
import "src/Harness/PublicMarketHarness.sol";
import { MockERC20 } from "src/Mocks/MockERC20.sol";

import "lib/chimera/src/Hevm.sol";

// import { Actor } from "test/recon/Actor.sol";

abstract contract Setup is BaseSetup {
  PublicMarketHarness internal target;

  address internal _target;

  MockERC20 internal tokenOne;
  MockERC20 internal tokenTwo;
  MockERC20 internal tokenThree;

  address internal _tokenOne;
  address internal _tokenTwo;
  address internal _tokenThree;

  // Actor internal alice;
  // Actor internal bob;
  // Actor internal carl;

  address internal _admin = address(0x40000);

  address internal _alice;
  address internal _bob;
  address internal _carl;

  address[] internal tokens;
  address[] internal users;

  function setup() internal virtual override {
    tokenOne = new MockERC20(18);
    tokenTwo = new MockERC20(18);
    tokenThree = new MockERC20(9);

    _tokenOne = address(tokenOne);
    _tokenTwo = address(tokenTwo);
    _tokenThree = address(tokenThree);

    tokens.push(_tokenOne);
    tokens.push(_tokenTwo);
    tokens.push(_tokenThree);

    target = new PublicMarketHarness();
    _target = address(target);

    // alice = new Actor(_target, tokens[0], tokens[1], tokens[2]);
    // bob = new Actor(_target, tokens[0], tokens[1], tokens[2]);
    // carl = new Actor(_target, tokens[0], tokens[1], tokens[2]);

    _alice = address(0x10000);
    _bob = address(0x20000);
    _carl = address(0x30000);

    users.push(_alice);
    users.push(_bob);
    users.push(_carl);

    for (uint256 i; i < users.length; ++i) {
      fundUser(users[i]);
    }
  }

  function fundUser(address user) internal {
    vm.prank(user);
    tokenOne.mint(type(uint96).max);
    vm.prank(user);
    tokenTwo.mint(type(uint96).max);
    vm.prank(user);
    tokenThree.mint(type(uint96).max);

    vm.prank(user);
    tokenOne.approve(_target, type(uint96).max);
    vm.prank(user);
    tokenTwo.approve(_target, type(uint96).max);
    vm.prank(user);
    tokenThree.approve(_target, type(uint96).max);
  }

  function checkInputs(address checkOne, address checkTwo) internal view returns (address, address) {
    if (
      (checkOne == _tokenOne || checkOne == _tokenTwo || checkOne == _tokenThree)
        && (checkTwo == _tokenOne || checkTwo == _tokenTwo || checkTwo == _tokenThree)
    ) {
      return (checkOne, checkTwo);
    } else {
      return pickTokenPair(checkOne, checkTwo);
    }
  }

  function pickTokenPair(address randOne, address randTwo) internal view returns (address, address) {
    uint256 rand = uint256(keccak256(abi.encode((uint160(randOne) + uint160(randTwo))))) + 1;
    uint256 modulo = 6;
    if (rand % modulo == 0) {
      return (_tokenOne, _tokenTwo);
    } else if (rand % modulo == 1) {
      return (_tokenOne, _tokenThree);
    } else if (rand % modulo == 2) {
      return (_tokenTwo, _tokenOne);
    } else if (rand % modulo == 3) {
      return (_tokenThree, _tokenOne);
    } else if (rand % modulo == 4) {
      return (_tokenTwo, _tokenThree);
    } else if (rand % modulo == 5) {
      return (_tokenThree, _tokenTwo);
    }
  }

  function pickTokenPair(uint256 rand) internal view returns (address, address) {
    rand = uint256(keccak256(abi.encode(((rand / 3) + 3))));
    uint256 modulo = 6;
    if (rand % modulo == 0) {
      return (_tokenOne, _tokenTwo);
    } else if (rand % modulo == 1) {
      return (_tokenOne, _tokenThree);
    } else if (rand % modulo == 2) {
      return (_tokenTwo, _tokenOne);
    } else if (rand % modulo == 3) {
      return (_tokenThree, _tokenOne);
    } else if (rand % modulo == 4) {
      return (_tokenTwo, _tokenThree);
    } else if (rand % modulo == 5) {
      return (_tokenThree, _tokenTwo);
    }
  }

  function pickAddress(uint256 rand) internal view returns (address, address) {
    rand = uint256(keccak256(abi.encode((rand / 2) + 2)));
    uint256 modulo = 6;
    if (rand % modulo == 0) {
      return (_alice, _bob);
    } else if (rand % modulo == 1) {
      return (_alice, _carl);
    } else if (rand % modulo == 2) {
      return (_bob, _alice);
    } else if (rand % modulo == 3) {
      return (_bob, _carl);
    } else if (rand % modulo == 4) {
      return (_carl, _alice);
    } else if (rand % modulo == 5) {
      return (_carl, _bob);
    }
  }

  /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
  /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
  /// e.g. `testSomething(uint256) public`.
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
