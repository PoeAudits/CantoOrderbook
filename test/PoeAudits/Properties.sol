// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BeforeAfter, OrdersLib } from "./BeforeAfter.sol";
import { Asserts } from "lib/chimera/src/Asserts.sol";

abstract contract Properties is BeforeAfter, Asserts {
  using OrdersLib for OrdersLib.Order;

  // example property test that gets run after each call in sequence
  // function invariant_order_zero() public returns (bool) {
  //   OrdersLib.Order memory orderZero = target.GetOrder(0);
  //   eq(orderZero.price, 0, "Order Zero Broken");
  //   eq(orderZero.pay_amount, 0, "Order Zero Broken");
  //   eq(uint256(uint160(orderZero.pay_token)), 0, "Order Zero Broken");
  //   eq(uint256(uint160(orderZero.buy_token)), 0, "Order Zero Broken");
  //   eq(uint256(uint160(orderZero.owner)), 0, "Order Zero Broken");
  // }
}
