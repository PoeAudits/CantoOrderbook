// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { TargetFunctions } from "./TargetFunctions.sol";
import { Test } from "forge-std/Test.sol";

import "forge-std/console2.sol";
import { FoundryAsserts } from "lib/chimera/src/FoundryAsserts.sol";

contract CryticToFoundry is TargetFunctions, FoundryAsserts {
  function setUp() public {
    setup();

    targetContract(address(target));
  }

  function test_crytic() public {
    // TODO: add failing property tests here for debugging
  }

  // function test_fuzz_market_buy(uint256 r1, uint256 r2) public {
  //   fuzz_market_buy(r1, r2);
  // }

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
    fuzz_market_buy(
      0,
      0
    );
  }
}
