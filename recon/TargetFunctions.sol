// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseTargetFunctions } from "lib/chimera/src/BaseTargetFunctions.sol";
// import { BeforeAfter } from "./BeforeAfter.sol";
import { BeforeAfter, Properties } from "./Properties.sol";
import { vm } from "lib/chimera/src/Hevm.sol";

import { console as console } from "lib/forge-std/src/Test.sol";

import { Math } from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import { OrdersLib } from "src/Libraries/OrdersLib.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties {
  using OrdersLib for OrdersLib.Order;

  function harness_record_order(uint96 payAmount, uint96 buyAmount, uint256 rand) public getSender {
    (address payToken, address buyToken) = pickTokenPair(rand);
    OrdersLib.Order memory order = OrdersLib.Order({
      price: OrdersLib.buyToPrice(buyAmount, payAmount),
      pay_amount: payAmount,
      pay_token: payToken,
      buy_token: buyToken,
      owner: _alice,
      data: ""
    });
    __before(rand);
    uint256 orderId = target.HarnessRecordOrder(order);
    __after(rand);

    eq(_before.nextOrderId + 1, _after.nextOrderId, "nextOrderId Not Incremented");
    eq(_before.nextOrderId, orderId, "Wrong OrderId");
    eq(_before.userOrderSize + 1, _after.userOrderSize, "User Orders not Increasing");
    eq(_before.marketSize + 1, _after.marketSize, "Market Size Did Not Increase");
  }

  // function harness_process_buy(uint96 payAmount, uint96 buyAmount, uint256 rand) public {
  //   precondition(
  //     payAmount > 1 && payAmount < type(uint96).max / 2 && buyAmount > 1
  //       && buyAmount < type(uint96).max / 2
  //   );
  //   console.log("Pay Amount: ", payAmount);
  //   console.log("Buy Amount: ", buyAmount);
  //   (address payToken, address buyToken) = pickTokenPair(rand);
  //   OrdersLib.Order memory order = OrdersLib.Order({
  //     price: OrdersLib.buyToPrice(buyAmount, payAmount),
  //     pay_amount: payAmount,
  //     pay_token: payToken,
  //     buy_token: buyToken,
  //     owner: _alice,
  //     data: ""
  //   });
  //   uint256 selector = rand % 3;
  //   console.log("Selector: ", selector);

  //   if (selector == 0) {
  //     vm.prank(_carl);
  //     target.makeOrderSimple(buyToken, buyAmount, payToken, payAmount);
  //   } else if (selector == 1) {
  //     vm.prank(_carl);
  //     target.makeOrderSimple(buyToken, buyAmount / 2, payToken, payAmount / 2);
  //   } else if (selector == 2) {
  //     vm.prank(_carl);
  //     target.makeOrderSimple(buyToken, 2 * buyAmount, payToken, 2 * payAmount);
  //   }

  //   __before(rand);
  //   vm.prank(_alice);
  //   (bool cont, uint256 remaining, uint256 purchased) = target.HarnessProcessBuy(order);
  //   __after(rand);

  //   if (selector == 0) {
  //     t(cont, "Should Continue");
  //     lte(remaining, 1, "None Remaining");
  //     eq(purchased, buyAmount, "Filled Order");
  //     target.makeOrderSimple(buyToken, buyAmount, payToken, payAmount);
  //   } else if (selector == 1) {
  //     t(cont, "Should Continue");
  //     gte(remaining, payAmount / 2, "Remaining Insufficient");
  //     gte(purchased, buyAmount / 2, "Purchased Insufficient");
  //   } else if (selector == 2) {
  //     t(!cont, "Should Not Continue");
  //     eq(remaining, 0, "None Remaining");
  //     gte(purchased, buyAmount, "Purchased Insufficient");
  //   }
  // }

  function fuzz_market_buy(uint256) public {
    uint256 r1;
    uint256 r2;

    uint256 max = 1e15;
    uint256 offset = 1e4;
    uint256 depth = 3;

    (address t_1, address t_2) = pickTokenPair(_random());

    bytes32 greenMarket = target.getMarket(t_1, t_2);

    uint256 aliceR1Sum;
    uint256 aliceR2Sum;

    for (uint256 i; i < depth; ++i) {
      r1 = (_random() % max) + offset;
      r2 = (_random() % max) + offset;
      vm.prank(sender);
      target.makeOrderSimple(t_1, r1, t_2, r2);

      aliceR1Sum += r1;
      aliceR2Sum += r2;
    }

    printList(greenMarket, "Market");

    console.log("");
    console.log("- - - - - - - - - - - -");
    console.log("");

    r1 = (_random() % max) + offset;
    r2 = (_random() % max) + offset;

    // uint256 bobBalanceWethBefore = t_1.balanceOf(bob);
    // uint256 bobBalanceWeth2Before = t_2.balanceOf(bob);
    __before();
    vm.prank(sender);
    uint256 bobRemaining = target.marketBuy(t_2, r1, t_1, r2);
    __after();

    printList(greenMarket, "Market After ");

    (uint256 marketRemaining, uint256 marketWant,,) = target.CleanMarkets(t_1, t_2);

    // console.log("Bob Pays      : ", r1);
    // console.log("Bob Want      : ", r2);
    // console.log("Bob Remaining : ", bobRemaining);
    // console.log("");
    // console.log("Market Remain : ", marketRemaining);
    // console.log("Market Want   : ", marketWant);
    // console.log("");
    // console.log("Bob t_1       : ", weth.balanceOf(bob) - bobBalanceWethBefore);
    // console.log("Bob t_2       : ", weth2.balanceOf(bob));
    // console.log("");
    // console.log("Alice t_2     : ", target.userBalances(alice, t_2));
    // console.log("Alice r1 Sum  : ", aliceR1Sum);
    // console.log("Alice r2 Sum  : ", aliceR2Sum);

    // console.log("");
    // console.log("Alice Weth2 Condition");
    // assertGe(target.userBalances(alice, t_2) + bobRemaining, r1);
    // console.log("Bob Remaining Condition");
    // assertGe(weth.balanceOf(bob) - bobBalanceWethBefore + CalcPrice(r1, r2, bobRemaining) + depth, r2);
    // console.log("Alice MarketWant Condition");
    // assertGe(target.userBalances(alice, t_2) + marketWant + depth, aliceR2Sum);
  }
}

// function testFuzzMarketBuy(uint256) public {
//     uint256 r1;
//     uint256 r2;

//     uint256 max = 1e15;
//     uint256 offset = 1e4;
//     uint256 depth = 3;

//     bytes32 greenMarket = target.getMarket(_weth, _weth2);

//     GiveApproval(alice, _weth);
//     GiveApproval(bob, _weth2);

//     uint256 aliceR1Sum;
//     uint256 aliceR2Sum;

//     for (uint256 i; i < depth; ++i) {
//         r1 = (_random() % max) + offset;
//         r2 = (_random() % max) + offset;

//         userOrder(alice, _weth, r1, _weth2, r2);
//         aliceR1Sum += r1;
//         aliceR2Sum += r2;
//     }

//     printList(greenMarket, "Market");

//     console.log("");
//     console.log("- - - - - - - - - - - -");
//     console.log("");

//     r1 = (_random() % max) + offset;
//     r2 = (_random() % max) + offset;

//     uint256 bobBalanceWethBefore = weth.balanceOf(bob);
//     uint256 bobBalanceWeth2Before = weth2.balanceOf(bob);

//     vm.prank(bob);
//     uint256 bobRemaining = target.marketBuy(_weth2, r1, _weth, r2);

//     printList(greenMarket, "Market After ");

//     (uint256 marketRemaining, uint256 marketWant,,) = target.CleanMarkets(_weth, _weth2);

//     console.log("Bob Pays      : ", r1);
//     console.log("Bob Want      : ", r2);
//     console.log("Bob Remaining : ", bobRemaining);
//     console.log("");
//     console.log("Market Remain : ", marketRemaining);
//     console.log("Market Want   : ", marketWant);
//     console.log("");
//     console.log("Bob Weth      : ", weth.balanceOf(bob) - bobBalanceWethBefore);
//     console.log("Bob Weth2     : ", weth2.balanceOf(bob));
//     console.log("");
//     console.log("Alice Weth2   : ", target.userBalances(alice, _weth2));
//     console.log("Alice r1 Sum  : ", aliceR1Sum);
//     console.log("Alice r2 Sum  : ", aliceR2Sum);

//     console.log("");
//     console.log("Alice Weth2 Condition");
//     assertGe(target.userBalances(alice, _weth2) + bobRemaining, r1);
//     console.log("Bob Remaining Condition");
//     assertGe(weth.balanceOf(bob) - bobBalanceWethBefore + CalcPrice(r1, r2, bobRemaining) + depth, r2);
//     console.log("Alice MarketWant Condition");
//     assertGe(target.userBalances(alice, _weth2) + marketWant + depth, aliceR2Sum);
// }

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
