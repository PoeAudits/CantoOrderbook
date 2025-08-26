// // SPDX-License-Identifier: GPL-2.0
// pragma solidity ^0.8.0;

// import { MockERC20 } from "src/Mocks/MockERC20.sol";
// import { PublicMarketHarness } from "src/Harness/PublicMarketHarness.sol";
// // import "test/recon/Structs.sol";
// import { console2 } from "lib/forge-std/src/Test.sol";

// contract Actor {
//   PublicMarketHarness internal target;

//   MockERC20 internal tokenOne;
//   MockERC20 internal tokenTwo;
//   MockERC20 internal tokenThree;

//   UserBalance internal balance;

//   constructor(address _target, address _tokenOne, address _tokenTwo, address _tokenThree) {
//     tokenOne = MockERC20(_tokenOne);
//     tokenTwo = MockERC20(_tokenTwo);
//     tokenThree = MockERC20(_tokenThree);

//     tokenOne.mint(1e30);
//     tokenTwo.mint(1e30);
//     tokenThree.mint(1e21);

//     tokenOne.approve(_target, type(uint256).max);
//     tokenTwo.approve(_target, type(uint256).max);
//     tokenThree.approve(_target, type(uint256).max);

//     target = PublicMarketHarness(_target);
//   }

//   function makeOrderSimple(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt)
//     public
//   {
//     pay_tkn.call(abi.encodeWithSignature("approve(address,uint256)", address(target), pay_amt));
//     target.makeOrderSimple(pay_tkn, pay_amt, buy_tkn, buy_amt);
//   }
// }
