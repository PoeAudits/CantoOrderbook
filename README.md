# Overview

The PublicMarket contract form the main entrypoint for the set of smart contracts. They facilitate the creation, management, and execution of trading orders within a public marketplace. This documentation provides a detailed explanation of each contract's functions, parameters, and behaviors. 

The intention behind this orderbook is to eventually add it, or a version of it, to Canto's existing Free Public Infrastructure. The orderbook takes no fees from makers nor takers, and any EOA or protocol can add to and buy from the orderbook.

One of the major problems with current orderbooks are that they are highly fragmented. An orderbook run by Coinbase cannot interact with an orderbook run by Binance, and the liquidity is halved. Protocols are incentivized to keep their own orderbooks to profit off the exorbitant fees, but doing so degrades user experience. Some protocols try to bridge this gap by aggregating different exchanges and finding the best prices for your tokens, but this is inefficient and costly. 

This project is permissionless, and anyone can use it to trade any ERC20 tokens. Technically, any token can be listed on the orderbook as long as it has functions for transfer(address,uint256), transferFrom(address,address,uint256), and balanceOf(address). 

## Introduction 

### Orderbooks
Orderbooks are a common tool used in finance to facilitate user transactions. They use a sorted list of maker orders for specific token pairs to match users who are trying to trade one token for another. Most exchanges use the orderbook model as they allow for consistent transactions, and can allow for more complex order types. 

Most orderbooks in use today are heavily centralized entities with little transparency or assurance of their inner workings. The opaque manner in which they are run creates concerns about their "fairness" such that they may create fake volume and engage in price manipulation or insider trading. A decentralized orderbook where all orders are written onto the blockchain allows for transparent trading while maintaining many of the benefits of the orderbook model. 


### Automated Market Makers
Canto already has an AMM in the free public infrastructure, so should a public decentralized orderbook even exist? The AMM model is an innovative method in which to allow for freely accessable, decentralized transactions between token pairs. AMMs process all transactions automatically, without relying on third party buy/sell requests for the token being traded. This system has its benefits, but it also has its drawbacks. Some of the drawbacks of the AMM model include slippage, liquidity fragmentation, impermanent loss, and only supports simple order types. If you want to create a limit order, or have your order expire after a certain timelimit you are basically out of luck. Additionally, liquidity providers must supply liquidity for each supported token pair, and if a pair has little liquidity, traders can severly unbalance the pools creating significant losses.

## System Design

The contract is designed using Vittorio Minacori's StructuredLinkedList library to create markets for each token pair. A linked list was chosen to allow for easy insertion of orders, as well as easy access to the head or lowest order in the orderbook. Each token pair is stored in a market, which is the keccak256 hash of the token addresses. You can determine the market identifier by calling the getMarket function in SimpleMarket.sol. The parameters of the getMarket function are the address of the token provided, and the address of the token desired, in that order. The order is important, because the reversed order is the market for the flipped token pair. For example, the market where one provides WCanto for Note is: getMarket(address(WCanto), address(Note)), and the market where one provides Note for WCanto is: getMarket(address(Note), address(WCanto)). 

When one creates an order on the orderbook, it will first check the reversed market pair to see if the order is immediately executable. If the order can be executed, it will, and any of the leftover order that cannot be executed will become an order in the orderbook. Orders will remain in the orderbook until they are filled, or canceled. Creating an order and making a market buy are very similar, however, in a market buy any leftover funds will be returned to the caller. A market buy will revert if it cannot be filled at the specified price. 

An important consideration is that after an order is filled, the funds are not directly sent to the owner of the order. The funds need to be claimed from the contract using the withdraw or withdrawMany function. This is a security consideration to avoid callbacks and reentrancy. The withdraw function takes an address of the token to withdraw, and the withdrawMany takes an array of addresses. 

The orderbook should support any ERC-20 token. ERC-721 are not supported. You can immediately list a newly created token by it's address, no configuration needed. 

## Dependencies
MatchingEngine: Inherits from SimpleMarket and contains the logic for matching user orders. <br />
SimpleMarket: Manages the storage and retrieval of orders, user balances, and market identifiers. <br />
StructuredLinkedList: A custom data structure for efficiently storing and retrieving orders. <br />
OrdersLib: Contains utility functions and definitions related to orders. 

# Code

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