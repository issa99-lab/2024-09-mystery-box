// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MysteryBox {
    address public owner;
    uint256 public boxPrice;
    mapping(address => uint256) public boxesOwned;
    mapping(address => Reward[]) public rewardsOwned;
    Reward[] public rewardPool;
    uint256 public constant SEEDVALUE = 0.1 ether;

    uint256 public gifts;

    struct Reward {
        string name;
        uint256 value;
    }

    constructor() payable {
        //uint amount, safetransfer library
        owner = msg.sender;
        boxPrice = 0.1 ether;
        require(msg.value >= SEEDVALUE, "Incorrect ETH sent");
        // Initialize with some default rewards
        rewardPool.push(Reward("Gold Coin", 0.5 ether));
        rewardPool.push(Reward("Silver Coin", 0.25 ether));
        rewardPool.push(Reward("Bronze Coin", 0.1 ether));
        rewardPool.push(Reward("Coal", 0 ether));
    }

    function setBoxPrice(uint256 _price) public {
        require(msg.sender == owner, "Only owner can set price");
        boxPrice = _price;
    }

    function addReward(string memory _name, uint256 _value) public {
        require(msg.sender == owner, "Only owner can add rewards");
        rewardPool.push(Reward(_name, _value));
    }

    function buyBox() public payable {
        require(msg.value == boxPrice, "Incorrect ETH sent");
        boxesOwned[msg.sender] += 1;
    }

    // audit Owner can open box
    function openBox() public returns (uint256) {
        require(boxesOwned[msg.sender] > 0, "No boxes to open");

        uint256 randomValue = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        ) % 100;

        // Determine the reward based on probability
        if (randomValue < 75) {
            // 75% chance to get Coal (0-74)
            rewardsOwned[msg.sender].push(Reward("Coal", 0 ether));
        } else if (randomValue >= 75 && randomValue < 95) {
            // 20% chance to get Bronze Coin (75-94)
            rewardsOwned[msg.sender].push(Reward("Bronze Coin", 0.1 ether));
        } else if (randomValue >= 95 && randomValue < 99) {
            // 4% chance to get Silver Coin (95-98)
            rewardsOwned[msg.sender].push(Reward("Silver Coin", 0.5 ether));
        } else {
            // 1% chance to get Gold Coin (99)
            rewardsOwned[msg.sender].push(Reward("Gold Coin", 1 ether));
        }

        // Decrease the number of boxes owned by the sender
        boxesOwned[msg.sender] -= 1;
        return randomValue;
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw");
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    //audit wrong!!
    function transferReward(address _to, uint256 _index) public {
        require(_index < rewardsOwned[msg.sender].length, "Invalid index"); //.length on mapping?
        rewardsOwned[_to].push(rewardsOwned[msg.sender][_index]);
        delete rewardsOwned[msg.sender][_index];
    }

    //audit !!
    function claimAllRewards() public {
        uint256 totalValue = 0;

        for (uint256 i = 0; i < rewardsOwned[msg.sender].length; i++) {
            totalValue += rewardsOwned[msg.sender][i].value;
        }
        require(totalValue > 0, "No rewards to claim");

        (bool success, ) = payable(msg.sender).call{value: totalValue}("");
        require(success, "Transfer failed");

        delete rewardsOwned[msg.sender];
    }

    //audit !!
    function claimSingleReward(uint256 _index) public {
        require(_index <= rewardsOwned[msg.sender].length, "Invalid index");
        uint256 value = rewardsOwned[msg.sender][_index].value;
        //require(value > 0, "No reward to claim");

        (bool success, ) = payable(msg.sender).call{value: value}("");
        require(success, "Transfer failed");

        delete rewardsOwned[msg.sender][_index];
    }

    function getRewards(address ply) public view returns (Reward[] memory) {
        return rewardsOwned[ply];
    }

    function getBoxesOwned() public view returns (uint) {
        return boxesOwned[msg.sender];
    }

    function getRewardPool() public view returns (Reward[] memory) {
        return rewardPool;
    }

    function changeOwner(address _newOwner) public {
        owner = _newOwner;
    }

    function getBalance() public view returns (uint256) {
        uint256 bal = address(this).balance;
        return bal;
    }

    function getPlayerGifts() public view returns (uint256) {
        return gifts;
    }
}
