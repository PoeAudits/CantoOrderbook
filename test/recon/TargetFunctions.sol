// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseTargetFunctions } from "lib/chimera/src/BaseTargetFunctions.sol";
import { BeforeAfter } from "./BeforeAfter.sol";
import { Properties } from "./Properties.sol";
import { vm } from "lib/chimera/src/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter { }
