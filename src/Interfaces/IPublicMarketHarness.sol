// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {OrdersLib} from "src/Libraries/OrdersLib.sol";

interface IPublicMarketHarness {

    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error BadInsert(uint256 pos);
    error FailedInnerCall();
    error InvalidBuy();
    error InvalidOrder();
    error InvalidOwnership();
    error MathOverflowedMulDiv();
    error NoneBought();
    error NotFound();
    error PrecisionLoss();
    error SafeERC20FailedOperation(address token);

    event MakeOrder(uint256 id, bytes32 market, uint256 price);
    event UserBalanceUpdated(address user, address token);

    function CleanBalance(address user, address token) external returns (uint256 balance);
    function CleanMarket(address tokenOne, address tokenTwo)
        external
        returns (uint256 greenRemaining, uint256 greenWant);
    function GetBuyAmount(uint256 orderId) external view returns (uint256);
    function GetMarketList(bytes32 market) external view returns (uint256[] memory);
    function GetMarketMinPrice(address tokenOne, address tokenTwo) external view returns (uint256);
    function GetMarketSize(bytes32 market) external view returns (uint256);
    function GetNextOrderId() external view returns (uint256);
    function GetOrder(uint256 orderId) external view returns (OrdersLib.Order memory);
    function GetUserBalances(address user, address[] memory tokens) external view returns (uint256[] memory);
    function GetUserOrdersSize(address user) external view returns (uint256);
    function HarnessProcessBuy(OrdersLib.Order memory order) external returns (bool, uint256, uint256);
    function HarnessRecordOrder(OrdersLib.Order memory order) external returns (uint256);
    function _getMarketOrders(address pay_token, address buy_token, uint256 numItems)
        external
        view
        returns (uint256[] memory, uint256[] memory);
    function cancelOrder(uint256 orderId) external;
    function getMarket(address pay_token, address buy_token) external pure returns (bytes32);
    function getUserOrders(address user) external view returns (OrdersLib.Order[] memory, uint256[] memory);
    function getValue(uint256 id) external view returns (uint256);
    function makeOrderOnBehalf(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt, address recipient)
        external
        returns (uint256);
    function makeOrderSimple(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt)
        external
        returns (uint256);
    function marketBuy(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt) external returns (uint256);
    function orders(uint256)
        external
        view
        returns (
            uint256 price,
            uint96 pay_amount,
            address pay_token,
            address buy_token,
            address owner,
            bytes memory data
        );
    function userBalances(address, address) external view returns (uint256);
    function withdraw(address token) external;
    function withdrawMany(address[] memory tokens) external;
    function ownerFlushMarket(bytes32 market, uint256[] calldata orderIds) external;
}
