// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../src/TwoPlayersLogic.sol";
import "./mocks/MockVRFCoordinatorV2.sol";
import "./mocks/LinkToken.sol";

contract TwoPlayersLogicTest is Test {
    LinkToken public LINK;
    MockVRFCoordinatorV2 public VRF;
    TwoPlayersLogic public tpc;

    uint96 constant D = 10**10;

    uint64 subId;
    bytes32 keyHash;

    address creator = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);

    function setUp() public {
        vm.deal(creator, 1000 ether);
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);

        LINK = new LinkToken();
        VRF = new MockVRFCoordinatorV2();

        vm.startPrank(creator);
        tpc = new TwoPlayersLogic(creator, 60, address(VRF), address(LINK), keyHash);
        vm.stopPrank();
        
        VRF.fundSubscription(tpc.subId(), 30 * 10 ** 18);
    }

    function testEvenOddWin1ButClaimWin2() public {
        uint8[3] memory move = [0, 1, 2];
        uint256 amount = 10 * D;
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.evenOdd;

        bytes32 proof = tpc.getProof("hello world");
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, id, 0, "");

        (address winnerAlice,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);

        vm.warp(61);
        address winnerBob = tpc.claim(name, room, id, 0, "");
        assertEq(winnerBob, bob);

        vm.warp(61);
        vm.expectRevert(bytes("Winner is determined"));
        tpc.claim(name, room, id, move[1], proof);
    }

    function testRockPaperScissorsWin1ButClaimWin2() public {
        uint8[3] memory move = [0, 3, 2];
        uint256 amount = 100 * D;
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.rockPaperScissors;

        bytes32 proof = tpc.getProof("hello world");
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, id, 0, "");

        (address winnerAlice,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);

        vm.warp(61);
        address winnerBob = tpc.claim(name, room, id, 0, "");
        assertEq(winnerBob, bob);

        vm.warp(61);
        vm.expectRevert(bytes("Winner is determined"));
        tpc.claim(name, room, id, move[1], proof);
    }

    function testKickDefenseWin1ButClaimWin2() public {
        uint24[3] memory move = [0, 112211, 211121];
        uint256 amount = 1000 * D;
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.kickDefense;

        bytes32 proof = tpc.getProof("hello world");
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, id, 0, "");

        (address winnerAlice,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);

        vm.warp(61);
        address winnerBob = tpc.claim(name, room, id, 0, "");
        assertEq(winnerBob, bob);

        vm.warp(61);
        vm.expectRevert(bytes("Winner is determined"));
        tpc.claim(name, room, id, move[1], proof);
    }

    function testEvenOddWin1() public {
        uint8[3] memory move = [0, 1, 2];
        uint256 amount = 1000 * D;

        bytes32 proof = tpc.getProof("hello world");
        
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.evenOdd;
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, 1, 0, "");

        (address winnerAddress,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAddress, alice);

        address winnerAlice = tpc.claim(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);
    }

    function testRockPaperScissorsWin1() public {
        uint8[3] memory move = [0, 3, 2];
        uint256 amount = 100 * D;

        bytes32 proof = tpc.getProof("hello world");
        
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.rockPaperScissors;
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, 1, 0, "");

        (address winnerAddress,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAddress, alice);

        address winnerAlice = tpc.claim(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);
    }

    function testKickDefenseWin1() public {
        uint24[3] memory move = [0, 112211, 211121];
        uint256 amount = 10 * D;

        bytes32 proof = tpc.getProof("hello world");
        
        TwoPlayersLogic.Name name = TwoPlayersLogic.Name.kickDefense;
        TwoPlayersLogic.Room room = tpc.getRoom(amount);

        vm.startPrank(alice);
        tpc.move1{value: amount}(name, tpc.getCipher(move[1], proof));
        vm.stopPrank();

        uint256 id = tpc.getId(name, room);

        vm.startPrank(bob);
        (, uint256 requestId) = tpc.move2{value: amount}(name, id, move[2]);
        vm.stopPrank();

        assertEq(address(tpc).balance, amount*2);

        uint256[] memory words = getWords(requestId);
        VRF.fulfillRandomWords(requestId, address(tpc));

        TwoPlayersLogic.Game memory game = tpc.getGame(name, room, id);

        assertEq(game.player1, alice);
        assertEq(game.player2, bob);
        assertEq(game.random, words[0]);

        vm.warp(60);
        vm.expectRevert(bytes("Result is not ready"));
        tpc.claim(name, room, 1, 0, "");

        (address winnerAddress,) = tpc.winner(name, room, id, move[1], proof);
        assertEq(winnerAddress, alice);

        address winnerAlice = tpc.claim(name, room, id, move[1], proof);
        assertEq(winnerAlice, alice);
    }

    function getWords(uint256 requestId)
        public
        pure
        returns (uint256[] memory) {
        uint256[] memory words = new uint256[](1);
        for (uint256 i = 0; i < 1; i++) {
            words[i] = uint256(keccak256(abi.encode(requestId, i)));
        }
        return words;
    }
}
