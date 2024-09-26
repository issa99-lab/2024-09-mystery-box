// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "lib/forge-std/src/console2.sol";
import {Test, console2} from "lib/forge-std/src/Test.sol";
import {ERC20Mock} from "../src/ERC20Mock.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxTest is Test {
    MysteryBox public mysteryBox;
    address public owner = makeAddr("owner");
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    ERC20Mock public usdc;
    uint256 seedValue = 0.2 ether;

    function setUp() public {
        usdc = new ERC20Mock();
        usdc.mint(owner, 2 ether);
        usdc.mint(user1, 1 ether);
        usdc.mint(user2, 1 ether);

        vm.prank(owner);
        mysteryBox = new MysteryBox{value: seedValue}();
        console2.log("Reward Pool Length:", mysteryBox.getRewardPool().length);
        console2.log("Bal:", mysteryBox.balance());
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(mysteryBox.owner(), owner);
    }

    function testSetBoxPrice() public {
        uint256 newPrice = 0.2 ether;
        mysteryBox.setBoxPrice(newPrice);
        assertEq(mysteryBox.boxPrice(), newPrice);
    }

    function testSetBoxPrice_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can set price");
        mysteryBox.setBoxPrice(0.2 ether);
    }

    function testAddReward() public {
        mysteryBox.addReward("Diamond Coin", 2 ether);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewardPool();
        assertEq(rewards.length, 5);
        assertEq(rewards[3].name, "Diamond Coin");
        assertEq(rewards[3].value, 2 ether);
    }

    function testAddReward_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can add rewards");
        mysteryBox.addReward("Diamond Coin", 2 ether);
    }

    function testBuyBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        assertEq(mysteryBox.boxesOwned(user1), 1);
    }

    function testBuyBox_IncorrectETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Incorrect ETH sent");
        mysteryBox.buyBox{value: 0.05 ether}();
    }

    function testOpenBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console2.log("Before Open:", mysteryBox.boxesOwned(user1));
        vm.prank(user1);
        mysteryBox.openBox();
        console2.log("After Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 0);

        vm.prank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);
    }

    function testOpenBox_NoBoxes() public {
        vm.prank(user1);
        vm.expectRevert("No boxes to open");
        mysteryBox.openBox();
    }

    function testTransferReward_InvalidIndex() public {
        vm.prank(user1);
        vm.expectRevert("Invalid index");
        mysteryBox.transferReward(user2, 0);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        console2.log("Owner Balance Before:", ownerBalanceBefore);
        vm.prank(owner);
        mysteryBox.withdrawFunds();
        uint256 ownerBalanceAfter = owner.balance;
        console2.log("Owner Balance After:", ownerBalanceAfter);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.1 ether);
    }

    function testWithdrawFunds_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can withdraw");
        mysteryBox.withdrawFunds();
    }

    function testChangeOwner() public {
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testChangeOwner_AccessControl() public {
        vm.prank(user1);
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }
}
