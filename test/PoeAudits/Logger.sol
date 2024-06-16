// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { OrdersLib, Properties } from "./Properties.sol";
import { Utils } from "./Utils.sol";
import { console2 as console } from "lib/forge-std/src/Test.sol";

abstract contract Logger is Properties, Utils {
  /*//////////////////////////////////////////////////////////////
                        Project Methods
  //////////////////////////////////////////////////////////////*/
  using OrdersLib for OrdersLib.Order;

  function printId(uint256 orderId) internal view {
    OrdersLib.Order memory order = target.GetOrder(orderId);
    uint256 buy_amount = target.GetBuyAmount(orderId);
    bytes32 marketIdentifier = target.getMarket(order.pay_token, order.buy_token);

    console.log(fixedLength("Order     : "), orderId);
    console.log("{");
    console.log(fixedLength("Price     : "), order.price);
    console.log(fixedLength("Pay Amount: "), order.pay_amount);
    console.log(fixedLength("Buy Amount: "), buy_amount);
    console.log(fixedLength("Pay Token : "), order.pay_token);
    console.log(fixedLength("Buy Token : "), order.buy_token);
    console.log(fixedLength("Owner     : "), order.owner);

    console.log("Market    : ");
    console.logBytes32(marketIdentifier);
    console.log("}");
    console.log("");
  }

  function printList(bytes32 market, string memory id) internal view {
    console.logString(id);
    uint256[] memory lst = target.GetMarketList(market);
    for (uint256 i; i < lst.length; ++i) {
      printId(lst[i]);
    }
    console.logString("");
  }

  /*//////////////////////////////////////////////////////////////
                    General Methods
  //////////////////////////////////////////////////////////////*/
  function printBreak() internal pure {
    console.log("");
    console.log("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
    console.log("");
  }

  function fixedLength(string memory s) internal pure returns (string memory) {
    uint256 len = 40;
    bytes memory b = abi.encodePacked(s);
    if (b.length > len) {
      return s;
    }
    uint256 spacesNeeded = len - b.length;

    if (spacesNeeded > 0) {
      // Only add spaces if necessary
      bytes memory spaces = new bytes(spacesNeeded);
      for (uint256 i = 0; i < spacesNeeded; i++) {
        spaces[i] = " "; // Fill the spaces byte array with spaces
      }
      bytes memory resultBytes = abi.encodePacked(b, spaces);

      return string(resultBytes);
    }
  }

  /*//////////////////////////////////////////////////////////////
                        Outside Methods
  //////////////////////////////////////////////////////////////*/
  /// @dev From Solmate
  function toString(uint256 value) internal pure returns (string memory str) {
    /// @solidity memory-safe-assembly
    assembly {
      // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
      // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
      // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
      let newFreeMemoryPointer := add(mload(0x40), 160)

      // Update the free memory pointer to avoid overriding our string.
      mstore(0x40, newFreeMemoryPointer)

      // Assign str to the end of the zone of newly allocated memory.
      str := sub(newFreeMemoryPointer, 32)

      // Clean the last word of memory it may not be overwritten.
      mstore(str, 0)

      // Cache the end of the memory to calculate the length later.
      let end := str

      // We write the string from rightmost digit to leftmost digit.
      // The following is essentially a do-while loop that also handles the zero case.
      // prettier-ignore
      for { let temp := value } 1 { } {
        // Move the pointer 1 byte to the left.
        str := sub(str, 1)

        // Write the character to the pointer.
        // The ASCII index of the '0' character is 48.
        mstore8(str, add(48, mod(temp, 10)))

        // Keep dividing temp until zero.
        temp := div(temp, 10)

        // prettier-ignore
        if iszero(temp) { break }
      }

      // Compute and cache the final total length of the string.
      let length := sub(end, str)

      // Move the pointer 32 bytes leftwards to make room for the length.
      str := sub(str, 32)

      // Store the string's length at the start of memory allocated for our string.
      mstore(str, length)
    }
  }

  /**
   * @dev Returns true if the two strings are equal. Credit @OpenZeppelin
   */
  function equal(string memory a, string memory b) internal pure returns (bool) {
    return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
  }
}
