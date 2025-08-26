// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "./Logger.sol";
import { BaseTargetFunctions } from "lib/chimera/src/BaseTargetFunctions.sol";
import { vm } from "lib/chimera/src/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Logger {
  struct Config {
    uint256 max;
    uint256 offset;
    uint256 depth;
  }

  function fuzz_market_buy(uint256 r1, uint256 r2) public {
    // uint256 r1;
    // uint256 r2;
    precondition(r1 != 0);
    precondition(r2 != 0);

    Config memory config = Config({ max: 1e15, offset: 1e4, depth: 3 });

    bytes32 greenMarket = target.getMarket(_tokens[0], _tokens[1]);

    uint256 makerPayAmounts;
    uint256 makerBuyAmounts;

    for (uint256 i; i < config.depth; ++i) {
      r1 = (seedRandom(r1) % config.max) + config.offset;
      r2 = (seedRandom(r2) % config.max) + config.offset;
      vm.prank(maker);
      target.makeOrderSimple(_weth, r1, _wbtc, r2);

      makerPayAmounts += r1;
      makerBuyAmounts += r2;
    }

    if (showLogs) {
      printList(greenMarket, "Market");
      printBreak();
    }

    r1 = (seedRandom(r1) % config.max) + config.offset;
    r2 = (seedRandom(r2) % config.max) + config.offset;

    __before(_tokens[0], _tokens[1]);
    vm.prank(taker);
    uint256 remaining = target.marketBuy(_wbtc, r1, _weth, r2);
    __after(_tokens[0], _tokens[1]);

    if (showLogs) {
      printList(greenMarket, "Market After ");
      printBreak();
    }

    (uint256 marketRemaining, uint256 marketWant) = target.CleanMarket(_weth, _wbtc);

    uint256 bobMinPrice = utilBuyToPrice(r1, r2);
    uint256 bobReversePrice = utilReversePrice(bobMinPrice);

    if (showLogs) {
      console.log(fixedLength("Bob Pays"), r1);
      console.log(fixedLength("Bob Want"), r2);
      console.log(fixedLength("Bob Price"), bobMinPrice);
      console.log(fixedLength("Bob Reverse Price"), bobReversePrice);
      console.log(
        fixedLength("Continue Condition"), int256(_before.marketMinPrice) - int256(bobReversePrice)
      );
      printBreak();
      console.log(fixedLength("Bob Remaining"), remaining);
      console.log(fixedLength("Bob Spent"), r1 - remaining);
      printBreak();
      console.log(fixedLength("Market Remaing"), marketRemaining);
      console.log(fixedLength("Market Wants"), marketWant);
      console.log(fixedLength("Market Before Min Price"), _before.marketMinPrice);
      console.log(fixedLength("Market After Min Price"), _after.marketMinPrice);
      printBreak();
      console.log(
        fixedLength("Bob _weth"), int256(_after.takerBalances[0]) - int256(_before.takerBalances[0])
      );
      console.log(
        fixedLength("Bob _wbtc"), int256(_after.takerBalances[1]) - int256(_before.takerBalances[1])
      );
      printBreak();
      console.log(
        fixedLength("Alice _weth"),
        int256(_after.makerBalances[0]) - int256(_before.makerBalances[0])
      );
      console.log(
        fixedLength("Alice _wbtc"),
        int256(_after.makerBalances[1]) - int256(_before.makerBalances[1])
      );
      printBreak();
      console.log(fixedLength("Alice Contract _weth"), _after.targetBalances[0][0]);
      console.log(fixedLength("Bob Contract _weth"), _after.targetBalances[0][1]);
      printBreak();
      console.log(fixedLength("Alice Contract _wbtc"), _after.targetBalances[1][0]);
      console.log(fixedLength("Bob Contract _wbtc"), _after.targetBalances[1][1]);
      printBreak();
      console.log(fixedLength("Alice Pay Amounts"), makerPayAmounts);
      console.log(fixedLength("Alice Buy Amounts"), makerBuyAmounts);
      printBreak();
    }

    // Funds bob paid went to alice
    eq(
      _after.targetBalances[1][0],
      _before.takerBalances[1] - _after.takerBalances[1],
      "Mismatch Sent Received Funds"
    );
    if (_after.marketMinPrice == 0) {
      // Bob bought all liquidity
      console.log("No Liquidity");
      gte(_after.targetBalances[1][0] + config.depth, makerBuyAmounts, "Alice Min Price");
      gte(
        (_after.takerBalances[0] - _before.takerBalances[0]) // Bob received weth
          + utilPriceToBuy(bobMinPrice, remaining), // What the remaining is worth at bobMinPrice
        r2, // What bob wanted
        "Bob Min Price"
      );
    } else if (bobReversePrice < _before.marketMinPrice) {
      // If market buy was not filled due to price difference
      console.log("Not Filled");
      eq(remaining, r1, "No Execution");
      eq(_after.makerBalances[0] - _before.makerBalances[0], 0, "No Execution Alice 0");
      eq(_after.makerBalances[1] - _before.makerBalances[1], 0, "No Execution Alice 1");
      eq(_after.takerBalances[0] - _before.takerBalances[0], 0, "No Execution Bob 0");
      eq(_after.takerBalances[1] - _before.takerBalances[1], 0, "No Execution Bob 1");
    } else if (
      (bobReversePrice >= _before.marketMinPrice) && (bobReversePrice < _after.marketMinPrice)
    ) {
      // If bob's market order was filled partially
      console.log("Partial Fill");
      gt(
        (_before.takerBalances[0] - _after.takerBalances[0]) // Bob's wbtc balance difference
          + utilPriceToBuy(bobMinPrice, (r1 - remaining)) // Funds needed for what Bob spent at Bob's price
          + config.depth, // Account for Rounding
        r2,
        "Bob Accounting Error"
      );
      gt(
        (_after.targetBalances[0][1] - _before.targetBalances[0][1]) // Alice contract wbtc balance
          + marketWant // Remaining funds required for Alice
          + config.depth, // Account for Rounding
        makerBuyAmounts,
        "Alice Accounting Error"
      );
    } else if (bobReversePrice >= _after.marketMinPrice) {
      // If bob's market order was filled fully
      console.log("Full Fill");
      eq(remaining, 0, "Should have none remaining");
      eq(_after.targetBalances[1][0], r1, "Alice Receives Bob's Funds");
      gt(_after.takerBalances[0] - _before.takerBalances[0], r2, "Bob Min Receive");
    }
  }

  function fuzz_cancel_order(uint96 r1, uint96 r2) public {
    precondition(r1 != 0);
    precondition(r1 < 1e25);
    precondition(r2 < 1e25);
    precondition(r2 != 0);
    __before();
    vm.prank(_alice);
    uint256 orderId = target.makeOrderSimple(_tokens[0], r1, _tokens[1], r2);
    vm.prank(_alice);
    target.cancelOrder(orderId);
    __after();

    OrdersLib.Order memory order = target.GetOrder(orderId);
    uint256 userOrderSize = target.GetUserOrdersSize(_alice);

    eq(_before.makerBalances[0], _after.makerBalances[0], "Balance Change");
    eq(_before.makerBalances[1], _after.makerBalances[1], "Balance Change Wtf");
    eq(order.pay_amount, 0, "Order Deletion Failed");
    eq(uint256(uint160(order.owner)), 0, "Order Deletion Failed");
    eq(_after.makerOrderSize - _before.makerOrderSize, 0, "User Order Not Deleted");
    t(
      !target.GetMarketOrderExists(target.getMarket(_tokens[0], _tokens[1]), orderId),
      "Order Should not Exist"
    );
  }
}

