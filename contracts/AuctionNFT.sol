// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AuctionNFT is ERC721, Ownable {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;
    uint256 MAX_SUPPLY = 10000;
    uint BASIC_SLIPPAGE_TOLERANCE = 2;
    /***  for production ***/
    uint PUBLIC_MINT_AVAILABLE_TIME = 14400;
    uint NORMAL_MINT_AVAILABLE_TIME = 172800;
    uint MAX_OWN_COUNT = 10;
    
    /***  for test ***/
    // uint PUBLIC_MINT_AVAILABLE_TIME = 600;
    // uint NORMAL_MINT_AVAILABLE_TIME = 600;
    // uint MAX_OWN_COUNT = 5;

    /**********  staging value for 
        initial state (value = 0)
        presale (value = 1), 
        public minting (value = 2)
        normal minting (value = 3)
        ended (value = 4)
    *******************************/
    
    uint _stagingValue = 0;
    
    /*********** Variables for changing token price ***********/
    
    uint256 _startingPrice = 200000000000000000; // 2 * (10 ^ 17) wei
    uint256 _endingPrice = 50000000000000000; // 5 * (10 ^ 16)wei
    uint256 _publicStartedAt = 0; // time
    uint256 _normalStartedAt = 0; // time
    
    /************* Variables for whitelist *************/
    
    mapping(address => bool) private _whitelist;
    mapping(address => uint) private _countlist;

    event presaleSuccess(bool result);
    event publicsaleSuccess(bool result);
    event normalsaleSuccess(bool result);
    
    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price; 
    }

    mapping(uint256 => MarketItem) private idToMarketItem;    
    
    constructor() public ERC721("NFT Auction", "CTBA") payable {
        
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
    
    function requestPresaleToken() external payable {
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        require(_stagingValue == 1, "Presale is not allowed.");
        require(_whitelist[msg.sender], "This address is not included in whitelist.");
        require(_countlist[msg.sender] < MAX_OWN_COUNT, "Overflow 10 tokens");
        require(msg.value == _endingPrice, "Invalid funds");
        _tokenMint();
        _countlist[msg.sender] = _countlist[msg.sender] + 1;
        emit presaleSuccess(true);
    }

    function requestPublicToken(uint mintCount) external payable {
        uint256 secondsPassed = 0;
        secondsPassed = now.sub(_publicStartedAt);
        require(secondsPassed < PUBLIC_MINT_AVAILABLE_TIME, "Minting is ended.");
        require(super.totalSupply() + mintCount <= MAX_SUPPLY, "Maximum supply reached.");
        require(mintCount > 0, "Mint count has to be more than 1.");
        require(_stagingValue == 2, "Public Minting is not allowed.");
        require(_countlist[msg.sender] + mintCount <= MAX_OWN_COUNT, "Overflow 10 tokens");
        uint tolerance = BASIC_SLIPPAGE_TOLERANCE;
        uint256 limitValue = getCurrentPrice().mul(10000 - tolerance).mul(mintCount).div(10000);
        require(msg.value >= limitValue);
        for (uint256 index = 0; index < mintCount; index++) {
            _tokenMint();
            _countlist[msg.sender] = _countlist[msg.sender] + 1;
        }
        emit publicsaleSuccess(true);
    }
    
    function requestNormalToken(uint mintCount) external payable {
        uint256 secondsPassed = 0;
        secondsPassed = now.sub(_normalStartedAt);
        require(secondsPassed < NORMAL_MINT_AVAILABLE_TIME, "Minting is ended.");
        require(super.totalSupply() + mintCount < MAX_SUPPLY, "Maximum supply reached.");
        require(_stagingValue == 3, "Normal Minting is not allowed.");
        require(_countlist[msg.sender] + mintCount <= MAX_OWN_COUNT, "Overflow 10 tokens");
        uint256 limitValue = getCurrentPrice().mul(mintCount);
        require(msg.value == limitValue, "Invalid funds");
        for (uint256 index = 0; index < mintCount; index++) {
            _tokenMint();
            _countlist[msg.sender] = _countlist[msg.sender] + 1;
        }
        emit normalsaleSuccess(true);
    }

    function setWhiteList(address[] memory params) public onlyOwner{
        require(params.length > 0, "Please input whiltelist array");
        for(uint i = 0; i < params.length; i++) {
            _whitelist[params[i]] = true;
        }
    }

    function setStage(uint256 value) public onlyOwner{
        require(value >= 0, "Invalid staging value");
        require(value < 5, "Invalid staging value");
        _stagingValue = value;
        if(value == 2) {
            _publicStartedAt = now;
        } else if (value == 3) {
            _normalStartedAt = now;
        }
    }
    
    function getPublicMintingAvailableTime() public view returns(uint256) {
        if(_publicStartedAt > 0) {
            uint256 secondsPassed = 0;
            secondsPassed = now.sub(_publicStartedAt);
            if(secondsPassed > PUBLIC_MINT_AVAILABLE_TIME) {
                return 0;
            } else {
                return PUBLIC_MINT_AVAILABLE_TIME - secondsPassed;
            }
        } else {
            return 0;
        }
    }

    function setPublicMintingAvailableTime(uint256 value) public onlyOwner {
        PUBLIC_MINT_AVAILABLE_TIME = value;
    }

    function getNormalMintingAvailableTime() public view returns(uint256) {
        if(_normalStartedAt > 0) {
            uint256 secondsPassed = 0;
            secondsPassed = now.sub(_normalStartedAt);
            if(secondsPassed > NORMAL_MINT_AVAILABLE_TIME) {
                return 0;
            } else {
                return NORMAL_MINT_AVAILABLE_TIME - secondsPassed;
            }
        } else {
            return 0;
        }
    }

    function setNormalMintingAvailableTime(uint256 value) public onlyOwner {
        NORMAL_MINT_AVAILABLE_TIME = value;
    }

    function getMaxMintCount() public view returns(uint256) {
        return MAX_OWN_COUNT;
    }

    function setMaxMintCount(uint256 value) public onlyOwner {
        MAX_OWN_COUNT = value;
    }

    function getCurrentStage() public view returns(uint256) {
        return _stagingValue;
    }
    
    function getCurrentPrice() public view returns(uint256) {
        if(_stagingValue == 1) {
            
            return _endingPrice;
            
        } else if(_stagingValue == 2) {

            uint256 secondsPassed = 0;
            
            secondsPassed = now.sub(_publicStartedAt);
            
            if(secondsPassed > PUBLIC_MINT_AVAILABLE_TIME) {
                
                return _endingPrice;
                
            } else {
                
                uint256 totalPriceChange = _startingPrice.sub(_endingPrice);
                
                uint256 currentPriceChange = totalPriceChange.mul(secondsPassed).div(PUBLIC_MINT_AVAILABLE_TIME);

                uint256 currentPrice = _startingPrice.sub(currentPriceChange);

                return currentPrice;
            
            }   

        } else if (_stagingValue == 3) {

            return _endingPrice;

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