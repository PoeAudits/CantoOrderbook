// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {MockERC20} from "src/Mocks/MockERC20.sol";


    struct Vars {
        uint256 _unused;
    }
    struct UserBalance {
        uint96 balanceOne;
        uint96 balanceTwo;
        uint96 balanceThree;
    }

    struct Tokens {
        MockERC20 balanceOne;
        MockERC20 balanceTwo;
        MockERC20 balanceThree;
    }

    struct UserBalances {
        UserBalance aliceBalance;
        UserBalance bobBalance;
        UserBalance carlBalance;
    }

    struct ContractBalances {
        UserBalance targetBalance;
        UserBalance targetAliceBalance;
        UserBalance targetBobBalance;
        UserBalance targetCarlBalance;
    }
