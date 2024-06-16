// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { PublicMarket } from "src/PublicMarket.sol";


contract Deploy is Script {
  PublicMarket public market;

  function setUp() public { }

  function run() public {
    vm.broadcast();
    market = new PublicMarket();

    
  }
}
