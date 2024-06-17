// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Setup } from "./Setup.sol";
import { OrdersLib } from "src/Libraries/OrdersLib.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
  using OrdersLib for OrdersLib.Order;

  struct Vars {
    uint256[2] makerBalances;
    uint256[2] takerBalances;
    uint256[2][2] targetBalances; // [Token][User]
    uint256 marketMinPrice;
    uint256 makerOrderSize;
    uint256 takerOrderSize;
  }

  Vars internal _before;
  Vars internal _after;
  bool showLogs = false;
  address internal maker = _alice;
  address internal taker = _bob;

  modifier getMaker() virtual {
    maker = msg.sender;
    _;
  }

  // _before.placeholder = target.placeholder();
  function __before() internal {
    for (uint256 i; i < tokens.length; ++i) {
      _before.makerBalances[i] = tokens[i].balanceOf(maker);
      _before.takerBalances[i] = tokens[i].balanceOf(taker);
      for (uint256 j; j < users.length; ++j) {
        _before.targetBalances[i][j] = target.userBalances(users[j], _tokens[i]);
      }
    }
    _before.makerOrderSize = target.GetUserOrdersSize(maker);
    _before.takerOrderSize = target.GetUserOrdersSize(taker);

  }

  function __before(address tokenOne, address tokenTwo) internal {
    __before();
    _before.marketMinPrice = target.GetMarketMinPrice(tokenOne, tokenTwo);
  }

  function __after(address tokenOne, address tokenTwo) internal {
    __after();
    _after.marketMinPrice = target.GetMarketMinPrice(tokenOne, tokenTwo);
  }

  // _after.placeholder = target.placeholder();
  function __after() internal {
    for (uint256 i; i < tokens.length; ++i) {
      _after.makerBalances[i] = tokens[i].balanceOf(maker);
      _after.takerBalances[i] = tokens[i].balanceOf(taker);
      for (uint256 j; j < users.length; ++j) {
        _after.targetBalances[i][j] = target.userBalances(users[j], _tokens[i]);
      }
    }
    _after.makerOrderSize = target.GetUserOrdersSize(maker);
    _after.takerOrderSize = target.GetUserOrdersSize(taker);

  }
}
