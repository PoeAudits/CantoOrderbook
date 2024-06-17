//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.20;

import { Math } from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "src/PublicMarket.sol";

contract PublicMarketHarness is PublicMarket {
  using StructuredLinkedList for StructuredLinkedList.List;
  using OrdersLib for OrdersLib.Order;
  using Math for uint256;

  function HarnessRecordOrder(OrdersLib.Order memory order) external returns (uint256) {
    return _recordOrder(order);
  }

  function HarnessProcessBuy(OrdersLib.Order memory order)
    external
    returns (bool, uint256, uint256)
  {
    bytes32 market = _getReversedMarket(order.pay_token, order.buy_token);

    return _processBuy(market, order.pay_amount, order.price, 0, order.pay_token);
  }

  function GetNextOrderId() external view returns (uint256) {
    return nextOrderId;
  }

  function GetUserOrdersSize(address user) external view returns (uint256) {
    return userOrders[user].size;
  }

  function GetUserBalances(
    address user,
    address[] calldata tokens
  ) external view returns (uint256[] memory) {
    uint256 lenTokens = tokens.length;

    uint256[] memory userBalance = new uint256[](lenTokens);

    for (uint256 i; i < lenTokens; ++i) {
      userBalance[i] = userBalances[user][tokens[i]];
    }

    return userBalance;
  }

  // function EfficientHash(
  //   address pay_token,
  //   address buy_token
  // ) external pure returns (bytes32 value) {
  //   /// @solidity memory-safe-assembly
  //   assembly {
  //     mstore(0x00, pay_token)
  //     mstore(0x20, buy_token)
  //     value := keccak256(0x00, 0x40)
  //   }
  // }

  function GetMarketSize(bytes32 market) external view returns (uint256) {
    return marketLists[market].size;
  }

  function GetMarketOrderExists(bytes32 market, uint256 orderId) external view returns (bool) {
    return marketLists[market].nodeExists(orderId);
  }

  function GetMarketMinPrice(address tokenOne, address tokenTwo) external view returns (uint256) {
    bytes32 greenMarket = _getMarket(tokenOne, tokenTwo);
    (, uint256 greenId) = marketLists[greenMarket].getAdjacent(0, true);
    uint256 minPrice = orders[greenId].price;
    return minPrice;
  }

  function GetOrder(uint256 orderId) external view returns (OrdersLib.Order memory) {
    return orders[orderId];
  }

  function GetBuyAmount(uint256 orderId) external view returns (uint256) {
    return orders[orderId].priceToBuy();
  }

  function CleanMarket(
    address tokenOne,
    address tokenTwo
  ) external returns (uint256 greenRemaining, uint256 greenWant) {
    bytes32 greenMarket = _getMarket(tokenOne, tokenTwo);
    // bytes32 redMarket = _getMarket(tokenTwo, tokenOne);
    (, uint256 greenId) = marketLists[greenMarket].getAdjacent(0, true);
    // (, uint256 redId) = marketLists[redMarket].getAdjacent(0, true);
    while (greenId != 0) {
      greenRemaining += orders[greenId].pay_amount;
      greenWant += orders[greenId].priceToBuy();
      _popHead(greenMarket, greenId);
      (, greenId) = marketLists[greenMarket].getAdjacent(0, true);
    }
    // while (redId != 0) {
    //   redRemaining += orders[redId].pay_amount;
    //   redWant += orders[redId].priceToBuy();
    //   _popHead(redMarket, redId);
    //   (, redId) = marketLists[redMarket].getAdjacent(0, true);
    // }
  }

  function CleanBalance(address user, address token) external returns (uint256 balance) {
    balance = userBalances[user][token];
    delete userBalances[user][token];
  }

  function GetMarketList(bytes32 market) external view returns (uint256[] memory) {
    StructuredLinkedList.List storage list = marketLists[market];
    uint256 len = list.sizeOf();
    uint256[] memory items = new uint256[](len);

    uint256 current = list.list[0][true];
    for (uint256 i; i < len; ++i) {
      items[i] = current;
      (, current) = list.getNextNode(current);
    }

    return items;
  }
}
