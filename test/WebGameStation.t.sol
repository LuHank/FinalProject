//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./interface.sol";
import {GS721A} from "../src/Web3GameStation.sol";
import {GS1155} from "../src/Web3GameStation.sol";
import {Web3GameStation} from "../src/Web3GameStation.sol";

contract WebGameStationTest is Test {
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address userAdmin;
    address heavenGame2;
    address user1;
    address user2;

    GS721A gs721A;
    GS1155 gs1155;
    Web3GameStation web3GameStation;
    bytes32 merkleRoot = 0x162c84fc10af443b77bd74cac127562c7a1650d940ea850ca4017152863d8281;
    bytes32[] merkleProof;

    function setUp() public {
        userAdmin = makeAddr("userAdmin");
        heavenGame2 = makeAddr("heavenGame2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        console.log("userAdmin: ", userAdmin);
        console.log("heavenGame2: ", heavenGame2);

        vm.startPrank(userAdmin);
        gs721A = new GS721A(1688479116, false, "heavenGame2", "HEAVEN2");
        gs721A.setSaleMerkleRoot(merkleRoot);
        gs1155 = new GS1155(1688479116, false, "heavenGame2-1155", "HEAVEN2-1155");
        gs1155.setSaleMerkleRoot(merkleRoot);
        web3GameStation = new Web3GameStation();
        web3GameStation.setSaleMerkleRoot(merkleRoot);
        merkleProof.push(0xcf35cc271f7afbaa4ae6d57c87db8efc82e3badbbccf985b1034cff2126b3f2a);

        web3GameStation.setReceipientAddr(address(web3GameStation));
        web3GameStation.setWithdraw(userAdmin);
        vm.stopPrank();
        deal(address(userAdmin), 100 ether);
        deal(address(heavenGame2), 100 ether);
        deal(address(user1), 10 ether);
        deal(address(user2), 10 ether);
    }

    function testMint() public {
        // vm.startPrank(user1);
        // gs721A.mint(heavenGame2, 5, merkleProof);
        // vm.stopPrank();
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479116);
        gs721A.mint{value: 0.0005 ether}(heavenGame2, 5, merkleProof);
        console.log("heavenGame2 nft balance of: ", gs721A.balanceOf(address(heavenGame2)));
        gs1155.mint(heavenGame2, 0, 10, merkleProof);
        console.log("heavenGame2 nft-1155 balance of-0: ", gs1155.balanceOf(address(heavenGame2), 0));
        console.log("heavenGame2 nft-1155 balance of-1: ", gs1155.balanceOf(address(heavenGame2), 1));
        vm.stopPrank();
    }

    function testAuction721A() public {
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479116);
        gs721A.mint{value: 0.0001 ether}(user1, 1, merkleProof);
        vm.stopPrank();
        // create auction
        vm.startPrank(user1);
        gs721A.balanceOf(user1);
        gs721A.ownerOf(0);
        gs721A.approve(address(web3GameStation), 0);
        web3GameStation.createAuction(address(gs721A), 0, 1e18, 1688479116, 1688479200);
        web3GameStation.getAuction(address(gs721A), 0);
        vm.stopPrank();
        // bid auction
        vm.startPrank(user2);
        web3GameStation.bidAuction{value: 1 ether}(address(gs721A), 0);
        web3GameStation.getAuction(address(gs721A), 0);
        vm.stopPrank();
        // complete auction
        vm.startPrank(user1);
        vm.warp(1688479200);
        web3GameStation.completeAuction(address(gs721A), 0);
        vm.stopPrank();
        console.log("user1's NFT721A: ", gs721A.balanceOf(user1));
        console.log("user1's ETH: ", address(user1).balance);
        console.log("user2's NFT721A: ", gs721A.balanceOf(user2));
        console.log("user2's ETH: ", address(user2).balance);
        console.log("web3GameStation's NFT721A: ", gs721A.balanceOf(address(web3GameStation)));
        console.log("web3GameStation's ETH: ", address(web3GameStation).balance);
    }

    function testAuction1155() public {
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479116);
        gs1155.mint{value: 0.0001 ether}(user1, 1, 1, merkleProof);
        vm.stopPrank();
        // create auction
        vm.startPrank(user1);
        gs1155.balanceOf(user1, 0);
        gs1155.setApprovalForAll(address(web3GameStation), true);
        web3GameStation.createAuction(address(gs1155), 0, 1e18, 1688479116, 1688479200);
        web3GameStation.getAuction(address(gs1155), 0);
        vm.stopPrank();
        // bid auction
        vm.startPrank(user2);
        web3GameStation.bidAuction{value: 1 ether}(address(gs1155), 0);
        web3GameStation.getAuction(address(gs1155), 0);
        vm.stopPrank();
        // complete auction
        vm.startPrank(user1);
        vm.warp(1688479200);
        web3GameStation.completeAuction(address(gs1155), 0);
        vm.stopPrank();
        console.log("user1's NFT1155: ", gs1155.balanceOf(user1, 0));
        console.log("user1's ETH: ", address(user1).balance);
        console.log("user2's NFT1155: ", gs1155.balanceOf(user2, 0));
        console.log("user2's ETH: ", address(user2).balance);
        console.log("web3GameStation's NFT1155: ", gs1155.balanceOf(address(web3GameStation), 0));
        console.log("web3GameStation's ETH: ", address(web3GameStation).balance);
    }
}