// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/TwoPlayersLogic.sol";
import "../src/utils/Multicall.sol";
import "../test/mocks/MockVRFCoordinatorV2.sol";
import "../test/mocks/LinkToken.sol";

contract TwoPlayersLogicScript is Script {

    LinkToken public LINK;
    MockVRFCoordinatorV2 public VRF;
    TwoPlayersLogic public tpc;

    address CREATOR = 0x094219B1b714c4D211D45992b774accA209f9b82;
    uint256 TIME = 300;
    bytes32 keyHash = 0x0;

    function setUp() public {
        // Goerli
        // VRF = MockVRFCoordinatorV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
        // LINK = LinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        // keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

        // Mumbai
        VRF = MockVRFCoordinatorV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
        LINK = LinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

        // Localhost
        // vm.startBroadcast();
        // console.logString("-----------");
        // console.logString("LINK TOKEN:");
        // LINK = new LinkToken();
        // console.logAddress(address(LINK));
        // console.logString("-----------");
        // console.logString("VRF:");
        // VRF = new MockVRFCoordinatorV2();
        // console.logAddress(address(VRF));
        // console.logString("-----------");
        // vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast();
        console.logString("-----------");
        console.logString("Multicall:");
        Multicall mc = new Multicall();
        console.logAddress(address(mc));
        console.logString("-----------");
        console.logString("TwoPlayers:");
        TwoPlayersLogic tpl = new TwoPlayersLogic(
            CREATOR,
            TIME,
            address(VRF),
            address(LINK),
            keyHash
        );
        console.logAddress(address(tpl));
        console.logString("-----------");
        vm.stopBroadcast();
    }
}
