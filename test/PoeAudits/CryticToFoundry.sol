// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { TargetFunctions } from "./TargetFunctions.sol";
import { Test, console2 as console } from "forge-std/Test.sol";

import { FoundryAsserts } from "lib/chimera/src/FoundryAsserts.sol";
import {OrdersLib} from "src/Libraries/OrdersLib.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
  using OrdersLib for OrdersLib.Order;
  function setUp() public {
    setup();

    targetContract(address(target));
  }

  function test_fuzz_cancel_order(uint96 r1, uint96 r2) public {
    fuzz_cancel_order(r1, r2);
  }

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

  function test_fuzz_market_buy_3() public {
    showLogs = true;
    fuzz_market_buy(0, 0);
  }

  function test_fuzz_cancel_order_1() public {
  fuzz_market_buy(39123005385198130189701652680834820149563279462715179642345952871345255966154, 97214873794808545137783655570754834902092925560040351160420198952872813846388);
  fuzz_cancel_order(1878780235102308218960017, 420);
}
}
