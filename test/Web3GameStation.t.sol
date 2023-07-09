//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "forge-std/Test.sol";
import "./interface.sol";
import {GS721A} from "../src/Web3GameStation.sol";
import {GS1155} from "../src/Web3GameStation.sol";
import {Web3GameStation} from "../src/Web3GameStation.sol";
import {IRegistry} from "../src/interfaces/IRegistry.sol";
import {Resolver} from "../src/Resolver.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {USDC} from "../src/payment_tokens/USDC.sol";

contract WebGameStationTest is Test {    
    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // 拍賣狀態改變事件
    event AuctionStatusChange(
        address _nftAddr,
        uint256 _tokenID,
        bytes32 _status,
        address indexed _offer,
        uint256 _price,
        address indexed _bidder,
        uint256 _startTime,
        uint256 _endTime
    );

    event Lend(
        bool is721,
        address indexed lenderAddress,
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 lendingID,
        uint8 maxRentDuration,
        bytes4 dailyRentPrice,
        uint16 lendAmount,
        uint8 paymentToken,
        bool willAutoRenew
    );

    event Rent(
        address indexed renterAddress,
        uint256 indexed lendingID,
        uint256 indexed rentingID,
        uint16 rentAmount,
        uint8 rentDuration,
        uint32 rentedAt
    );

    address userAdmin;
    address heavenGame2;
    address user1;
    address user2;

    GS721A gs721A;
    GS1155 gs1155;
    Web3GameStation web3GameStation;
    bytes32 merkleRoot = 0x162c84fc10af443b77bd74cac127562c7a1650d940ea850ca4017152863d8281;
    bytes32[] merkleProof;

    Resolver resolver;
    USDC usdc;

    function setUp() public {
        userAdmin = makeAddr("userAdmin");
        heavenGame2 = makeAddr("heavenGame2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(userAdmin, userAdmin);
        gs721A = new GS721A(1688479116, false, "heavenGame2", "HEAVEN2");
        gs721A.setSaleMerkleRoot(merkleRoot);
        gs1155 = new GS1155(1688479116, false, "heavenGame2-1155", "HEAVEN2-1155");
        gs1155.setSaleMerkleRoot(merkleRoot);
        resolver = new Resolver(userAdmin);
        usdc = new USDC();
        resolver.setPaymentToken(1, address(usdc));
        // web3GameStation = new Web3GameStation();
        web3GameStation = new Web3GameStation(address(resolver), payable(userAdmin), userAdmin);
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
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479116);
        gs721A.mint{value: 0.0005 ether}(heavenGame2, 5, merkleProof);
        gs1155.mint(heavenGame2, 0, 10, merkleProof);
        assertEq(gs721A.balanceOf(address(heavenGame2)), 5);
        assertEq(gs1155.balanceOf(address(heavenGame2), 0), 10);
        vm.stopPrank();
    }

    function testAuction721AFlow() public {
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479116);
        gs721A.mint{value: 0.0002 ether}(user1, 2, merkleProof);
        vm.stopPrank();
        assertEq(gs721A.balanceOf(user1), 2);
        assertEq(gs721A.ownerOf(0), user1);
        assertEq(gs721A.ownerOf(1), user1);
        // create auction
        vm.startPrank(user1, user1);
        gs721A.approve(address(web3GameStation), 0);
        vm.expectEmit(true, true, true, true);
        // parameters: 
        // address _nftAddr, uint256 _tokenID, bytes32 _status, address indexed _offer, uint256 _price, address indexed _bidder,
        // uint256 _startTime, uint256 _endTime
        // console.logBytes32(bytes32("Create")); // 0x4372656174650000000000000000000000000000000000000000000000000000
        emit AuctionStatusChange(address(gs721A), 0, bytes32("Create"), address(user1), 1e18, address(web3GameStation), 1688479116, 1688479200);
        web3GameStation.createAuction(address(gs721A), 0, 1e18, 1688479116, 1688479200);
        assertEq(gs721A.ownerOf(0), address(web3GameStation));
        // return 
        // offer address, nftAddr address, price uint128, tokenId uint256, startTime uint256, endTime uint256, 
        // highestBid uint256, highestBidder address, completed bool, active bool
        (address offer, address nftAddr, uint128 price, uint256 tokenId, uint256 startTime, uint256 endTime,
        uint256 highestBid, address highestBidder, bool completed, bool active) = web3GameStation.getAuction(address(gs721A), 0);
        assertEq(offer == address(user1) && nftAddr == address(gs721A) && price == 1e18 && tokenId == 0 && startTime == 1688479116
        && endTime == 1688479200 && highestBid == 0 && highestBidder == address(0) && completed == false && active == true, true);
        vm.stopPrank();

        // calcel auction
        vm.startPrank(user1, user1);
        gs721A.approve(address(web3GameStation), 1);
        web3GameStation.createAuction(address(gs721A), 1, 1e18, 1688479116, 1688479200);
        vm.expectEmit(true, true, true, true);
        emit AuctionStatusChange(address(gs721A), 1, bytes32("Cancel"), address(web3GameStation), 0, address(user1), 1688479116, 1688479116);
        web3GameStation.cancelAuction(address(gs721A), 1);
        (, , , , , , , , completed, active) = web3GameStation.getAuction(address(gs721A), 1);
        assertEq(completed == false && active == false, true);
        vm.stopPrank();
        assertEq(gs721A.ownerOf(1), user1);
        assertNotEq(gs721A.ownerOf(1), address(web3GameStation));

        // bid auction
        vm.startPrank(user2, user2);
        vm.expectEmit(true, true, true, true);
        emit AuctionStatusChange(address(gs721A), 0, bytes32("Bid"), address(web3GameStation), 1e18, address(user2), 1688479116, 1688479116);
        web3GameStation.bidAuction{value: 1 ether}(address(gs721A), 0);
        (, , , , , , highestBid, highestBidder, completed, active) = web3GameStation.getAuction(address(gs721A), 0);
        assertEq(highestBid == 1e18 && highestBidder == address(user2) && completed == false && active == true, true);
        vm.stopPrank();

        // complete auction
        vm.startPrank(user1, user1);
        cheat.warp(1688479200);
        vm.expectEmit(true, true, true, true);
        emit AuctionStatusChange(address(gs721A), 0, bytes32("Complete"), address(web3GameStation), 1e18, address(user2), 1688479200, 1688479200);
        web3GameStation.completeAuction(address(gs721A), 0);
        (, , , , , , , , completed, active) = web3GameStation.getAuction(address(gs721A), 0);
        assertEq(completed == true && active == false, true);
        vm.stopPrank();

        // NFT 流向
        assertNotEq(gs721A.ownerOf(0), user1);
        assertEq(gs721A.ownerOf(0), user2);
        assertNotEq(gs721A.ownerOf(0), address(web3GameStation));

        // ETH 流向
        uint256 tradeFee = (1e18 * web3GameStation.tradeFee() / web3GameStation.feePercent());
        assertEq(address(user2).balance, (10e18 - 1e18));
        assertEq(address(web3GameStation).balance, tradeFee);
        assertEq(address(user1).balance, (10e18 + 1e18 - tradeFee));

        // 平台出金 withdraw
        vm.startPrank(userAdmin, userAdmin);
        uint256 we3GameStationBalance = web3GameStation.totalBalance();
        uint256 userAdminBalance = address(userAdmin).balance;
        web3GameStation.withdrawFunds();
        assertEq(address(web3GameStation).balance, 0);
        assertEq(address(userAdmin).balance, we3GameStationBalance + userAdminBalance);
        vm.stopPrank();
    }



    function testLendNFT721Flow() public {
        vm.startPrank(heavenGame2, heavenGame2);
        cheat.warp(1688479200);
        gs721A.mint{value: 0.0002 ether}(user1, 2, merkleProof);
        vm.stopPrank();

        // lend
        vm.startPrank(user1, user1);
        uint256 tID = 0;
        gs721A.approve(address(web3GameStation), 0);
        web3GameStation.getE721();
        IRegistry.NFTStandard[] memory nftStandard = new IRegistry.NFTStandard[](1);
        nftStandard[0] = web3GameStation.nftStandard();
        address[] memory gs721ANFT = new address[](1);
        gs721ANFT[0] = address(gs721A);
        uint256[] memory tokenID = new uint256[](1);
        tokenID[0] = tID;
        uint256[] memory lendAmount = new uint256[](1);
        lendAmount[0] = 1;
        uint8[] memory maxRentDuration = new uint8[](1);
        maxRentDuration[0] = 1;
        bytes4[] memory dailyRentPrice = new bytes4[](1);
        dailyRentPrice[0] = 0x00000001;
        uint8[] memory paymentToken = new uint8[](1);
        paymentToken[0] = 1;
        bool[] memory willAutoRenew = new bool[](1);
        willAutoRenew[0] = true;
        // event parameter
        //   bool is721, address indexed lenderAddress, address indexed nftAddress, uint256 indexed tokenID, uint256 lendingID,
        //   uint8 maxRentDuration, bytes4 dailyRentPrice, uint16 lendAmount, uint8 paymentToken, bool willAutoRenew
        vm.expectEmit(true, true, true, true);
        emit Lend(true, user1, address(gs721A), tID, 1, 1, 0x00000001, 1, 1, true);
        // function parameter
        //   IRegistry.NFTStandard[] memory nftStandard, 
        //   address[] memory nftAddress, 
        //   uint256[] memory tokenID, 
        //   uint256[] memory lendAmount, 
        //   uint8[] memory maxRentDuration,
        //   bytes4[] memory dailyRentPrice,
        //   uint8[] memory paymentToken,
        //   bool[] memory willAutoRenew
        web3GameStation.lend(nftStandard, gs721ANFT, tokenID, lendAmount, maxRentDuration, dailyRentPrice, paymentToken, willAutoRenew);
        assertEq(gs721A.balanceOf(user1), 1);
        assertEq(gs721A.balanceOf(address(web3GameStation)), 1);
        assertEq(gs721A.ownerOf(0), address(web3GameStation));

        // updateDailyRentPrice
        // (uint8 getNftStandard, address getLenderAddress, uint8 getMaxRentDuration, bytes4 getDailyRentPrice, uint16 getLendAmount, 
        // uint16 getAvailableAmount, uint8 getPaymentToken) = web3GameStation.getLending(address(gs721A), 0, 1);
        (, , , bytes4 getDailyRentPrice, , , ) = web3GameStation.getLending(address(gs721A), 0, 1);
        uint32 beforePrice = 1;
        assertEq(getDailyRentPrice, bytes4(beforePrice));
        uint32 afterPrice = 3;
        web3GameStation.updateDailyRentPrice(address(gs721A), 0, 1, afterPrice);
        (, , , getDailyRentPrice, , , ) = web3GameStation.getLending(address(gs721A), 0, 1);
        assertEq(getDailyRentPrice, bytes4(afterPrice)); // bytes4(uint32(555)) = 0x0000022b => 16 進位的值
        web3GameStation.getOwnerLending(user1);
        vm.stopPrank();

        // Rent
        cheat.warp(1688479116);
        vm.startPrank(user2, user2);
        address USDC = address(usdc);
        deal(USDC, address(user2), 10000e6);
        uint256 dailyRent = 600;
        usdc.approve(address(web3GameStation), dailyRent);
        IRegistry.NFTStandard[] memory nftStandardRent = new IRegistry.NFTStandard[](1);
        nftStandardRent[0] = web3GameStation.nftStandard();
        address[] memory gs721ANFTRent = new address[](1);
        gs721ANFTRent[0] = address(gs721A);
        uint256[] memory tokenIDRent = new uint256[](1);
        tokenIDRent[0] = 0;
        uint256[] memory _lendingID = new uint256[](1);
        _lendingID[0] = 1;
        uint8[] memory rentDuration = new uint8[](1);
        rentDuration[0] = 1;
        uint256[] memory rentAmount = new uint256[](1);
        rentAmount[0] = 2;
        // event parameter
        //   address indexed renterAddress, uint256 indexed lendingID, uint256 indexed rentingID, uint16 rentAmount,
        //   uint8 rentDuration, uint32 rentedAt
        vm.expectEmit(true, true, true, true);
        emit Rent(user2, 1, 1, 2, 1, 1688479116);
        // function parameter
        //   IRegistry.NFTStandard[] memory nftStandard, 
        //   address[] memory nftAddress, 
        //   uint256[] memory tokenID, 
        //   uint256[] memory _lendingID, 
        //   uint8[] memory rentDuration,
        //   uint256[] memory rentAmount
        uint256 user2USDCBalance = usdc.balanceOf(user2);
        web3GameStation.rent(nftStandardRent, gs721ANFTRent, tokenIDRent, _lendingID, rentDuration, rentAmount);
        vm.stopPrank();
        assertEq(usdc.balanceOf(user2), user2USDCBalance - dailyRent);

        // updateRent
        vm.startPrank(user2, user2);
        // return
        //   address renterAddress, uint16 rentAmount, uint8 rentDuration, uint32 rentedAt
        (address renterAddressBefore, uint16 rentAmountBefore, uint8 rentDurationBefore, uint32 rentedAtBefore) = 
            web3GameStation.getRenting(address(gs721A), 0, 1);
        // parameter
        //   address nftAddress, uint256 tokenID, uint256 _rentingID, uint16 rentAmount, uint8 rentDuration, uint32 rentedAt
        web3GameStation.updateRent(address(gs721A), 0, 1, 3, 0, 0);
        (, uint16 rentAmountAfter, uint8 rentDurationAfter, uint32 rentedAtAfter) = 
            web3GameStation.getRenting(address(gs721A), 0, 1);
        assertEq(rentAmountAfter > rentAmountBefore, true);
        assertEq(rentDurationAfter == rentDurationBefore, true);
        assertEq(rentedAtAfter == rentedAtBefore, true);
        vm.stopPrank();

        // updateRent
        vm.startPrank(user1, user1);
        vm.expectRevert("not renter!");
        web3GameStation.updateRent(address(gs721A), 0, 1, 4, 0, 0);
        vm.stopPrank();

        // not allow call by contract
        vm.expectRevert("Web3 Game Station :: Cannot be called by a contract");
        web3GameStation.updateRent(address(gs721A), 0, 1, 5, 0, 0);

        // 增加一筆 lend
        vm.startPrank(user1, user1);
        gs721A.approve(address(web3GameStation), 1);
        web3GameStation.getE721();
        IRegistry.NFTStandard[] memory nftStandard2 = new IRegistry.NFTStandard[](1);
        nftStandard2[0] = web3GameStation.nftStandard();
        address[] memory gs721ANFT2 = new address[](1);
        gs721ANFT2[0] = address(gs721A);
        uint256[] memory tokenID2 = new uint256[](1);
        tokenID2[0] = 1;
        uint256[] memory lendAmount2 = new uint256[](1);
        lendAmount2[0] = 1;
        uint8[] memory maxRentDuration2 = new uint8[](1);
        maxRentDuration2[0] = 1;
        bytes4[] memory dailyRentPrice2 = new bytes4[](1);
        dailyRentPrice2[0] = 0x00000001;
        uint8[] memory paymentToken2 = new uint8[](1);
        paymentToken2[0] = 1;
        bool[] memory willAutoRenew2 = new bool[](1);
        willAutoRenew2[0] = true;
        // function parameter
        //   IRegistry.NFTStandard[] memory nftStandard, 
        //   address[] memory nftAddress, 
        //   uint256[] memory tokenID, 
        //   uint256[] memory lendAmount, 
        //   uint8[] memory maxRentDuration,
        //   bytes4[] memory dailyRentPrice,
        //   uint8[] memory paymentToken,
        //   bool[] memory willAutoRenew
        web3GameStation.lend(nftStandard2, gs721ANFT2, tokenID2, lendAmount2, maxRentDuration2, dailyRentPrice2, paymentToken2, willAutoRenew2);
        IRegistry.OwnerLending[] memory ownerLending2 = web3GameStation.getOwnerLending(user1);
        assertEq(ownerLending2.length, 2); // user1 有 2 筆 lend
        vm.stopPrank();
    }
}