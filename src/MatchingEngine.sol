//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity 0.8.20;

import { OrdersLib } from "src/Libraries/OrdersLib.sol";
import { SoladySafeCastLib } from "src/Libraries/SoladySafeCastLib.sol";
import { SimpleMarket, StructuredLinkedList } from "src/SimpleMarket.sol";

contract MatchingEngine is SimpleMarket {
  using StructuredLinkedList for StructuredLinkedList.List;
  using OrdersLib for OrdersLib.Order;
  using SoladySafeCastLib for uint256;

  /// @notice Handles the overall market buy process
  /// @param request The marketBuy request data as an Order struct
  /// @return remainingAmount The amount of the request left unbought
  function _matchOrder(OrdersLib.Order memory request) internal returns (uint256) {
    // Buying into the reversed market list
    bytes32 market = _getReversedMarket(request.pay_token, request.buy_token);

    uint256 remainingAmount = request.pay_amount;
    uint256 purchasedAmount;

    bool flag = true;

    while (flag) {
      (flag, remainingAmount, purchasedAmount) =
        _processBuy(market, remainingAmount, request.price, purchasedAmount, request.pay_token);
    }

    if (purchasedAmount != 0) {
      userBalances[request.owner][request.buy_token] += purchasedAmount;
    }

    return remainingAmount;
  }

  /// @notice Handle the market buy process on individual stored orders
  /// @param market The bytes32 identifier for the market
  /// @param remainingAmount The amount left in the buy order
  /// @param requestPrice The maximum price to buy orders
  /// @param purchasedAmount The total amount of purchased tokens
  /// @param payToken The pay_token of the ***buy_order***
  /// @return bool True if we continue buying orders, false if done
  /// @return uint256 The remaining amount of purchasing power
  /// @return uint256 The cumulative amount of tokens purchased
  function _processBuy(
    bytes32 market,
    uint256 remainingAmount,
    uint256 requestPrice,
    uint256 purchasedAmount,
    address payToken
  ) internal returns (bool, uint256, uint256) {
    (, uint256 orderId) = marketLists[market].getAdjacent(0, true);
    // If orderId is zero the list is empty
    if (orderId == 0) return (false, remainingAmount, purchasedAmount);

    OrdersLib.Order storage order = orders[orderId];

    if (order.reversePrice() < requestPrice) {
      return (false, remainingAmount, purchasedAmount);
    }

    uint256 payOut;
    // If the order is greater than the buy request, consume the buy request
    // otherwise consume the order and continue
    if (order.priceToBuy() > remainingAmount) {
      payOut = order.buyQuote(remainingAmount);
      order.pay_amount = (order.pay_amount - payOut).toUint96();

      purchasedAmount += payOut;
      userBalances[order.owner][payToken] += remainingAmount;
      emit UserBalanceUpdated(order.owner, payToken);

      return (false, 0, purchasedAmount);
    } else {
      payOut = order.priceToBuy();

      purchasedAmount += order.pay_amount;
      userBalances[order.owner][payToken] += payOut;
      emit UserBalanceUpdated(order.owner, payToken);

      userOrders[orders[orderId].owner].remove(orderId);
      _popHead(market, orderId);
      return (true, remainingAmount - payOut, purchasedAmount);
    }
  }

  /// @notice Remove the first item of the a market
  /// @param market The market of the order to remove
  /// @param orderId The id of the order to remove
  function _popHead(bytes32 market, uint256 orderId) internal {
    marketLists[market].popFront();
    delete orders[orderId];
  }
}
