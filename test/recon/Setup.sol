// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
// import "src/Factory.sol";
import "src/Harness/PublicMarketHarness.sol";

abstract contract Setup is BaseSetup {
  PublicMarketHarness public target;

  function setup() internal virtual override {
    target = new PublicMarketHarness();
  }
  // Factory public factory;
  // Singleton public target;

  // OrderModule public orderModule;
  // MatchingModule public matchingModule;

  // function setup() internal virtual override {
  //  factory = new Factory();
  //  (target, orderModule, matchingModule) = factory.getContracts();
  // }
}
