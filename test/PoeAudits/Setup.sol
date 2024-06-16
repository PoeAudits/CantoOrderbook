// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
import { vm } from "lib/chimera/src/Hevm.sol";
import { PublicMarketHarness } from "src/Harness/PublicMarketHarness.sol";
import { MockERC20 } from "src/Mocks/MockERC20.sol";

abstract contract Setup is BaseSetup {
  PublicMarketHarness public target;
  address internal _target;

  MockERC20 internal weth;
  MockERC20 internal wbtc;

  address internal _weth;
  address internal _wbtc;

  address internal _alice = address(0x10000);
  address internal _bob = address(0x20000);

  MockERC20[] internal tokens;
  address[] internal _tokens;
  address[] internal users;

  function setup() internal virtual override {
    weth = new MockERC20(18);
    wbtc = new MockERC20(18);

    _weth = address(weth);
    _wbtc = address(wbtc);

    tokens.push(weth);
    tokens.push(wbtc);

    _tokens.push(_weth);
    _tokens.push(_wbtc);

    users.push(_alice);
    users.push(_bob);

    target = new PublicMarketHarness();
    _target = address(target);

    for (uint256 i; i < users.length; ++i) {
      for (uint256 j; j < tokens.length; ++j) {
        vm.prank(users[i]);
        tokens[j].mint(type(uint128).max);
        vm.prank(users[i]);
        tokens[j].approve(_target, type(uint128).max);
      }
    }
  }
}
