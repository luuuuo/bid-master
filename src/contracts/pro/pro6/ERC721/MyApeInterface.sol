// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface MyApeInterface {
    function mint(address _to, uint256 _tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}