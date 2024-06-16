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
        (_after.takerBalances[0] - _before.takerBalances[0]) + // Bob received weth
        utilPriceToBuy(bobMinPrice, remaining), // What the remaining is worth at bobMinPrice
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
}

// function testFuzzMarketOrders(uint256) public {
//     uint256 r1;
//     uint256 r2;

//     uint256 max = 1e20;
//     uint256 offset = 1e8;
//     uint256 loops = 8;

//     uint256 bobWethBalanceBefore = weth.balanceOf(bob);

//     vm.startPrank(alice);
//     weth.approve(_target, type(uint256).max);
//     // weth2.approve(_target, type(uint256).max);
//     vm.stopPrank();

//     vm.startPrank(bob);
//     // weth.approve(_target, type(uint256).max);
//     weth2.approve(_target, type(uint256).max);
//     vm.stopPrank();

//     uint256[] memory aliceR1 = new uint256[](loops);
//     uint256[] memory aliceR2 = new uint256[](loops);
//     uint256[] memory bobR1 = new uint256[](loops);
//     uint256[] memory bobR2 = new uint256[](loops);

//     for (uint256 i; i < loops; ++i) {
//         r1 = (_random() % max) + offset;
//         r2 = (_random() % max) + offset;

//         userOrder(alice, _weth, r1, _weth2, r2);
//         aliceR1[i] = r1;
//         aliceR2[i] = r2;
//     }

//     for (uint256 i; i < loops; ++i) {
//         r1 = (_random() % max) + offset;
//         r2 = (_random() % max) + offset;

//         userOrder(bob, _weth2, r1, _weth, r2);
//         bobR1[i] = r1;
//         bobR2[i] = r2;
//     }

//     printList(target.getMarket(_weth, _weth2), "Green Market");
//     printList(target.getMarket(_weth2, _weth), "Red Market");

//     Balances memory userBalances = Balances({
//         aliceWeth: target.userBalances(alice, _weth),
//         aliceWeth2: target.userBalances(alice, _weth2),
//         bobWeth: weth.balanceOf(bob) - bobWethBalanceBefore,
//         bobWeth2: weth2.balanceOf(bob)
//     });

//     console.log("Alice Weth  : ", userBalances.aliceWeth);
//     console.log("Alice Weth2  : ", userBalances.aliceWeth2);
//     console.log("Bob Weth  : ", userBalances.bobWeth);
//     console.log("Bob Weth2  : ", userBalances.bobWeth2);
//     console.log("- - - - - - - - - - - -");

//     (uint256 greenRemaining, uint256 greenWant, uint256 redRemaining, uint256 redWant) =
//         target.CleanMarkets(_weth, _weth2);

//     Balances memory randomBalances;
//     // aliceWeth = sum of aliceR1 values or pay amounts
//     // aliceWeth2 = sum of aliceR2 values or want amounts
//     // bobWeth = sum of bobR1 values or pay amounts
//     // bobWeth2 = sum of bobR2 values or want amounts
//     for (uint256 i; i < loops; ++i) {
//         randomBalances.aliceWeth += aliceR1[i];
//         randomBalances.aliceWeth2 += aliceR2[i];
//         randomBalances.bobWeth += bobR1[i];
//         randomBalances.bobWeth2 += bobR2[i];
//     }

//     console.log("Alice Balance Condition");
//     assertGe(target.userBalances(alice, _weth2) + greenWant + 1e3, randomBalances.aliceWeth2);
//     console.log("Bob Balance Condition");
//     assertGe(userBalances.bobWeth + redWant + 1e3, randomBalances.bobWeth2);
//     console.log("Contract Weth Balance Condition");
//     console.log("Contract Weth          : ", weth.balanceOf(_target));
//     console.log("Contract Required Weth : ", greenRemaining);
//     assertGe(weth.balanceOf(_target), greenRemaining);
//     console.log("Contract Weth2          : ", weth2.balanceOf(_target) - target.userBalances(alice, _weth2));
//     console.log("Contract Required Weth2 : ", redRemaining);
//     console.log("Contract Weth2 Balance Condition");
//     assertGe(weth2.balanceOf(_target), redRemaining);
// }
