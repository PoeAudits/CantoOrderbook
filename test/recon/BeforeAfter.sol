// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { Setup } from "./Setup.sol";
import "test/recon/Structs.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {



  Vars internal _before;
  Vars internal _after;

  UserBalances internal _beforeBalances;
  UserBalances internal _afterBalances;

  ContractBalances internal _beforeContractBalances;
  ContractBalances internal _afterContractBalances;

  // _before.placeholder = target.placeholder();
  function __before() internal { }
  function __before() internal { }



  // function __beforeBalances() internal {
  //   _beforeBalances.aliceBalance.balanceOne = tokenOne.balanceOf(alice);
  //   _beforeBalances.aliceBalance.balanceTwo = tokenTwo.balanceOf(alice);
  //   _beforeBalances.aliceBalance.balanceThree = tokenThree.balanceOf(alice);

  //   _beforeBalances.bobBalance.balanceOne = tokenOne.balanceOf(bob);
  //   _beforeBalances.bobBalance.balanceTwo = tokenTwo.balanceOf(bob);
  //   _beforeBalances.bobBalance.balanceThree = tokenThree.balanceOf(bob);

  //   _beforeBalances.carlBalance.balanceOne = tokenOne.balanceOf(carl);
  //   _beforeBalances.carlBalance.balanceTwo = tokenTwo.balanceOf(carl);
  //   _beforeBalances.carlBalance.balanceThree = tokenThree.balanceOf(carl);
    
  //   uint256[] memory tempBalances = target.GetUserBalances(alice, tokens);
  //   _beforeContractBalances.targetAliceBalance.balanceOne = tempBalances[0];
  //   _beforeContractBalances.targetAliceBalance.balanceTwo = tempBalances[1];
  //   _beforeContractBalances.targetAliceBalance.balanceThree = tempBalances[2];

  //   tempBalances = target.GetUserBalances(bob, tokens);
  //   _beforeContractBalances.targetBobBalance.balanceOne = tempBalances[0];
  //   _beforeContractBalances.targetBobBalance.balanceTwo = tempBalances[1];
  //   _beforeContractBalances.targetBobBalance.balanceThree = tempBalances[2];

  //   tempBalances = target.GetUserBalances(carl, tokens);
  //   _beforeContractBalances.targetCarlBalance.balanceOne = tempBalances[0];
  //   _beforeContractBalances.targetCarlBalance.balanceTwo = tempBalances[1];
  //   _beforeContractBalances.targetCarlBalance.balanceThree = tempBalances[2];
  // }

  // function __afterBalances() internal {
  //   _afterBalances.aliceBalance.balanceOne = tokenOne.balanceOf(alice);
  //   _afterBalances.aliceBalance.balanceTwo = tokenTwo.balanceOf(alice);
  //   _afterBalances.aliceBalance.balanceThree = tokenThree.balanceOf(alice);

  //   _afterBalances.bobBalance.balanceOne = tokenOne.balanceOf(bob);
  //   _afterBalances.bobBalance.balanceTwo = tokenTwo.balanceOf(bob);
  //   _afterBalances.bobBalance.balanceThree = tokenThree.balanceOf(bob);

  //   _afterBalances.carlBalance.balanceOne = tokenOne.balanceOf(carl);
  //   _afterBalances.carlBalance.balanceTwo = tokenTwo.balanceOf(carl);
  //   _afterBalances.carlBalance.balanceThree = tokenThree.balanceOf(carl);

  //   uint256[] memory tempBalances = target.GetUserBalances(alice, tokens);
  //   _afterContractBalances.targetAliceBalance.balanceOne = tempBalances[0];
  //   _afterContractBalances.targetAliceBalance.balanceTwo = tempBalances[1];
  //   _afterContractBalances.targetAliceBalance.balanceThree = tempBalances[2];

  //   tempBalances = target.GetUserBalances(bob, tokens);
  //   _afterContractBalances.targetBobBalance.balanceOne = tempBalances[0];
  //   _afterContractBalances.targetBobBalance.balanceTwo = tempBalances[1];
  //   _afterContractBalances.targetBobBalance.balanceThree = tempBalances[2];

  //   tempBalances = target.GetUserBalances(carl, tokens);
  //   _afterContractBalances.targetCarlBalance.balanceOne = tempBalances[0];
  //   _afterContractBalances.targetCarlBalance.balanceTwo = tempBalances[1];
  //   _afterContractBalances.targetCarlBalance.balanceThree = tempBalances[2];
  //  }
}
