// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AuctionNFT is ERC721, Ownable, ReentrancyGuard {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    uint256 MAX_SUPPLY = 10000;
    uint BASIC_SLIPPAGE_TOLERANCE = 2;
    /***  for production ***/
    uint256 MINT_AVAILABLE_TIME = 187200;
    uint PUBLIC_MINT_AVAILABLE_TIME = 14400;
    uint MAX_OWN_COUNT = 10;
    
    /***  for test ***/
    //uint256 MINT_AVAILABLE_TIME = 3600;
    //uint MAX_OWN_COUNT = 5;

    /**********  staging value for 
        presale (value = 1), 
        public minting (value = 2)
    *******************************/
    
    uint _stagingValue = 0;
    
    /*********** Variables for changing token price ***********/
    
    uint256 _startingPrice = 200000000000000000; // 2 * (10 ^ 17) wei
    uint256 _endingPrice = 50000000000000000; // 5 * (10 ^ 16)wei
    uint256 _startedAt; // time
    
    /************* Variables for whitelist *************/
    
    mapping(address => bool) private _whitelist;
    mapping(address => uint) private _countlist;

    event currePrice(uint256 currPrice);
    
    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price; 
    }

    mapping(uint256 => MarketItem) private idToMarketItem;    
    
    constructor() public ERC721("NFT Auction", "NFTA") payable {
        
    }

    function _tokenMint() internal {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uint2str(tokenId));     
        idToMarketItem[tokenId] =  MarketItem(
            tokenId,
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            getCurrentPrice()
        );   
    }
    
    function ownerMint() public onlyOwner {
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        _tokenMint();
    }
    
    function requestPresaleToken() external payable nonReentrant{
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        require(_stagingValue == 1, "Presale is not allowed.");
        require(_whitelist[msg.sender], "This address is not included in whitelist.");
        require(_countlist[msg.sender] < MAX_OWN_COUNT, "Overflow 10 tokens");
        require(msg.value == _endingPrice, "Invalid funds");
        _tokenMint();
        _countlist[msg.sender] = _countlist[msg.sender] + 1;
    }

    function requestPublicToken(uint mintCount) external payable nonReentrant{
        uint256 secondsPassed = 0;
        secondsPassed = now.sub(_startedAt);
        require(secondsPassed < MINT_AVAILABLE_TIME, "Minting is ended.");
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        require(mintCount > 0, "Mint count has to be more than 1.");
        require(_stagingValue == 2, "Public Minting is not allowed.");
        require(_countlist[msg.sender] + mintCount < MAX_OWN_COUNT, "Overflow 10 tokens");
        uint tolerance = BASIC_SLIPPAGE_TOLERANCE;
        if(secondsPassed > PUBLIC_MINT_AVAILABLE_TIME) {
            tolerance = 0;
        }
        uint256 limitValue = getCurrentPrice().mul(10000 - tolerance).mul(mintCount).div(10000);
        require(msg.value >= limitValue);
        for (uint256 index = 0; index < mintCount; index++) {
            _tokenMint();
            _countlist[msg.sender] = _countlist[msg.sender] + 1;
        }
    }
    
    function setWhiteList(address[] memory params) public onlyOwner{
        require(params.length > 0, "Please input whiltelist array");
        for(uint i = 0; i < params.length; i++) {
            _whitelist[params[i]] = true;
        }
    }

    function setStage(uint256 value) public onlyOwner{
        require(value >= 0, "Invalid staging value");
        require(value < 3, "Invalid staging value");
        _stagingValue = value;
        if(value == 2) {
            _startedAt = now;
        }
    }
    
    function getCurrentStage() public view returns(uint256) {
        return _stagingValue;
    }
    
    function getCurrentPrice() public view returns(uint256) {
        if(_stagingValue == 1) {
            
            return _endingPrice;
            
        } else if(_stagingValue == 2) {

            uint256 secondsPassed = 0;
            
            secondsPassed = now.sub(_startedAt);
            
            if(secondsPassed >= PUBLIC_MINT_AVAILABLE_TIME) {
                
                return _endingPrice;
                
            } else {
                
                uint256 totalPriceChange = _startingPrice.sub(_endingPrice);
                
                uint256 currentPriceChange = totalPriceChange.mul(secondsPassed).div(PUBLIC_MINT_AVAILABLE_TIME);

                uint256 currentPrice = _startingPrice.sub(currentPriceChange);

                return currentPrice;
            
            }   

        } else {
            
            return 0;
            
        }
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
    
        return items;
    }
    
    // Function to withdraw all Ether from this contract.
    function withdraw() external onlyOwner{
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
}