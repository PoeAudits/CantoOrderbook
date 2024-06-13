// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {MockERC20} from "src/Mocks/MockERC20.sol";
import {PublicMarketHarness} from "src/Harness/PublicMarketHarness.sol";
import "test/recon/Structs.sol";

contract Actor {
    PublicMarketHarness internal target;

    MockERC20 internal tokenOne;
    MockERC20 internal tokenTwo;
    MockERC20 internal tokenThree;

    constructor(address _target, address _tokenOne, address _tokenTwo, address _tokenThree) {
        tokenOne = MockERC20(_tokenOne);
        tokenTwo = MockERC20(_tokenTwo);
        tokenThree = MockERC20(_tokenThree);

        tokenOne.mint(1e30);
        tokenOne.mint(1e30);
        tokenOne.mint(1e21);
    }

    function publicMarket_makeOrderSimple(address pay_tkn, uint256 pay_amt, address buy_tkn, uint256 buy_amt) public {
        target.makeOrderSimple(pay_tkn, pay_amt, buy_tkn, buy_amt);
    }

    
}