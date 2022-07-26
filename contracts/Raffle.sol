// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Not_Enough_ETH_Entered();
error Raffle_Transfer_Failed(address winner);
error Raffle_Not_Open();
error Raffle_Not_Needed(uint256 balance, uint256 people, uint256 raffleState);

/**
    @title my first smart contract.
    @author chaofeng zhang
 */
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address private recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimestamp;
    uint256 private immutable i_interval;

    event RaffleEnter(address indexed player);
    event RequestRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinator,
        uint256 entranceFee,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimestamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Not_Enough_ETH_Entered();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_Not_Open();
        }

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /**checkData*/
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPeople = s_players.length > 0;
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;

        upkeepNeeded = (isOpen && hasBalance && hasPeople && timePassed);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_Not_Needed(
                s_players.length,
                address(this).balance,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = i_COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        recentWinner = s_players[indexOfWinner];
        s_raffleState = RaffleState.CALCULATING;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_Transfer_Failed(recentWinner);
        }

        emit WinnerPicked(recentWinner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return 1;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
