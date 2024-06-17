// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IPublicMarket {
    struct Order {
        uint256 price;
        uint96 pay_amount;
        address pay_token;
        address buy_token;
        address owner;
        bytes data;
    }

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

    function _getMarketOrders(address pay_token, address buy_token, uint256 numItems)
        external
        view
        returns (uint256[] memory, uint256[] memory);
    function cancelOrder(uint256 orderId) external;
    function getMarket(address pay_token, address buy_token) external pure returns (bytes32);
    function getUserOrders(address user) external view returns (Order[] memory, uint256[] memory);
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
}
