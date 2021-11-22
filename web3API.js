// node web3API.js

var Web3 = require('web3');
var NFT = require("./build/contracts/NFT.json");
var Auction = require("./build/contracts/Auction.json");
const web3 = new Web3("HTTP://127.0.0.1:7545");

const NFTContractAddress = "0xc4DA2E9898DeFBA22c534C06E846842CBcA6B16f";
const AuctionContractAddress = "0xf4475E904Dde75Ef90dE3F7d7f15e0F55964aE57";
const creator = "0xED5C4Cd0F322F758aEbd857dA78C285BE999e1c6";
const bidderOne = "0xe0EAB5Bb3bdaD73b20Ede02F9Bdd0c7485A71B02";
const bidderTwo = "0x17572c5089cB5a4C4ee5B0F9163f57ce469a03D1";

const getNFTContract = async () => {
    const netId = await web3.eth.net.getId();
    const deployedNetwork = NFT.networks[netId];
    const nft = new web3.eth.Contract(
      NFT.abi,
      deployedNetwork && deployedNetwork.address
    );
    return nft;
  };

const getAuctionContract = async () => {
    const netId = await web3.eth.net.getId();
    const deployedNetwork = Auction.networks[netId];
    const auction = new web3.eth.Contract(
        Auction.abi,
      deployedNetwork && deployedNetwork.address
    );
    return auction;
};

const createNFT = async (creatorAddress, tokenURI) => {
    const contract = await getNFTContract();
    //console.log(contract);
    const tokenid = await contract.methods.createNFT(creatorAddress, tokenURI).send({ from: creatorAddress, gas:3000000});
    // console.log(typeof tokenid);
    currentTokenID = parseInt(tokenid);
    return tokenid;
};

// createNFT(creator, "NFT_URI");

const checkBalance = async (creatorAddress) => {
    const contract = await getNFTContract();
    const balance = await contract.methods.balanceOf(creatorAddress).call();
    console.log("Balance of ", creatorAddress, " : ", balance);
};

// checkBalance(creator);

const setApprovalForAll = async (creatorAddress, auctionContractAddress) => {
    const contract = await getNFTContract();
    //console.log(contract);
    await contract.methods.setApprovalForAll(auctionContractAddress, true).send({ from: creatorAddress, gas:3000000})
    console.log("Approved Auction Contract");
};

// setApprovalForAll(creator, AuctionContractAddress);

const putTokenOnBid = async (creatorAddress, tokenID) => {
    // const tokenID = await createNFT(creator, "XXX");
    const AuctionContract = await getAuctionContract();
    const contract = await getNFTContract();
    const x = await contract.methods.ownerOf(tokenID).call();
    console.log(x);
    await AuctionContract.methods.putTokenOnBid(parseInt(tokenID),1000000).send({ from: creatorAddress, gas:3000000})
    
    console.log("NFT with tokenID - ",tokenID, "put on bid");
};

// putTokenOnBid(creator, 15);

const placeBid = async (bidder, tokenID, amount) => {
    const contract = await getAuctionContract();
     //console.log(contract);
    await contract.methods.placeBid(parseInt(tokenID)).send({ from: bidder, gas:3000000, value: web3.utils.toWei(amount, 'ether')})
    console.log("Placed Bid by : ", bidder);
}; 

// placeBid(bidderOne, 15);


const onBidComplete = async (tokenID) => {
    const contract = await getAuctionContract();
     //console.log(contract);
    await contract.methods.onBidComplete(parseInt(tokenID)).send({ from: creator, gas:3000000})
    console.log("Placed Bid by : ", bidder);
}; 

createNFT(creator, "NFT_URI").then(
    first => {
        setApprovalForAll(creator, AuctionContractAddress).then(
            second => {
                putTokenOnBid(creator, 1).then(
                    third => {
                        placeBid(bidderOne, 1, "1").then(
                            fourth => {
                                placeBid(bidderTwo, 1, "2").then(
                                    fifth => {
                                        onBidComplete(1).then(
                                            sixth => {
                                                checkBalance(bidderTwo);
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    }
)

