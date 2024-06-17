// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseSetup } from "lib/chimera/src/BaseSetup.sol";
import { vm } from "lib/chimera/src/Hevm.sol";
import { PublicMarketHarness } from "src/Harness/PublicMarketHarness.sol";
import { MockERC20 } from "src/Mocks/MockERC20.sol";
import {ERC1967Proxy} from "lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IPublicMarketHarness} from "src/Interfaces/IPublicMarketHarness.sol";


abstract contract Setup is BaseSetup {

  PublicMarketHarness public imp;
  address internal _imp;

  ERC1967Proxy public proxy;
  address internal _proxy;

  IPublicMarketHarness public target;
  address internal _target;

  MockERC20 internal weth;
  MockERC20 internal wbtc;

  address internal _weth;
  address internal _wbtc;

  address internal _admin = address(0x50000);

  address internal _alice = address(0x10000);
  address internal _bob = address(0x20000);

  address internal _turnstile = 0xEcf044C5B4b867CFda001101c617eCd347095B44;

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

    vm.prank(_admin);
    imp = new PublicMarketHarness();
    _imp = address(imp);

    bytes memory initData = abi.encodeWithSignature("__PublicMarket_init(address,address,address)", _admin, _admin, _turnstile);
    vm.prank(_admin);
    proxy = new ERC1967Proxy(_imp, initData);
    _proxy = address(proxy);

    target = IPublicMarketHarness(_proxy);
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
