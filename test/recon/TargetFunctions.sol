// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseTargetFunctions } from "lib/chimera/src/BaseTargetFunctions.sol";
import { BeforeAfter } from "./BeforeAfter.sol";
import { Properties } from "./Properties.sol";
import { vm } from "lib/chimera/src/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter { 

  function publicMarket_makeOrderSimple(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt) public {
    publicMarket.makeOrderSimple(pay_tkn, pay_amt, buy_tkn, buy_amt);
  }


  function pickTokenPair(uint256 rand) internal returns(MockErc20, MockErc20) {
    rand = uint256(keccak256(abi.encode(rand - 1)));
    uint256 modulo = 6;
    if (rand % modulo == 0) {
      return (tokenOne, tokenTwo);
    } else if (rand % modulo == 1) {
      return (tokenOne, tokenThree);
    } else if (rand % modulo == 2) {
      return (tokenTwo, tokenOne);
    } else if (rand % modulo == 3) {
      return (tokenThree, tokenOne);
    } else if (rand % modulo == 4) {
      return (tokenTwo, tokenThree);
    } else if (rand % modulo == 5) {
      return (tokenThree, tokenTwo);
    }
  }

  function pickAddress(uint256 rand) internal returns(address) {
    rand = uint256(keccak256(abi.encode(rand - 2)));
    uint256 modulo = 6;
    if (rand % modulo == 0) {
      return (alice, bob);
    } else if (rand % modulo == 1) {
      return (alice, carl);
    } else if (rand % modulo == 2) {
      return (bob, alice);
    } else if (rand % modulo == 3) {
      return (carl, alice);
    } else if (rand % modulo == 4) {
      return (bob, carl);
    } else if (rand % modulo == 5) {
      return (carl, bob);
    }
  }

}
