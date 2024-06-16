//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity 0.8.20;
// 0xecf55337d2a1588a14fe7666cfb47b4de3063408 - Testnet
import { SoladySafeCastLib } from "src/Libraries/SoladySafeCastLib.sol";
import {
  MatchingEngine,
  OrdersLib,
  SoladySafeCastLib,
  StructuredLinkedList
} from "src/MatchingEngine.sol";

contract PublicMarket is MatchingEngine {
  using StructuredLinkedList for StructuredLinkedList.List;
  using OrdersLib for OrdersLib.Order;
  using SoladySafeCastLib for uint256;

  // Used for mainnet deployment to register on the turnstile
  // constructor(address _turnstile, address owner) {
  //     (bool ok, ) = _turnstile.call(abi.encodeWithSignature("register(address)", owner));
  //     require(ok, "Failed to register");
  // }

  /// @notice Public entrypoint to making an order
  /// @dev See _makeOrder
  function makeOrderSimple(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt
  ) external returns (uint256) {
    return _makeOrder(pay_tkn, pay_amt, buy_tkn, buy_amt, msg.sender, "");
  }
  /// @notice Public entrypoint to making an order for another
  /// @dev Not recommended for general use
  /// @dev Caller pays, and recipient receives the funds

  function makeOrderOnBehalf(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt,
    address recipient
  ) external returns (uint256) {
    return _makeOrder(pay_tkn, pay_amt, buy_tkn, buy_amt, recipient, "");
  }

  /// @notice Public entrypoint to making a market buy
  /// @dev See _marketBuy
  function marketBuy(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt
  ) external returns (uint256) {
    return _marketBuy(pay_tkn, pay_amt, buy_tkn, buy_amt);
  }

  /// @notice Public entrypoint to making a marketBuy
  /// @dev Unpurchased funds will be returned to user
  /// @param pay_tkn, the address of the token the user has and wants to trade
  /// @param pay_amt, the amount of pay_tkn the user wants to trade
  /// @param buy_tkn, the address of the token the user wants in return for pay_token
  /// @param buy_amt, the amount of buy_tkn the user wants in return for pay_amt
  /// @return Uint256, The amount remaining from the marketBuy
  function _marketBuy(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt
  ) internal returns (uint256) {
    if (pay_amt == 0) revert InvalidOrder();
    if (buy_amt == 0) revert InvalidOrder();
    if (pay_tkn == address(0)) revert InvalidOrder();
    if (buy_tkn == address(0)) revert InvalidOrder();
    if (pay_tkn == buy_tkn) revert InvalidOrder();

    uint256 received = _receiveFunds(pay_tkn, pay_amt, msg.sender);

    uint256 orderPrice = OrdersLib.buyToPrice(buy_amt, received);
    if (orderPrice < OrdersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

    OrdersLib.Order memory order = OrdersLib.Order({
      price: orderPrice,
      pay_amount: received.toUint96(),
      pay_token: pay_tkn,
      buy_token: buy_tkn,
      owner: msg.sender,
      data: ""
    });

    uint256 remaining = _marketBuy(order);

    if (remaining == buy_amt) revert NoneBought();

    _sendFunds(msg.sender, buy_tkn);
    if (remaining != 0) {
      // _sendFunds will provide gas refund for this sstore
      userBalances[msg.sender][pay_tkn] += remaining;
      _sendFunds(msg.sender, pay_tkn);
    }
    return remaining;
  }

  /// @notice Entrypoint to making an order
  /// @dev First checks if the order can be filled from reversed market
  /// @dev Unpurchased funds will be listed in orderbook
  /// @param pay_tkn, the address of the token the user has and wants to trade
  /// @param pay_amt, the amount of pay_tkn the user wants to trade
  /// @param buy_tkn, the address of the token the user wants in return for pay_token
  /// @param buy_amt, the amount of buy_tkn the user wants in return for pay_amt
  /// @param logic, optional bytes data field for additional logic
  /// @return Uint256, The id of the created order, 0 if fully filled
  function _makeOrder(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt,
    address recipient,
    bytes memory logic
  ) internal returns (uint256) {
    if (pay_amt == 0) revert InvalidOrder();
    if (buy_amt == 0) revert InvalidOrder();
    if (pay_tkn == address(0)) revert InvalidOrder();
    if (buy_tkn == address(0)) revert InvalidOrder();
    if (pay_tkn == buy_tkn) revert InvalidOrder();

    uint256 received = _receiveFunds(pay_tkn, pay_amt, msg.sender);

    uint256 orderPrice = OrdersLib.buyToPrice(buy_amt, received);
    if (orderPrice < OrdersLib.MAX_PRECISION_LOSS) revert PrecisionLoss();

    OrdersLib.Order memory order = OrdersLib.Order({
      price: orderPrice,
      pay_amount: received.toUint96(),
      pay_token: pay_tkn,
      buy_token: buy_tkn,
      owner: recipient,
      data: logic
    });

    uint256 remaining = _marketBuy(order);
    uint256 orderId;

    if (remaining > 0) {
      order.pay_amount = remaining.toUint96();
      orderId = _recordOrder(order);
    }

    _sendFunds(recipient, buy_tkn);
    return orderId;
  }

  /// @notice Cancel an existing order
  /// @param orderId The id of the order to cancel
  function cancelOrder(uint256 orderId) external {
    OrdersLib.Order storage order = orders[orderId];
    if (msg.sender != order.owner) revert InvalidOwnership();

    address payToken = order.pay_token;

    bytes32 market = getMarket(payToken, order.buy_token);

    userBalances[msg.sender][payToken] += order.pay_amount;

    // There is no orderId 0, so should revert on !nodeExists check in remove
    if (marketLists[market].remove(orderId) != orderId) revert NotFound();
    _popUserOrder(orderId);
    delete orders[orderId];

    _sendFunds(msg.sender, payToken);
  }

  /// @notice Allow user to withdraw their balance of tokens from contract
  /// @param token The address of the token to receive
  function withdraw(address token) external {
    _sendFunds(msg.sender, token);
  }

  /// @notice Allow user to withdraw several tokens at once
  /// @param tokens An array containing the address of tokens to receive
  function withdrawMany(address[] calldata tokens) external {
    uint256 len = tokens.length;
    for (uint256 i; i < len; ++i) {
      _sendFunds(msg.sender, tokens[i]);
    }
  }

  /// @notice Get a user's current orders
  /// @param user The address of the user
  /// @return OrdersLib.Order[] An unsorted array of user's orders
  function getUserOrders(address user)
    external
    view
    returns (OrdersLib.Order[] memory, uint256[] memory)
  {
    StructuredLinkedList.List storage list = userOrders[user];
    uint256 size = list.size;

    OrdersLib.Order[] memory userOrder = new OrdersLib.Order[](size);
    uint256[] memory userOrderIds = new uint256[](size);

    uint256 orderId;
    for (uint256 i; i < size; ++i) {
      (, orderId) = list.getAdjacent(orderId, true);
      userOrderIds[i] = orderId;
      userOrder[i] = orders[orderId];
    }

    return (userOrder, userOrderIds);
  }

  /// @notice Get the top number of items in a market
  /// @param pay_token The collateral token for the market
  /// @param buy_token The token that is wanted for the provided collateral
  /// @param numItems The number of items to return IF less than market size
  /// @return uint256[] The array of pay_amounts for the top market orders
  /// @return uint256[] The array of buy_amounts for the top market orders
  function getMarketOrders(
    address pay_token,
    address buy_token,
    uint256 numItems
  ) external view returns (uint256[] memory, uint256[] memory) {
    bytes32 market = getMarket(pay_token, buy_token);

    StructuredLinkedList.List storage list = marketLists[market];

    uint256 size = list.size;
    if (numItems < size) {
      size = numItems;
    }

    uint256[] memory pay_amounts = new uint256[](size);
    uint256[] memory buy_amounts = new uint256[](size);

    uint256 orderId;
    for (uint256 i; i < size; ++i) {
      (, orderId) = list.getAdjacent(orderId, true);
      pay_amounts[i] = (orders[orderId].pay_amount);
      buy_amounts[i] = (orders[orderId].priceToBuy());
    }
    return (pay_amounts, buy_amounts);
  }
}
