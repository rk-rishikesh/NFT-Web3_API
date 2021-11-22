var NFT = artifacts.require ("NFT");
var Auction = artifacts.require ("Auction");

module.exports = function(deployer) {
      deployer.deploy(NFT);
      deployer.deploy(Auction, NFT.address, 5);
      //console.log("NFT Contract deployed at : ", NFT.address);
      //console.log("Auction Contract deployed at : ", Auction.address);
}
