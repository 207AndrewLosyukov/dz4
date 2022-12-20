// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.3;
 
contract LosGame {
 
    struct PlayerOfGame {
        uint256 ready;
        uint256 playerSymbol;
        bytes32 step;
        address payable playerAddress;
    }
 
    event Added(address player);
    event Show(address player);
    event ShowToOtherPlayers(address player, uint256 playerSymbol);
    event GetReward(address player, uint amount);
 
 
    uint public valueOfGame = 0;
        PlayerOfGame player1 = PlayerOfGame(1, 0, 0x0, payable(address(0x0)));
        PlayerOfGame player2 = PlayerOfGame(1, 0, 0x0, payable(address(0x0)));
 
    modifier canAddPlayer() {
        require(
            (player1.playerAddress == payable(address(0x0)) ||
             player2.playerAddress == payable(address(0x0))) &&
                (player1.ready == 1 || player2.ready == 1) &&
                (player1.step == 0x0 || player2.step == 0x0) && 
                (player1.playerSymbol == 0 || player2.playerSymbol == 0)
                );
 
        _;
    }
 
     modifier gameReward() {
 
        require(msg.value > 0);
 
        _;
    }

    modifier canShow() {
        require((player1.playerAddress != payable(address(0x0)) 
        && player2.playerAddress != payable(address(0x0))) &&
                (player1.playerSymbol == 0 && player2.playerSymbol == 0) &&
                (player1.step == 0x0 
                || player2.step == 0x0) && 
                (player1.ready == 2
                 || player2.ready == 2));
        _;
    }
 
    function addPlayer() public payable canAddPlayer gameReward returns (uint256) {
        if (player1.ready == 1) {
 
            if (player2.ready == 1){
                valueOfGame = msg.value;
 
            } else {
                require(valueOfGame == msg.value, "invalid value");
            }
            player1.playerAddress = payable(msg.sender);
 
            player1.ready = 2;
            emit Added(msg.sender);
            return 1;
        } else if (player2.ready == 1) {
 
            if (player1.ready == 1){
                valueOfGame = msg.value;
 
            } else {
                require(valueOfGame == msg.value, "invalid value");
            }
            player2.playerAddress = payable(msg.sender);
            player2.ready = 2;
 
 
 
            emit Added(msg.sender);
            return 2;
        }
 
        return 0;
    }

    modifier isPlayer() {
        require (msg.sender == player1.playerAddress || msg.sender == player2.playerAddress);
 
        _;
    }
 
    function startShowing(bytes32 step) public canShow isPlayer returns (bool) {
        if (msg.sender == player1.playerAddress && player1.step == 0x0) {
            player1.step = step;
            player1.ready = 3;
        } else if (msg.sender == player2.playerAddress && player2.step == 0x0) {
            player2.step = step;
            player2.ready = 3;
        } else {
            return false;
        }
        emit Show(msg.sender);
        return true;
    }
 
    modifier playersReady() {
        require((player1.playerSymbol == 0 || player2.playerSymbol == 0) &&
                (player1.step != 0x0 && player2.step != 0x0) && 
                (player1.ready == 3 || player2.ready == 3));
        _;
    }
 
    function getingResults(uint256 playerSymbol, string calldata pad) public playersReady isPlayer returns (bool) {
        if (msg.sender == player1.playerAddress) {
            require(sha256(abi.encodePacked(msg.sender, playerSymbol, pad)) == player1.step, "exception");
 
 
            player1.playerSymbol = playerSymbol;
            player1.ready = 4;
 
            emit ShowToOtherPlayers(msg.sender, playerSymbol);
            return true;
        } else if (msg.sender == player2.playerAddress){
            require(sha256(abi.encodePacked(msg.sender, playerSymbol, pad)) == player2.step, "exception");
            player2.playerSymbol = playerSymbol;
 
            player2.ready = 4;
 
            emit ShowToOtherPlayers(msg.sender, playerSymbol);
            return true;
        }
        return false;
    }
 
 
    modifier canGetReward() {
        require((player1.playerSymbol != 0 && player2.playerSymbol != 0) 
                &&
                (player1.step != 0x0 && player2.step != 0x0) 
                &&
                (player1.ready == 4 && player2.ready == 4));
        _;
    }
 
    function finishThis() private {
        player1 = PlayerOfGame(1, 0, 0x0, payable(address(0x0)));
        player2 = PlayerOfGame(1, 0, 0x0, payable(address(0x0)));
 
        valueOfGame = 0;
    }

    function endRound() public canGetReward isPlayer returns (uint) {
        if (player1.playerSymbol == player2.playerSymbol) {
            address payable firstAddress = player1.playerAddress;
 
            address payable secondAddress = player1.playerAddress;
 
            uint amount = valueOfGame;
            finishThis();
            firstAddress.transfer(amount);
            secondAddress.transfer(amount);
 
            emit GetReward(firstAddress, amount);
            emit GetReward(secondAddress, amount);
            return 0;
        } else if ((
            player1.playerSymbol == 1 && player2.playerSymbol == 3) ||
                   (player1.playerSymbol == 2 && player2.playerSymbol == 1)     ||
                   (player1.playerSymbol == 3 && player2.playerSymbol == 2)) {
            address payable addressToReward = player1.playerAddress;
            uint amount = 2 * valueOfGame;
 
            finishThis();
 
            addressToReward.transfer(amount);
            emit GetReward(addressToReward, amount);
            return 1;
        } else {
            address payable addressToReward = player2.playerAddress;
 
            uint amount = 2 * valueOfGame;
            finishThis();
            addressToReward.transfer(amount);
            emit GetReward(addressToReward, amount);
            return 2;
        }
    }
}