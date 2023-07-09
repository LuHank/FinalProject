// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {ERC1155} from "openzeppelin/token/ERC1155/ERC1155.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {Registry} from "./Registry.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

contract GS1155 is ERC1155, Ownable {
    uint256 public constant GOLD = 0; // 金幣
    uint256 public constant WAND = 1; // 魔杖
    uint256 public constant KNIFE = 2; // 刀
    uint256 public constant AX = 3; // 斧頭
    uint256 public constant HAMMER = 4; // 大槌
    uint256 public constant SWORD = 5; // 劍
    uint256 public constant SHIELD = 6; // 盾牌

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PRICE_PER_TOKEN = 0.0001 ether;
    uint256 public immutable START_TIME;
    bool public mintPaused;
    mapping(uint => string) public _baseTokenURI;

    bytes32 public saleMerkleRoot;
    bytes32[] public merkleProof;

    constructor(
        uint256 _startTime, 
        bool _paused, 
        string memory _name, 
        string memory _symbol
    ) ERC1155("") {
        START_TIME = _startTime;
        mintPaused = _paused;
    }

    modifier isValidMerkleProof(bytes32[] calldata _merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                _merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
    
    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    // 只允許 EOA 不允許 contract ，避免合約駭客攻擊。
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Web3 Game Station :: Cannot be called by a contract");
        _;
    }

    function mint(address _to, uint _id, uint _amount, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint _id, uint _amount, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(uint[] memory _ids, uint[] memory _amounts, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }

    function setURI(uint _id, string memory _uri) external onlyOwner {
        _baseTokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public override view returns (string memory) {
        return _baseTokenURI[_id];
    }

    function pauseMint(bool _paused) external onlyOwner {
        require(!mintPaused, "Contract paused.");
        mintPaused = _paused;
    }

    receive() external payable {}

}

contract GS721A is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PRICE_PER_TOKEN = 0.0001 ether;
    uint256 public immutable START_TIME;
    bool public mintPaused;
    string private _baseTokenURI;

    bytes32 public saleMerkleRoot;

    constructor(uint256 _startTime, bool _paused, string memory _name, string memory _symbol) ERC721A(_name, _symbol) {
        START_TIME = _startTime;
        mintPaused = _paused;
    }

    modifier isValidMerkleProof(bytes32[] calldata _merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                _merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }
    
    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    // 只允許 EOA 不允許 contract ，避免合約駭客攻擊。
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Web3 Game Station :: Cannot be called by a contract");
        _;
    }
    
    function mint(address to, uint256 quantity, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        require(!mintPaused, "Mint is paused");
        require(block.timestamp >= START_TIME, "Sale not started");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max Supply Hit");
        require(msg.value >= quantity * PRICE_PER_TOKEN, "Insufficient Funds");
        _safeMint(to, quantity);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function pauseMint(bool _paused) external onlyOwner {
        require(!mintPaused, "Contract paused.");
        mintPaused = _paused;
    }
    
    function burn(uint256 tokenId, bytes32[] calldata _merkleProof) 
        external 
        payable 
        callerIsUser 
        isValidMerkleProof(_merkleProof, saleMerkleRoot)
    {
        _burn(tokenId);
    }
    
    function getAux(address owner) view external {
        _getAux(owner);
    }

    function setAux(address owner, uint64 aux) external {
        _setAux(owner, aux);
    }

    receive() external payable {}
}

contract Web3GameStation is Registry, Ownable {
// contract Web3GameStation is Ownable {

    struct Auction {
        address offer;
        address nftAddr;
        uint128 price; 
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
        bool completed;
        bool active;
    }

    struct Bidder {
        address addr;
        address nftAddr;
        uint256 tokenId;
        uint256 amount;
        uint256 bidTime;
    }

    IERC721 public itemToken;
    GS721A public gs721A;
    GS1155 public gs1155;

    // address private owner;
    bytes32 public saleMerkleRoot;

    uint256 public tradeFee = 5;
    uint256 public constant feePercent = 100;
    Auction[] public auctions;
    Bidder[] public bidders;
    address public withdrawAddress; // 出金地址
    address public receipientAddr; // 交易手續費接收者地址

    IRegistry.NFTStandard public nftStandard;

    mapping(address => mapping(uint256 => Auction)) public NFTTokenIdToAuction; // nftAddr => tokenId => Auction
    mapping(address => Auction[]) public auctionOwner; // offerAddress => Auction
    mapping(address => mapping(uint256 => Bidder[])) public NFTTokenIdToBidder; // nftAddr => TokenId => Bidder
    
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

    constructor(
            address newResolver, 
            address payable newBeneficiary, 
            address newAdmin
        ) Registry(newResolver, newBeneficiary, newAdmin) {
    // constructor() {
        // owner = msg.sender;
    }

    modifier isValidMerkleProof(bytes32[] calldata _merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                _merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function setSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        saleMerkleRoot = merkleRoot;
    }

    // 只允許 EOA 不允許 contract ，避免合約駭客攻擊。
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Web3 Game Station :: Cannot be called by a contract");
        _;
    }

    // 設定平台出金地址
    function setWithdraw(address withdrawAddr) external onlyOwner {
        withdrawAddress = withdrawAddr;
    }


    function setReceipientAddr(address __receipientAddr) external onlyOwner {
        receipientAddr = __receipientAddr;
    }

    // 設定交易手續費
    function settradeFee(uint256 _tradeFee) external onlyOwner {
        tradeFee = _tradeFee;
    }

    /**
     * @dev 創建拍賣 - offer
     * @param _nftAddr, _tokenId, _price, _startTime, _endTime
     */
    function createAuction(
        address _nftAddr,
        uint256 _tokenId,
        uint128 _price,
        uint256 _startTime,
        uint256 _endTime
    ) public callerIsUser {
        itemToken = IERC721(_nftAddr);
        require(
            msg.sender == itemToken.ownerOf(_tokenId),
            "Should be the owner of token"
        );
        require(_startTime >= block.timestamp);
        require(_endTime >= block.timestamp);
        require(_endTime > _startTime);

        // offer's NFT 移轉到 Web3GameStation contract
        itemToken.transferFrom(msg.sender, address(this), _tokenId);

        Auction memory auction = Auction({
            offer: msg.sender,
            nftAddr: _nftAddr,
            price: _price,
            tokenId: _tokenId,
            startTime: _startTime,
            endTime: _endTime,
            highestBid: 0,
            highestBidder: address(0x0),
            completed: false,
            active: true
        });

        NFTTokenIdToAuction[_nftAddr][_tokenId] = auction;
        auctions.push(auction);

        auctionOwner[msg.sender].push(auction);

        emit AuctionStatusChange(
            _nftAddr,
            _tokenId,
            "Create",
            msg.sender,
            _price,
            address(this),
            _startTime,
            _endTime
        );
    }

    /**
     * @dev 拍賣出價
     * @param _nftAddr, _tokenId
     */
    function bidAuction(address _nftAddr, uint256 _tokenId) public payable callerIsUser {
        itemToken = IERC721(_nftAddr);
        require(isBidValid(_nftAddr, _tokenId, msg.value));
        Auction memory auction = NFTTokenIdToAuction[_nftAddr][_tokenId];
        if (block.timestamp > auction.endTime) revert();

        require(msg.sender != auction.offer, "Owner can't bid");

        uint256 highestBid = auction.highestBid;    
        address highestBidder = auction.highestBidder;  
        require(msg.value > auction.highestBid);
        
        require(
            payable(msg.sender).balance >= msg.value,
            "insufficient balance"
        );
        if (msg.value > highestBid) {
            NFTTokenIdToAuction[_nftAddr][_tokenId].highestBid = msg.value;
            NFTTokenIdToAuction[_nftAddr][_tokenId].highestBidder = msg.sender;
            if (highestBid > 0) {
                payable(highestBidder).transfer(highestBid);    // 返還上一個最高出價者
            }

            Bidder memory bidder = Bidder({
                addr: msg.sender,
                nftAddr: _nftAddr,
                tokenId: _tokenId,
                amount: msg.value,
                bidTime: block.timestamp
            });

            NFTTokenIdToBidder[_nftAddr][_tokenId].push(bidder);
            
            emit AuctionStatusChange(
                _nftAddr,
                _tokenId,
                "Bid",
                address(this),
                msg.value,
                msg.sender,
                block.timestamp,
                block.timestamp
            );
        }
    }

    /**
     * @dev 完成拍賣
     * @param _nftAddr, _tokenId
     */
    function completeAuction(address _nftAddr, uint256 _tokenId) public payable callerIsUser {
        itemToken = IERC721(_nftAddr);
        Auction memory auction = NFTTokenIdToAuction[_nftAddr][_tokenId];
        require(
            msg.sender == auction.offer,
            "Should only be called by the offer"
        );
        require(block.timestamp >= auction.endTime);
        uint256 _bidAmount = auction.highestBid;
        address _bider = auction.highestBidder;

        if (_bidAmount == 0) {
            cancelAuction(_nftAddr, _tokenId);
        } else {
            uint256 receipientAmount = (_bidAmount * tradeFee) / feePercent;  // 計算交易手續費
            uint256 offerAmount = _bidAmount - receipientAmount;   // offer 得到的金額須扣除手續費
            payable(receipientAddr).transfer(receipientAmount);  // 交易手續費轉到手續費接收者地址
            payable(auction.offer).transfer(offerAmount); // 拍賣金額轉給 offer

            // NFT 轉給出價最高者
            itemToken.transferFrom(address(this), _bider, _tokenId);
            NFTTokenIdToAuction[_nftAddr][_tokenId].completed = true;
            NFTTokenIdToAuction[_nftAddr][_tokenId].active = false;
            delete NFTTokenIdToBidder[_nftAddr][_tokenId];

            emit AuctionStatusChange(
                _nftAddr,
                _tokenId,
                "Complete",
                address(this),
                _bidAmount,
                _bider,
                block.timestamp,
                block.timestamp
            );
        }
    }

    /**
     * @dev 出價合法性
     * @param _nftAddr, _tokenId, _bidAmount
     */
    function isBidValid(address _nftAddr, uint256 _tokenId, uint256 _bidAmount)
        internal
        view
        returns (bool)
    {
        Auction memory auction = NFTTokenIdToAuction[_nftAddr][_tokenId];
        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;
        address offer = auction.offer;
        uint128 price = auction.price;

        bool withinTime = block.timestamp >= startTime && block.timestamp <= endTime;
        bool bidAmountValid = _bidAmount >= price;
        bool offerValid = offer != address(0);
        return withinTime && bidAmountValid && offerValid;
    }

    /**
     * @dev 獲得拍賣最新高價價格
     * @param _nftAddr, _tokenId
     * @return offer address, nftAddr address, price uint128, tokenId uint256, startTime uint256, endTime uint256, highestBid uint256, highestBidder address, completed bool, active bool
     */
    function getAuction(address _nftAddr, uint256 _tokenId)
        public
        view
        returns (
            address,
            address,
            uint128,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            bool,
            bool
        )
    {
        Auction memory auction = NFTTokenIdToAuction[_nftAddr][_tokenId];
        return (
            auction.offer,
            auction.nftAddr,
            auction.price,
            auction.tokenId,
            auction.startTime,
            auction.endTime,
            auction.highestBid,
            auction.highestBidder,
            auction.completed,
            auction.active
        );
    }

    /**
     * @dev 獲得最新出價資訊
     * @param _nftAddr, _tokenId
     * @return Bidder Bidder[]
     */
    function getBidders(address _nftAddr, uint256 _tokenId)
        public
        view
        returns (Bidder[] memory)
    {
        Bidder[] memory biddersOfToken = NFTTokenIdToBidder[_nftAddr][_tokenId];
        return (biddersOfToken);
    }

    /**
     * @dev 取消拍賣
     * @param _nftAddr, _tokenId
     */
    function cancelAuction(address _nftAddr, uint256 _tokenId) public callerIsUser {

        itemToken = IERC721(_nftAddr);
        Auction memory auction = NFTTokenIdToAuction[_nftAddr][_tokenId];
        require(
            msg.sender == auction.offer,
            "Auction can be cancelled only by offer."
        );
        uint256 amount = auction.highestBid;
        address bidder = auction.highestBidder;

        // NFT 轉回給 offer
        itemToken.transferFrom(address(this), msg.sender, _tokenId);

        // refund bidder
        if (amount > 0) {
            payable(bidder).transfer(amount);
        }

        NFTTokenIdToAuction[_nftAddr][_tokenId].active = false;
        delete NFTTokenIdToBidder[_nftAddr][_tokenId];
        
        emit AuctionStatusChange(
            _nftAddr,
            _tokenId,
            "Cancel",
            address(this),
            0,
            auction.offer,
            block.timestamp,
            block.timestamp
        );
    }

    /**
     * @dev 獲得當前出價資訊
     * @param _nftAddr, _tokenId
     * @return bidder address, nftAddr address, tokenId uint256, amount uint256, bidTime uint256
     */
    function getCurrentBid(address _nftAddr, uint256 _tokenId)
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 bidsLength = NFTTokenIdToBidder[_nftAddr][_tokenId].length;
        // refund bidder
        if (bidsLength > 0) {
            Bidder memory lastBid = NFTTokenIdToBidder[_nftAddr][_tokenId][bidsLength - 1];
            return (lastBid.addr, lastBid.nftAddr, lastBid.tokenId, lastBid.amount, lastBid.bidTime);
        }
        return (address(0), address(0), uint256(0), uint256(0), uint256(0));
    }

    // 獲得用戶所有拍賣資訊
    function getAuctionsOf(address _owner)
        public
        view
        returns (Auction[] memory)
    {
        Auction[] memory ownedAuctions = auctionOwner[_owner];
        return ownedAuctions;
    }

    // 獲得用戶總共有多少個拍賣
    function getAuctionsCountOfOwner(address _owner)
        public
        view
        returns (uint256)
    {
        return auctionOwner[_owner].length;
    }

    /**
     * @dev 獲得平台總共有多少拍賣
     * @return quantity uint256
     */
    function getCount() public view returns (uint256) {
        return auctions.length;
    }

    /**
     * @dev 獲得某一 NFT 總共有多少個出價
     * @param _tokenId uint ID of the auction
     */
    function getBidsCount(address _nftAddr, uint256 _tokenId) public view returns (uint256) {
        return NFTTokenIdToBidder[_nftAddr][_tokenId].length;
    }

    // 獲得合約有多少 ETH 餘額
    function totalBalance() external view returns (uint256) {
        return payable(address(this)).balance;
    }

    // 合約 ETH 餘額出金
    function withdrawFunds() external withdrawAddressOnly {
        payable(msg.sender).transfer(this.totalBalance());
    }

    modifier withdrawAddressOnly() {
        require(msg.sender == withdrawAddress, "only withdrawer can call this");
        _;
    }

    // Rent NFT

    function getE721() public {
        nftStandard = IRegistry.NFTStandard.E721;
    }

    // 注意：
    // 1. Registry.lendings: private 改成 internal 這樣繼承才能存取。
    // 2. uint32 才能轉換 bytes4
    function updateDailyRentPrice(address nftAddress, uint256 tokenID, uint256 _lendingID, uint32 _updateDailyRentPrice) external notPaused callerIsUser {
        bytes32 identifier = keccak256(abi.encodePacked(nftAddress, tokenID, _lendingID));
        IRegistry.Lending storage lending = lendings[identifier];
        require(msg.sender == lending.lenderAddress, "not lender!");
        // bytes4 相當於 16 進位的值前面再補 0 。例如 555 = 22b(16 進位) = 0x0000022b (bytes4)
        lending.dailyRentPrice = bytes4(_updateDailyRentPrice);
        lending.availableAmount = uint16(_updateDailyRentPrice);
        // IRegistry.Lending[] storage lendingPool = new IRegistry.Lending[](ownerLendings[msg.sender].length);
        for (uint i = 0; i < ownerLendings[msg.sender].length; i++) {
            IRegistry.OwnerLending storage ownerLending = ownerLendings[msg.sender][i];
            if (ownerLending.lendingID == _lendingID) {
                ownerLending.dailyRentPrice = bytes4(_updateDailyRentPrice);
            }
        }
    }

    function updateRent(address nftAddress, uint256 tokenID, uint256 _rentingID, uint16 rentAmount, uint8 rentDuration, uint32 rentedAt) external notPaused callerIsUser {
        bytes32 identifier = keccak256(abi.encodePacked(nftAddress, tokenID, _rentingID));
        IRegistry.Renting storage renting = rentings[identifier];
        require(msg.sender == renting.renterAddress, "not renter!");
        bool rentAmountUpdate = false;
        bool rentDurationUpdate = false;
        bool rentedAtUpdate = false;
        if (rentAmount > 0) {
            require(rentAmount > renting.rentAmount, "rent amount must be greater than the last amount!");
            renting.rentAmount = rentAmount;
            rentAmountUpdate = true;
        }
        if (rentDuration > 0) {
            renting.rentDuration = rentDuration;
            rentDurationUpdate = true;
        }
        if (rentedAt > 0) {
            renting.rentedAt = rentedAt;
            rentedAtUpdate = true;
        }
        for (uint i = 0; i < userRentings[msg.sender].length; i++) {
            IRegistry.UserRenting storage userRenting = userRentings[msg.sender][i];
            if (userRenting.rentingID == _rentingID) {
                if (rentAmountUpdate) {
                    userRenting.rentAmount = rentAmount;
                }
                if (rentDurationUpdate) {
                    userRenting.rentDuration = rentDuration;
                }
                if (rentedAtUpdate) {
                    userRenting.rentedAt = rentedAt;
                }
            }
        }
    }

    function getOwnerLending(address owner) public returns(OwnerLending[] memory) {
        return ownerLendings[owner];
    }

    function getUserRenting(address user) public returns(UserRenting[] memory) {
        return userRentings[user];
    }

    fallback() external payable {}
}