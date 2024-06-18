// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ExampleFRC20Token} from "src/ExampleFRC20Token.sol";

// forge test --fork-url https://rpc.ham.fun --match-path ./test/FRC20.t.sol  -vvv
contract FRC20Test is Test {
    ExampleFRC20Token public tokenContract;

    address deployer = address(69);

    function setUp() public {
        vm.deal(deployer, 1 ether);
        vm.prank(deployer);
        tokenContract = new ExampleFRC20Token();
    }

    function testMintsMaxSupply() public view {
        assertEq(tokenContract.balanceOf(deployer), 777777777 ether);
    }

    function testDeployerAllowlist() public view {
        assertEq(tokenContract.isAllowlisted(deployer), true);
    }

}
