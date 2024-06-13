//SPDX-LICENSE-IDENTIFIER: UNLICENSED
pragma solidity 0.8.24;

import "src/PublicMarket.sol";
import { Math } from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract PublicMarketHarness is PublicMarket {
  using StructuredLinkedList for StructuredLinkedList.List;
  using OrdersLib for OrdersLib.Order;
  using Math for uint256;

  function GetMarkets(address pay_token, address buy_token) public pure returns (bytes32, bytes32) {
    return (getMarket(pay_token, buy_token), _getReversedMarket(pay_token, buy_token));
  }

  function GetBuyAmount(uint256 pay_amount, uint256 price) public pure returns (uint256) {
    return price.mulDiv(pay_amount, OrdersLib.SCALE_FACTOR);
  }

  function GetBuyAmount(uint256 id) public view returns (uint256) {
    OrdersLib.Order storage order = orders[id];
    return order.priceToBuy();
  }

  function GetReversePrice(uint256 orderId) public view returns (uint256) {
    OrdersLib.Order storage order = orders[orderId];
    return order.reversePrice();
  }

  function GetUserBalances(address user, address[] calldata tokens) external returns(uint256[] memory){
    uint256 lenTokens = tokens.length;
    
    uint256[] memory userBalance = new uint256[](lenTokens);

    for (uint256 i; i < lenTokens; ++i) {
      userBalance[i] = userBalances(user, tokens[i]);
    }

    return userBalance;
  }

  function GetListSize(bytes32 market) public view returns (uint256) {
    return marketLists[market].size;
  }

  function CleanMarkets(address tokenOne, address tokenTwo)
    public
    returns (uint256 greenRemaining, uint256 greenWant, uint256 redRemaining, uint256 redWant)
  {
    bytes32 greenMarket = getMarket(tokenOne, tokenTwo);
    bytes32 redMarket = getMarket(tokenTwo, tokenOne);
    (, uint256 greenId) = marketLists[greenMarket].getAdjacent(0, true);
    (, uint256 redId) = marketLists[redMarket].getAdjacent(0, true);

    while (greenId != 0) {
      greenRemaining += orders[greenId].pay_amount;
      greenWant += orders[greenId].priceToBuy();
      _popHead(greenMarket, greenId);
      (, greenId) = marketLists[greenMarket].getAdjacent(0, true);
    }
    while (redId != 0) {
      redRemaining += orders[redId].pay_amount;
      redWant += orders[redId].priceToBuy();
      _popHead(redMarket, redId);
      (, redId) = marketLists[redMarket].getAdjacent(0, true);
    }
  }

  function CleanBalance(address user, address token) public returns (uint256 balance) {
    balance = userBalances[user][token];
    delete userBalances[user][token];
  }

  function GetMarketList(bytes32 market) public view returns (uint256[] memory) {
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
