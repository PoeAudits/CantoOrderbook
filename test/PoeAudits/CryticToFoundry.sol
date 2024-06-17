// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { TargetFunctions } from "./TargetFunctions.sol";
import { Test, console2 as console } from "lib/forge-std/src/Test.sol";

import { FoundryAsserts } from "lib/chimera/src/FoundryAsserts.sol";
import { OrdersLib } from "src/Libraries/OrdersLib.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
  using OrdersLib for OrdersLib.Order;

  function setUp() public {
    setup();

    targetContract(address(target));
  }

  function test_init() public view {
    console.log("Implementation: ", _imp);
    console.log("Proxy: ", _proxy);
    console.log("Target: ", _target);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                        Make Order                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     Make Order Behalf                      */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function test_make_order_behalf() public {
    maker = _alice;
    taker = _bob;

    __before();
    vm.prank(_alice);
    uint256 orderId = target.makeOrderOnBehalf(_tokens[0], 1e18, _tokens[1], 2e18, taker);
    __after();

    OrdersLib.Order memory order = target.GetOrder(orderId);

    assertEq(order.owner, _bob, "Bob Not Owner");
    assertEq(order.pay_amount, 1e18, "Wrong Amount");
    assertEq(order.buy_token, _tokens[1], "Wrong Tokens");
    assertEq(_after.takerOrderSize - _before.takerOrderSize, 1, "UserOrders Wrong Update");
    assertEq(_before.makerBalances[0] - _after.makerBalances[0], 1e18, "Alice Did Not Pay");
    assertEq(_before.makerBalances[1] - _after.makerBalances[1], 0, "Alice Wrong Token");
    assertEq(_before.takerBalances[0] - _after.takerBalances[0], 0, "Bob Balance Change 0");
    assertEq(_before.takerBalances[1] - _after.takerBalances[1], 0, "Bob Balance Change 1");
  }

  function test_make_order_behalf_self() public {
    maker = _alice;
    taker = _bob;

    __before();
    vm.prank(_alice);
    uint256 orderIdFirst = target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 2e18);

    vm.prank(_alice);
    uint256 orderIdSecond = target.makeOrderOnBehalf(_tokens[0], 1e18, _tokens[1], 2e18, maker);
    __after();

    OrdersLib.Order memory orderFirst = target.GetOrder(orderIdFirst);
    OrdersLib.Order memory orderSecond = target.GetOrder(orderIdSecond);

    assertEq(orderFirst.price, orderSecond.price, "Price");
    assertEq(orderFirst.pay_amount, orderSecond.pay_amount, "Pay Amount");
    assertEq(orderFirst.pay_token, orderSecond.pay_token, "Buy Token");
    assertEq(orderFirst.buy_token, orderSecond.buy_token, "Buy Token");
    assertEq(orderFirst.owner, orderSecond.owner, "Owner");
    assertEq(orderFirst.data, orderSecond.data, "Data");

    assertEq(_after.makerOrderSize - _before.makerOrderSize, 2, "Order Size Error");
    assertEq(_before.makerBalances[0] - _after.makerBalances[0], 2e18, "Alice Balance Error");
  }

  function test_make_order_behalf_address_zero() public {
    vm.expectRevert(bytes4(0xaf610693)); // InvalidOrder()
    vm.prank(_alice);
    uint256 orderId = target.makeOrderOnBehalf(_tokens[0], 1e18, _tokens[1], 2e18, address(0));
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     Market Buy                             */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function test_fuzz_market_buy(uint96 r1, uint96 r2) public {
    fuzz_market_buy(r1, r2);
  }

  function test_fuzz_market_buy_1() public {
    showLogs = true;
    fuzz_market_buy(
      115_792_089_237_316_195_423_570_985_008_048_500_886_937_714_638_926_451_925_144_210_186_813_659_138_104,
      115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_576_007_913_129_639_936
    );
  }

  function test_fuzz_market_buy_2() public {
    showLogs = true;
    fuzz_market_buy(
      228,
      35_915_041_164_440_816_374_939_780_094_570_207_331_879_234_708_433_247_878_511_034_042_074_554_040_988
    );
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    Cancel Order                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function test_fuzz_cancel_order(uint96 r1, uint96 r2) public {
    fuzz_cancel_order(r1, r2);
  }

  function test_fuzz_cancel_order_1() public {
    fuzz_market_buy(
      39_123_005_385_198_130_189_701_652_680_834_820_149_563_279_462_715_179_642_345_952_871_345_255_966_154,
      97_214_873_794_808_545_137_783_655_570_754_834_902_092_925_560_040_351_160_420_198_952_872_813_846_388
    );
    fuzz_cancel_order(1_878_780_235_102_308_218_960_017, 420);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                    Flush Market                            */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  function test_owner_flush_market() public {
    maker = _alice;
    taker = _bob;

    uint256[] memory orderIds = new uint256[](3);

    vm.prank(_alice);
    orderIds[0] = target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1e18);
    vm.prank(_alice);
    orderIds[1] = target.makeOrderSimple(_tokens[0], 1.5e18, _tokens[1], 1.2e18);
    vm.prank(_bob);
    target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1.1e18);
    vm.prank(_bob);
    orderIds[2] = target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1.5e18);

    bytes32 market = target.getMarket(_tokens[0], _tokens[1]);
    __before();
    vm.prank(_admin);
    target.ownerFlushMarket(market, orderIds);
    __after();

    eq(
      _after.targetBalances[0][0] - _before.targetBalances[0][0], 2.5e18, "Alice Flush Balance Fail"
    );
    eq(_after.targetBalances[0][1] - _before.targetBalances[0][1], 1e18, "Bob Flush Balance Fail");
    eq(_before.makerOrderSize - _after.makerOrderSize, 2, "Alice Order Size Fail");
    eq(_before.takerOrderSize - _after.takerOrderSize, 1, "Bob Order Size Fail");
  }

  function test_owner_flush_market_reverts() public {
    maker = _alice;
    taker = _bob;

    uint256[] memory orderIds = new uint256[](3);

    vm.prank(_alice);
    orderIds[0] = target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1e18);
    vm.prank(_alice);
    orderIds[1] = target.makeOrderSimple(_tokens[0], 1.5e18, _tokens[1], 1.2e18);
    vm.prank(_bob);
    target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1.1e18);
    vm.prank(_bob);
    target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1.5e18);
    vm.prank(_bob);
    uint256 wrongMarket = target.makeOrderSimple(_tokens[1], 1e18, _tokens[0], 1.5e18);

    bytes32 market = target.getMarket(_tokens[0], _tokens[1]);

    orderIds[2] = orderIds[1]; // Duplicates
    vm.expectRevert(bytes4(0xc5723b51)); // NotFound()
    vm.prank(_admin);
    target.ownerFlushMarket(market, orderIds);

    orderIds[2] = wrongMarket; // Order in different market

    vm.expectRevert(bytes4(0xc5723b51)); // NotFound()
    vm.prank(_admin);
    target.ownerFlushMarket(market, orderIds);
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         Withdraw                           */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  function test_withdraw_many_duplicates() public {
    vm.startPrank(_alice);
    target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 2e18);
    target.makeOrderSimple(_tokens[0], 1e18, _tokens[1], 1.5e18);
    vm.stopPrank();

    vm.prank(_bob);
    target.marketBuy(_tokens[1], 2e18, _tokens[0], 1e18);

    address[] memory withdrawTokens = new address[](6);
    withdrawTokens[0] = _tokens[0];
    withdrawTokens[1] = _tokens[1];
    withdrawTokens[2] = _tokens[0];
    withdrawTokens[3] = _tokens[1];
    withdrawTokens[4] = _tokens[0];
    withdrawTokens[5] = _tokens[1];

    __before();
    vm.prank(_alice);
    target.withdrawMany(withdrawTokens);
    __after();

    eq(2e18, _after.makerBalances[1] - _before.makerBalances[1], "Alice Withdrew Extra");
  }
}
