# Canto Free Public Orderbook:

# Overview

The PublicMarket contract form the main entrypoint for the set of smart contracts. They facilitate the creation, management, and execution of trading orders within a public marketplace. This documentation provides a detailed explanation of each contract's functions, parameters, and behaviors. 

## Dependencies
MatchingEngine: Inherits from SimpleMarket and contains the logic for matching user orders. <br />
SimpleMarket: Manages the storage and retrieval of orders, user balances, and market identifiers. <br />
StructuredLinkedList: A custom data structure for efficiently storing and retrieving orders. <br />
OrdersLib: Contains utility functions and definitions related to orders. 

## System Design

The contract is designed using Vittorio Minacori's StructuredLinkedList library to create markets for each token pair. A linked list was chosen to allow for easy insertion of orders, as well as easy access to the head or lowest order in the orderbook. Each token pair is stored in a market, which is the keccak256 hash of the token addresses. You can determine the market identifier by calling the getMarket function in SimpleMarket.sol. The parameters of the getMarket function are the address of the token provided, and the address of the token desired, in that order. The order is important, because the reversed order is the market for the flipped token pair. For example, the market where one provides WCanto for Note is: getMarket(address(WCanto), address(Note)), and the market where one provides Note for WCanto is: getMarket(address(Note), address(WCanto)). 

When one creates an order on the orderbook, it will first check the reversed market pair to see if the order is immediately executable. If the order can be executed, it will, and any of the leftover order that cannot be executed will become an order in the orderbook. Orders will remain in the orderbook until they are filled, or canceled. Creating an order and making a market buy are very similar, however, in a market buy any leftover funds will be returned to the caller. A market buy will revert if it cannot be filled at the specified price. 

An important consideration is that after an order is filled, the funds are not directly sent to the owner of the order. The funds need to be claimed from the contract using the withdraw or withdrawMany function. This is a security consideration to avoid callbacks and reentrancy. The withdraw function takes an address of the token to withdraw, and the withdrawMany takes an array of addresses. 

The orderbook should support any ERC-20 token. ERC-721 are not supported. You can immediately list a newly created token by it's address, no configuration needed. 

## PublicMarket Contract


### makeOrderSimple

Creates a simple trading order.  

Parameters <br /> 
pay_tkn{address}: Address of the payment token. <br />
pay_amt{uint256}: Amount of payment token to trade. Must have approval to transfer tokens from user.<br />
buy_tkn{address}: Address of the buying token. <br />
buy_amt{uint256}: Amount of buying token desired. <br />
Returns <br />
uint256: Order ID. 


### marketBuy
Executes a market buy operation, attempting to purchase a specified amount of a token (buy_tkn) using another token (pay_tkn). The function calculates the best possible price based on the current market conditions.

Parameters <br />
pay_tkn{address}: Address of the payment token.  <br />
pay_amt{uint256}: Amount of payment token to trade. Must have approval to transfer tokens from user. <br />
buy_tkn{address}: Address of the buying token. <br />
buy_amt{uint256}: Amount of buying token desired. <br />
Returns <br />
uint256: Remaining amount of pay_tkn after the transaction, if any. 

### cancelOrder
Cancels an existing order, returning any unfulfilled amounts to the order's creator.

Parameters <br />
orderId{uint256}: ID of the order to cancel. 

### withdraw
Allows a user to withdraw their balance of a specific token from the contract. Tokens from fufilled orders are generally held by the contract and must be claimed.

Parameters <br />
token{address}: Address of the token to withdraw. 

### withdrawMany
Permits a user to withdraw balances of multiple tokens at once. Tokens from fufilled orders are generally held by the contract and must be claimed.

Parameters <br />
tokens{address[]}: Array of addresses representing the tokens to withdraw. 

### getUserOrders
Retrieves an array of orders which an address has active in the market.

Parameters <br />
user{address}: The address of the user to retrieve data <br />
Returns <br />
An array of Order structs the user has in the market, and a uint256 array of the user's orderIds. 

### getMarketOrders
Retrieves the top number of items in a market, providing details about the lowest-cost orders.

Parameters <br />
pay_token{address}: Collateral token for the market. <br />
buy_token{address}: Token sought in exchange for the collateral. <br />
numItems{uint256}: Number of items to retrieve. <br />
Returns <br />
Two {uint256[]}: Pay amounts and buy amounts for the top market orders. 

## SimpleMarket.sol


### userBalances
Get the balance of a user for a specific token. Public mapping variable.

Parameters <br />
First address: User's address. <br />
Second address: Token's address <br />
mapping(address => mapping(address => uint256)) public userBalances;

### orders
Get an order from an orderId. OrderIds are returned and emitted when creating an order. Public mapping variable. 

Parameters <br />
uint256: OrderId <br />
mapping(uint256 => OrdersLib.Order) public orders;

### getMarket 
Get the bytes32 identifier for a market. 

Parameters <br />
pay_token{address}: Collateral token for the market. <br />
buy_token{address}: Token sought in exchange for the collateral. <br />
Returns <br />
Bytes32 identifier for where the market is stored in storage.