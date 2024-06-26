// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Asserts } from "lib/chimera/src/Asserts.sol";
// import { Setup } from "./Setup.sol";
import { BeforeAfter } from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts {
// example property test that gets run after each call in sequence
// function invariant_always_pass() public pure returns (bool) {
//   return (1 == 1);
// }
}
