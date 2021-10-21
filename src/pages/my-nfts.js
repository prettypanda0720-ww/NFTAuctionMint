import { ethers } from 'ethers'
import { useEffect, useState } from 'react'
import web3 from 'web3'
import axios from 'axios'
import Web3Modal from "web3modal"

import { contractAddress } from '../config'

import AuctionNFT from '../artifacts/contracts/AuctionNFT.json'

export const MyNfts = ({signer}) => {
  const [nfts, setNfts] = useState([])
  const [loaded, setLoaded] = useState('not-loaded')

  async function loadNFTs() {
    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)

    const data = await auctionContract.fetchMyNFTs()
    
    console.log('My NFT', data)
    const config = {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      }
    }
    const items = await Promise.all(data.map(async i => {
      const tokenUri = await auctionContract.tokenURI(i.tokenId)
      const meta = await axios.get(tokenUri, {}, config)
      let price = web3.utils.fromWei(i.price.toString(), 'ether');
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        owner: i.owner,
        image: meta.data.image,
      }
      return item
    }))
  
    setNfts(items)
    setLoaded('loaded')
  }
  if (loaded === 'loaded' && !nfts.length) return (<h1 className="p-20 text-4xl">No NFTs!</h1>)
  if (loaded === 'not-loaded' && !nfts.length) return (<button onClick={loadNFTs} className="rounded bg-blue-600 py-2 px-12 text-white m-16">Fetch NFTs</button>)
  return (
    <div className="flex justify-center">
      <div style={{ width: 900 }}>
        <div className="grid grid-cols-2 gap-4 pt-8">
          {
            nfts.map((nft, i) => (
              <div key={i} className="border p-4 shadow">
                <img src={nft.image} className="rounded" />
                <p className="text-2xl my-4 font-bold">Price paid: {nft.price} ETH</p>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  )
}
