// SPDX-Lincense-Identifier : MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    //returns the price of an NFT from the FakeNFTMarketplace
    function getPrice() external view returns (uint256);

    //returns whether or not the given _tokenId has already been purchased
    function available(uint256 _tokenId) external view returns (bool);

    // Purchase a NFT from the FakeNFTMarketplace
    function purchase(uint256 _tokenId) external payable;
}


interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);

    // Returns a tokenID at given index for owner
    // owner - address to fetch the NFT TokenID for
    // index - index of NFT in owned tokens array to fetch
    // return - returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index) 
        external
        view
        returns (uint256);
    
}

contract CryptoDevsDAO is Ownable {

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    struct Proposal {
        // the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        // cannot be executed before the deadline has been exceeded
        bool executed;
        // a mapping of CryptoDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    //create an enum named Vote containing possible option for a vote

    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    

    //Create a mapping of ID to proposal
    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;


    // Create a modifier which only allows a function to be called by someone who owns at least 1  CryptoDevsNFT
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEED"
        );
        _;
    }


    modifier inactiveProposalOnly(uint256 proposalIndex){
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );

        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }



    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)

    {
            require(nftMarketplace.available(_nftTokenId),"NFT_NOT_FOR_SALE");
            Proposal storage proposal = proposals[numProposals];
            proposal.nftTokenId = _nftTokenId;
            //Set the proposal's voting deadline to be (current time + 5 minutes)
            proposal.deadline = block.timestamp + 5 minutes;

            numProposals++;

            return numProposals - 1;
    }

    function voteOnProposal (uint256 proposalIndex, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        }else{
            proposal.nayVotes += numVotes;
        }
    }


    function executeProposal(uint256 proposalIndex)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // If the proposal has more YAY votes than NAY votes purchase the NFT from the FakeNFTmarketplace
        if(proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    //withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }



    // allows the contract to accept ETH deposits directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

}