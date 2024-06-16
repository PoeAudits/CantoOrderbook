// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Setup } from "./Setup.sol";
import { console as console } from "forge-std/console.sol";
import { OrdersLib } from "src/Libraries/OrdersLib.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
  using OrdersLib for OrdersLib.Order;

  struct Vars {
    uint256 nextOrderId;
    uint256 userOrderSize;
    uint256 marketSize;
    uint256 reverseMarketSize;
  }

  struct UserVars {
    uint256[2] tokenBalances;
    uint256[2] targetBalances;
  }

  Vars internal _before;
  Vars internal _after;
  address internal sender;

  modifier getSender() virtual {
    sender = msg.sender;
    _;
  }
  // Global variables

  function __before() internal {
    _before.nextOrderId = target.GetNextOrderId();
    _before.userOrderSize = target.GetUserOrdersSize(_alice);
  }

  function __before(uint256 rand) internal {
    __before();
    (address u_one, address u_two) = pickAddress(rand);
    (address t_one, address t_two) = pickTokenPair(rand);

    _before.marketSize = target.GetMarketSize(target.getMarket(t_one, t_two));
    _before.reverseMarketSize = target.GetMarketSize(target.getMarket(t_two, t_one));
  }

  // Global variables
  function __after() internal {
    _after.nextOrderId = target.GetNextOrderId();
    _after.userOrderSize = target.GetUserOrdersSize(_alice);
  }

  function __after(uint256 rand) internal {
    __after();
    (address u_one, address u_two) = pickAddress(rand);
    (address t_one, address t_two) = pickTokenPair(rand);

    _after.marketSize = target.GetMarketSize(target.getMarket(t_one, t_two));
    _after.reverseMarketSize = target.GetMarketSize(target.getMarket(t_two, t_one));
  }

  function printVars() internal view {
    console.log("");
    console.log(fixedLength("nextOrderId Before: "), _before.nextOrderId);
    console.log(fixedLength("nextOrderId After: "), _after.nextOrderId);
    printSeperator();
    console.log(fixedLength("userOrderSize Before: "), _before.userOrderSize);
    console.log(fixedLength("userOrderSize After: "), _after.userOrderSize);
    printSeperator();

    console.log("");
  }

  function printId(uint256 orderId) internal view {
    OrdersLib.Order memory order = target.GetOrder(orderId);
    uint256 buy_amount = target.GetBuyAmount(orderId);
    bytes32 marketIdentifier = target.getMarket(order.pay_token, order.buy_token);

    console.log(fixedLength("Order     : "), orderId);
    console.log("{");
    console.log(fixedLength("Price     : "), order.price);
    console.log(fixedLength("Pay Amount: "), order.pay_amount);
    console.log(fixedLength("Buy Amount: "), buy_amount);
    console.log(fixedLength("Pay Token : "), order.pay_token);
    console.log(fixedLength("Buy Token : "), order.buy_token);
    console.log(fixedLength("Owner     : "), order.owner);

    console.log("Market    : ");
    console.logBytes32(marketIdentifier);
    console.log("}");
    console.log("");
  }

  function printList(bytes32 market, string memory id) internal {
    console.logString(id);
    uint256[] memory lst = target.GetMarketList(market);
    for (uint256 i; i < lst.length; ++i) {
      printId(lst[i]);
    }
    console.logString("");
  }

  function printSeperator() internal view {
    console.log("--------------------------------------------------------------------");
  }

  function fixedLength(string memory s) internal pure returns (string memory) {
    uint256 len = 40;
    bytes memory b = abi.encodePacked(s);
    if (b.length > len) {
      return s;
    }
    uint256 spacesNeeded = len - b.length;

    if (spacesNeeded > 0) {
      // Only add spaces if necessary
      bytes memory spaces = new bytes(spacesNeeded);
      for (uint256 i = 0; i < spacesNeeded; i++) {
        spaces[i] = " "; // Fill the spaces byte array with spaces
      }
      bytes memory resultBytes = abi.encodePacked(b, spaces);

      return string(resultBytes);
    }
  }
}
