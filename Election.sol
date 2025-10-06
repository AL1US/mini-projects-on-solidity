// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Voting {

    // ["Putin","Lenin","Stalin","Rasputin"] - пример того, что вводить в массив при диплое

    string[] public candidateList;

    mapping(uint256 => uint256) public votesCounter;

    mapping(address => bool) public hasVoted;

    address public owner;

    // Общее кол-во голосов включительно
    uint256 public totalVotes;
    
    // Время указывается в секундах 
    uint256 public totalTime;

    uint256 public totalVotesCounter;

    modifier ModifierElectionIsOver() {
        require(block.timestamp < totalTime, ElectionIsOver());
        require(totalVotesCounter < totalVotes, ElectionIsOver());
        _;
    }

    modifier OnlyOwnerFunc() {
        require(msg.sender == owner, OnlyOwner());
        _;
    }

    // Неверный кандидат. Сначала показываем кого выбрали, а затем показываем доступные варианты
    error InvalidCandidate(uint256 _yourCandidate, uint256 _allElectors);
    
    // Голосование заканчивается, когда достигается пиковое количество голосов или иссекает время
    error ElectionIsOver();

    error OnlyOwner();

    // Конструктор в котором выбираются кандидаты, пиковое кол-во голосов и время завершения голосования
    constructor(string[] memory _candidateList, uint256 _totalTime, uint256 _totalVotes) {
        candidateList = _candidateList;
        owner = msg.sender;
        totalVotes = _totalVotes;
        totalTime = block.timestamp + _totalTime;
    }

    function vote(uint256 _candidate) public ModifierElectionIsOver { 
        require(hasVoted[msg.sender] == false, "You have already voted");
        require(_candidate < candidateList.length, InvalidCandidate(_candidate, candidateList.length));

        hasVoted[msg.sender] = true;
        votesCounter[_candidate] ++;    
        totalVotesCounter ++;
    }

    function getAllCandidate() public view returns (string[] memory) {
        return candidateList;
    }

    function stopVoting() public OnlyOwnerFunc{
        totalTime = block.timestamp;
    }

    function resetMaxVotes(uint256 _newTotalVotes) public OnlyOwnerFunc {
        totalVotes = _newTotalVotes;
    }

    function resetMaxTime(uint256 _newMaxTime) public OnlyOwnerFunc {
        totalTime = block.timestamp + _newMaxTime;
    }    

}
