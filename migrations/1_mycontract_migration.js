const AuctionNFT = artifacts.require('AuctionNFT')

module.exports = async (deployer, network, [defaultAccount]) => {
  AuctionNFT.setProvider(deployer.provider)
  if (network.startsWith('rinkeby')) {
    await deployer.deploy(AuctionNFT)
    let dnd = await AuctionNFT.deployed()
  } else if (network.startsWith('mainnet')) {
    console.log("If you're interested in early access to Chainlink VRF on mainnet, please email vrf@chain.link")
  } else if (network.startsWith('localhost')) {
    await deployer.deploy(AuctionNFT)
    let dnd = await AuctionNFT.deployed()
  } else {
    console.log("Right now only rinkeby works! Please change your network to Rinkeby")
  }
}
