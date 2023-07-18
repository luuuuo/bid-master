// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./errors/AuctionErrors.sol";
import "./events/AuctionEvents.sol";
import "./interfaces/AuctionInterface.sol";

abstract contract AbstractBasicAuction is AuctionInterface, AuctionErrors, AuctionEvents{

}