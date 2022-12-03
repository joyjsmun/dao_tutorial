//SPDX-License-Identifier : MIT
pragma solidity ^0.8.0;


contract FakeNFTMarketplace {
    mapping(uint256 => address) public tokens;
    uint256 nftPrice = 0.1 ether;

    // Accepts ETH and marks the owner of the given tokenId as the caller address
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This is NFT costs 0.1 ether");
        tokens[_tokenId] = msg.sender;

    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // Checks whether the given tokenId has already been sold or not
    function available(uint256 _tokenId) external view returns (bool) {
        if(tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }


}