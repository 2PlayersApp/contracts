// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./TwoPlayersLogic.sol";

contract TwoPlayers {

    address factory;

    address LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address VRF = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    // address VRF = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    // address LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    // bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    
    struct Game {
        address creator;
        address game;
    }

    uint256 id;
    mapping(uint256 => Game) public games;

    constructor() {
        factory = msg.sender;
    }

    function createGame(uint256 time_) public returns(uint256) {
        id++;
        TwoPlayersLogic game = new TwoPlayersLogic(msg.sender, time_, VRF, LINK, keyHash);
        games[id] = Game(msg.sender, address(game));
        return id;
    }
}
