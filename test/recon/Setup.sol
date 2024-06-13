// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
import "src/Harness/PublicMarketHarness.sol";
import {MockERC20} from "src/Mocks/MockERC20.sol";
import {Actor} from "test/recon/Actor.sol";
import "test/recon/Structs.sol";

abstract contract Setup is BaseSetup {
  PublicMarketHarness internal target;

  address internal _target;

  MockERC20 internal tokenOne;
  MockERC20 internal tokenTwo;
  MockERC20 internal tokenThree;

  Actor internal alice;
  Actor internal bob;
  Actor internal carl;

  address internal _alice;
  address internal _bob;
  address internal _carl;

  address[] internal tokens;
  address[] internal users;

  function setup() internal virtual override {
    tokenOne = new MockERC20(18);
    tokenTwo = new MockERC20(18);
    tokenThree = new MockERC20(9);

    tokens[0] = address(tokenOne);
    tokens[1] = address(tokenTwo);
    tokens[2] = address(tokenThree);

    target = new PublicMarketHarness();
    _target = address(target);

    alice = new Actor(_target, tokens[0], tokens[1], tokens[2]);
    bob = new Actor(_target, tokens[0], tokens[1], tokens[2]);
    carl = new Actor(_target, tokens[0], tokens[1], tokens[2]);

    _alice = address(alice);
    _bob = address(bob);
    _carl = address(carl);
    
    users[0] = alice;
    users[1] = bob;
    users[2] = carl;

  }


}
