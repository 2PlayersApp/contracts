// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract TwoPlayersLogic is VRFConsumerBaseV2 {

    address public factory;
    address public creator;
    uint256 public time;
    uint64 public subId;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    bytes32 keyHash;
    uint256 D = 10 ** 10;

    struct Path {
        Name name;
        Room room;
        uint256 id;
    }

    enum Name {
        evenOdd,
        rockPaperScissors,
        kickDefense
    }

    enum Room {
        One,
        Ten,
        Hundred,
        Thousand
    }

    struct Game {
        uint256 id;
        address winner;
        address player1;
        address player2;
        uint256 move1;
        uint256 move2;
        uint256 time1;
        uint256 time2;
        uint256 random;
        bytes32 proof;  // keccak256("word1 word2 word3")
        bytes32 cipher; // keccak256(move1, proof)
    }

    event Move1(
        address indexed player, 
        Name name,
        Room room,
        uint256 id,
        bytes32 cipher
    );

    event Move2(
        address indexed player, 
        Name name,
        Room room,
        uint256 id,
        uint256 move,
        uint256 requestId
    );

    mapping(Name => mapping(Room => uint256)) public id;                     // Name => Room => ID++
    mapping(Name => mapping(Room => mapping(uint256 => Game))) public games; // Name => Room => ID => Game
    mapping(address => Path[]) public user;                                  // User => Games
    mapping(uint256 => Path) public requests;                                // RequestID => Path
    
    constructor(
        address creator_,
        uint256 time_,
        address vrf_,
        address link_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrf_) {
        factory = msg.sender;
        creator = creator_;
        time = time_;
        COORDINATOR = VRFCoordinatorV2Interface(vrf_);
        LINKTOKEN = LinkTokenInterface(link_);
        keyHash = keyHash_;
        createNewSubscription();
    }

    function move1(
        Name name_,
        bytes32 cipher_
    ) public payable returns(Game memory, uint256) {

        Room room = getRoom(msg.value);

        id[name_][room]++;
        user[msg.sender].push(Path(name_, room, id[name_][room]));
        games[name_][room][id[name_][room]] = Game({
            id: id[name_][room],
            winner: address(0),
            player1: msg.sender,
            player2: address(0),
            move1: 0,
            move2: 0,
            time1: block.timestamp,
            time2: 0,
            random: 0,
            proof: "",
            cipher: cipher_
        });

        emit Move1(msg.sender, name_, room, id[name_][room], cipher_);

        return (games[name_][room][id[name_][room]], id[name_][room]);
    }

    function move2(
        Name name_,
        uint256 id_,
        uint256 move_
    ) public payable returns(Game memory, uint256) {

        Room room = getRoom(msg.value);
        Game storage game = games[name_][room][id_];

        require(game.move2 == 0, "Move 2 exists");
        require(game.player1 != msg.sender, "Double move");

        user[msg.sender].push(Path(name_, room, id_));
        game.player2 = msg.sender;
        game.move2 = move_;

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subId,
            3,
            200000,
            1
        );

        requests[requestId] = Path(name_, room, id_);

        emit Move2(msg.sender, name_, room, id_, move_, requestId);

        return (game, requestId);
    }

    function winner(
        Name name_,
        Room room_,
        uint256 id_,
        uint256 move_,
        bytes32 proof_
    ) public view returns(address, uint256) {
        Game memory game = games[name_][room_][id_];
        address player;
        uint256 sec;

        if (move_ != 0) {
            bytes32 cipher = getCipher(move_, proof_);
            require(game.cipher == cipher, "Invalid proof");
        } else {
            if (block.timestamp >= game.time2 + time) {
                player = game.player2;
            } else {
                sec = (game.time2 + time) - block.timestamp;
            }
            return (player, sec);
        }

        uint256 m1 = move_;
        uint256 m2 = game.move2;

        if (name_ == Name.evenOdd) {
            if (m1 % 2 == m2 % 2) {
                if (game.random % 2 == 0) {
                    player = game.player1;
                } else {
                    player = game.player2;
                }
            } else {
                if (game.random % 2 == m1 % 2) {
                    player = game.player1;
                } else {
                    player = game.player2;
                }
            }
        } else if (name_ == Name.rockPaperScissors) {
            if (
                (m1 == 1 && m2 == 1) ||
                (m1 == 2 && m2 == 2) ||
                (m1 == 3 && m2 == 3)
            ) {
                if (game.random % 2 == 0) {
                    player = game.player1;
                } else {
                    player = game.player2;
                }
            }
            if (m1 == 1 && m2 == 2) {
                player = game.player2;
            }
            if (m1 == 1 && m2 == 3) {
                player = game.player1;
            }
            if (m1 == 2 && m2 == 1) {
                player = game.player1;
            }
            if (m1 == 2 && m2 == 3) {
                player = game.player2;
            }
            if (m1 == 3 && m2 == 1) {
                player = game.player2;
            }
            if (m1 == 3 && m2 == 2) {
                player = game.player1;
            }
        } else if (name_ == Name.kickDefense) {
            bool[] memory p1 = splitMove(m1);
            bool[] memory p2 = splitMove(m2);
            bool w1 = 
                (p2[0] && p1[3]) ||
                (p2[1] && p1[4]) ||
                (p2[2] && p1[5]);
            bool w2 = 
                (p1[0] && p2[3]) ||
                (p1[1] && p2[4]) ||
                (p1[2] && p2[5]);
            if (w1 && w2) {
                if (game.random % 2 == 0) {
                    player = game.player1;
                } else {
                    player = game.player2;
                }
            } else if (w1) {
                player = game.player1;
            } else if (w2) {
                player = game.player2;
            }
        }

        return (player, sec);
    }

    function claim(
        Name name_,
        Room room_,
        uint256 id_,
        uint256 move_,
        bytes32 proof_
    ) public returns(address) {
        Game storage game = games[name_][room_][id_];

        require(
            game.winner == address(0),
            "Winner is determined"
        );

        if (move_ != 0) {
            (address player,) = winner(name_, room_, id_, move_, proof_);
            require(
                player != address(0),
                "Claim error"
            );
            game.winner = player;
            game.proof = proof_;
            game.move1 = move_;
        } else {
            require(
                block.timestamp >= game.time2 + time,
                "Result is not ready"
            );
            game.winner = game.player2;
        }

        uint256 prize = getPrize(room_);

        uint256 fee = prize / 100;
        (bool sent,) = payable(game.winner).call{value: prize - fee - fee}("");
        require(sent, "Failed to send MATIC for winner");
        (bool sent2,) = payable(creator).call{value: fee}("");
        require(sent2, "Failed to send MATIC for creator");
        (bool sent3,) = payable(factory).call{value: fee}("");
        require(sent3, "Failed to send MATIC for factory");

        return game.winner;
    }

    function stop(
        Name name_,
        Room room_,
        uint256 id_
    ) public returns(bool) {
        Game storage game = games[name_][room_][id_];
        require(
            msg.sender == game.player1,
            "Player not found"
        );
        require(
            game.time1 + 3600 <= block.timestamp,
            "Wait 1 hour"
        );
        require(
            game.move2 == 0,
            "Move 2 exists"
        );
        require(
            game.cipher[0] != 0,
            "Cipher not exists"
        );
        game.cipher = "";
        uint256 prize = getPrize(room_) / 2;
        (bool sent,) = payable(game.player1).call{value: prize}("");
        require(sent, "Failed to send MATIC for player1");
        return sent;
    }

    function splitMove(
        uint256 move_
    ) internal pure returns (bool[] memory) {
        bool[] memory arr = new bool[](6);
        arr[0] = (move_ % 1000000 / 100000) == 2;
        arr[1] = (move_ % 100000 / 10000) == 2;
        arr[2] = (move_ % 10000 / 1000) == 2;
        arr[3] = (move_ % 1000 / 100) == 2;
        arr[4] = (move_ % 100 / 10) == 2;
        arr[5] = (move_ % 10 / 1) == 2;
        bool kickTrue = true;
        bool defenceTrue = true;
        for (uint8 i = 0; i < 3; i++) {
            if (arr[i] == true && kickTrue) {
                kickTrue = false;
            } else {
                arr[i] = false;
            }
            if (arr[i + 3] == true && defenceTrue) {
                defenceTrue = false;
            } else {
                arr[i + 3] = false;
            }
        }
        return arr;
    }

    function getRoom(uint256 value_) public view returns(Room room) {
        if (value_ == 1 * D) {
            room = Room.One;
        } else if (value_ == 10 * D) {
            room = Room.Ten;
        } else if (value_ == 100 * D) {
            room = Room.Hundred;
        } else if (value_ == 1000 * D) {
            room = Room.Thousand;
        } else {
            revert("Room 1,10,100,1000 MATIC");
        }
    }

    function getPrize(Room room_) internal view returns(uint256 prize) {
        if (room_ == Room.One) {
            prize = 2 * D;
        } else if (room_ == Room.Ten) {
            prize = 20 * D;
        } else if (room_ == Room.Hundred) {
            prize = 200 * D;
        } else if (room_ == Room.Thousand) {
            prize = 2000 * D;
        } else {
            revert("Prize 2,20,200,2000 MATIC");
        }
    }

    function getId(Name name_, Room room_) public view returns(uint256) {
        return id[name_][room_];
    }

    function getGame(Name name_, Room room_, uint256 id_) public view returns(Game memory) {
        return games[name_][room_][id_];
    }

    function getGameDesc(Name name_, Room room_, uint256 id_) public view returns(Game memory) {
        id_ = id[name_][room_] > 0 && id_ > 0 && id[name_][room_] >= id_ ? id[name_][room_] - id_ + 1 : 0;
        return games[name_][room_][id_];
    }

    function getUserGames(address user_, uint256 id_) public view returns(Path memory) {
        return user[user_][id_];
    }

    function getUserGamesDesc(address user_, uint256 id_) public view returns(Path memory) {
        id_ = user[user_].length > 0 && id_ > 0 && user[user_].length >= id_ ? user[user_].length - id_ + 1 : 0;
        return user[user_][id_];
    }

    function getCipher(uint256 move_, bytes32 proof_) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(move_, proof_));
    }

    function getProof(string calldata proof_) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(proof_));
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        Path memory r = requests[requestId];
        games[r.name][r.room][r.id].random = randomWords[0];
        games[r.name][r.room][r.id].time2 = block.timestamp;
    }

    function createNewSubscription() private {
        subId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subId, address(this));
    }

    function topUpSubscription(uint256 amount) external {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(subId));
    }

}
