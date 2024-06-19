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

import { OwnableUpgradeable } from
  "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { Initializable } from
  "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from
  "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from
  "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

contract PublicMarket is
  MatchingEngine,
  Initializable,
  ReentrancyGuardUpgradeable,
  UUPSUpgradeable,
  OwnableUpgradeable
{
  using StructuredLinkedList for StructuredLinkedList.List;
  using OrdersLib for OrdersLib.Order;
  using SoladySafeCastLib for uint256;

  constructor() {
    _disableInitializers();
  }

  /// @notice Initialization for initial deployment
  function __PublicMarket_init(
    address _initialOwner,
    address _csrRecipient,
    address _turnstile
  ) external initializer {
    __Ownable_init(_initialOwner);
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();
    __PublicMarket_init_unchained(_csrRecipient, _turnstile);
  }

  /// @notice Initialization for initial deployment
  /// @dev Crucial that nextOrderId is set to 1
  function __PublicMarket_init_unchained(
    address _csrRecipient,
    address _turnstile
  ) internal onlyInitializing {
    // (bool ok, ) = _turnstile.call(abi.encodeWithSignature("register(address)", _csrRecipient));
    // require(ok, "Failed to register");
    nextOrderId = 1;
  }

  /// @notice Public entrypoint to making an order
  /// @dev See _makeOrder
  function makeOrderSimple(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt
  ) external nonReentrant returns (uint256) {
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
  ) external nonReentrant returns (uint256) {
    return _makeOrder(pay_tkn, pay_amt, buy_tkn, buy_amt, recipient, "");
  }

  /// @notice Public entrypoint to making a market buy
  /// @dev See _marketBuy
  function marketBuy(
    address pay_tkn,
    uint256 pay_amt,
    address buy_tkn,
    uint256 buy_amt
  ) external nonReentrant returns (uint256) {
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

    uint256 remaining = _matchOrder(order);

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
    if (recipient == address(0)) revert InvalidOrder();
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

    uint256 remaining = _matchOrder(order);
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
  function cancelOrder(uint256 orderId) external nonReentrant {
    OrdersLib.Order storage order = orders[orderId];
    if (msg.sender != order.owner) revert InvalidOwnership();

    address payToken = order.pay_token;

    bytes32 market = _getMarket(payToken, order.buy_token);

    userBalances[msg.sender][payToken] += order.pay_amount;

    // There is no orderId 0, so should revert on !nodeExists check in remove
    if (marketLists[market].remove(orderId) != orderId) revert NotFound();
    userOrders[orders[orderId].owner].remove(orderId);
    delete orders[orderId];

    _sendFunds(msg.sender, payToken);
    emit OrderCanceled(orderId, market);
  }

  /// @notice Allow user to withdraw their balance of tokens from contract
  /// @param token The address of the token to receive
  function withdraw(address token) external nonReentrant {
    _sendFunds(msg.sender, token);
  }

  /// @notice Allow user to withdraw several tokens at once
  /// @param tokens An array containing the address of tokens to receive
  function withdrawMany(address[] calldata tokens) external nonReentrant {
    uint256 len = tokens.length;
    for (uint256 i; i < len; ++i) {
      _sendFunds(msg.sender, tokens[i]);
    }
  }

  /// @notice Get the market identifier for a token pair
  /// @dev Each market has a unique bytes32 identifier based on the token pair
  /// @param pay_token the address of the token the user has and wants to trade
  /// @param buy_token the address of the token the user wants in return for pay_token
  /// @return Bytes32 identifier of the market
  function getMarket(address pay_token, address buy_token) external pure returns (bytes32) {
    return _getMarket(pay_token, buy_token);
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
    bytes32 market = _getMarket(pay_token, buy_token);

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

  /// @notice Emergency function for owners to remove orders from market
  /// @dev Users are attributed their tokens if removed in this manner, must be claimed
  /// @param market The bytes32 market to remove orders from
  /// @param orderIds The order ids to remove
  function ownerFlushMarket(bytes32 market, uint256[] calldata orderIds) external onlyOwner {
    StructuredLinkedList.List storage list = marketLists[market];

    uint256 len = orderIds.length;
    uint256 orderId;
    for (uint256 i; i < len; ++i) {
      OrdersLib.Order memory order = orders[orderIds[i]];
      userBalances[order.owner][order.pay_token] += order.pay_amount;
      userOrders[order.owner].remove(orderIds[i]);
      if (list.remove(orderIds[i]) == 0) revert NotFound();
    }

    emit OwnerFlushMarket(market, orderIds);
  }

  /// @notice UUPS upgrade function, restricted to Owner
  function _authorizeUpgrade(address) internal override onlyOwner { }
}
