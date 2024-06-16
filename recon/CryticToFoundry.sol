// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { TargetFunctions } from "./TargetFunctions.sol";
import { Test, console2 as console } from "forge-std/Test.sol";

import "forge-std/console2.sol";
import { FoundryAsserts } from "lib/chimera/src/FoundryAsserts.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
  function setUp() public {
    setup();
    targetContract(address(target));
  }

  // function test_harness_record_order() public {
  //   vm.startPrank(_alice);
  //   harness_record_order(1e18, 1.5e18, 128_973);
  //   vm.stopPrank();
  // }

  // function test_harness_process_buy(uint96 val, uint96 val2) public {
  //   vm.assume(val != 0 && val < type(uint96).max / 2);
  //   vm.assume(val2 != 0 && val2 < type(uint96).max / 2);
  //   harness_process_buy(val, val2, uint256(val / 2));
  // }

  // function test_fuzz_market_buy() public {
  //   sender = _alice;
  //   fuzz_market_buy(5);
  // }
}
