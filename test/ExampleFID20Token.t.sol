// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ExampleFID20Token} from "../src/ExampleFID20Token.sol";

contract FRC20Test is Test {
    ExampleFID20Token public tokenContract;
    address deployer = address(69);
    address user1 = address(1);
    address user2 = address(2);

    address fiduser = address(0x777c47498b42dbe449fB4cB810871A46cD777777);

    function setUp() public {
        vm.deal(deployer, 1 ether);
        vm.prank(deployer);
        tokenContract = new ExampleFID20Token();
        console.log("ExampleFRC20Token deployed at address:", address(tokenContract));
    }

    function testInitialState() view public {
        // Check deployer balance
        assertEq(tokenContract.balanceOf(deployer), 100_000_000 ether);

        // Check deployer is on the allowlist
        assertEq(tokenContract.isAllowlisted(deployer), true);
    }

    function testAllowlist() public {
        // Add user1 to allowlist
        vm.prank(deployer);
        tokenContract.setAllowlist(user1, true);
        assertEq(tokenContract.isAllowlisted(user1), true);

        // Remove user1 from allowlist
        vm.prank(deployer);
        tokenContract.setAllowlist(user1, false);
        assertEq(tokenContract.isAllowlisted(user1), false);

        // Attempt to add user2 to allowlist from a non-deployer address
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        tokenContract.setAllowlist(user2, true);

        // Verify user2 is not on the allowlist
        assertEq(tokenContract.isAllowlisted(user2), false);
    }

    function testTransferWithinAllowlist() public {
        // Add user1 and user2 to allowlist
        vm.prank(deployer);
        tokenContract.setAllowlist(user1, true);
        vm.prank(deployer);
        tokenContract.setAllowlist(user2, true);

        // Transfer tokens from deployer to user1
        vm.prank(deployer);
        tokenContract.transfer(user1, 1000 ether);
        assertEq(tokenContract.balanceOf(deployer), 100_000_000 ether - 1000 ether);
        assertEq(tokenContract.balanceOf(user1), 1000 ether);

        // Transfer tokens from user1 to user2
        vm.prank(user1);
        tokenContract.transfer(user2, 500 ether);
        assertEq(tokenContract.balanceOf(user1), 500 ether);
        assertEq(tokenContract.balanceOf(user2), 500 ether);
    }

    function testTransferNotAllowed() public {
        // Attempt transfer from deployer to non-allowlisted user1
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSignature("FID20InvalidTransfer(address)", user1));
        tokenContract.transfer(user1, 1000 ether);

        // Add user1 to allowlist but not user2
        vm.prank(deployer);
        tokenContract.setAllowlist(user1, true);

        // Transfer should succeed from deployer to user1
        vm.prank(deployer);
        tokenContract.transfer(user1, 1000 ether);
        assertEq(tokenContract.balanceOf(deployer), 100_000_000 ether - 1000 ether);
        assertEq(tokenContract.balanceOf(user1), 1000 ether);

        // Attempt transfer from user1 to non-allowlisted user2
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("FID20InvalidTransfer(address)", user2));
        tokenContract.transfer(user2, 500 ether);
    }

    function testTransferToFID() public {
        // Transfer tokens from deployer to user1
        vm.prank(deployer);
        tokenContract.transfer(fiduser, 1000 ether);
        assertEq(tokenContract.balanceOf(deployer), 100_000_000 ether - 1000 ether);
        assertEq(tokenContract.balanceOf(fiduser), 1000 ether);

        // // Transfer tokens from user1 to user2
        vm.prank(fiduser);
        tokenContract.transfer(deployer, 500 ether);
        assertEq(tokenContract.balanceOf(fiduser), 500 ether);
        assertEq(tokenContract.balanceOf(deployer), 99_999_500 ether);
    }
    
}
