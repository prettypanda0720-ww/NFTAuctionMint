import { ethers } from 'ethers'
import { useEffect, useState } from 'react'
import { Button, notification } from 'antd'
import web3 from 'web3'
import axios from 'axios'
import Web3Modal from "web3modal"
import { contractAddress, presalePrice, PRIVATE_KEY } from "../config";

import AuctionNFT from '../artifacts/contracts/AuctionNFT.json'

export const Presale = ({signer}) => {
  console.log('props', signer)
  const [nfts, setNfts] = useState([])
  const [presaleAvailable, setPresaleAvailable] = useState(false)
  useEffect(() => {
      getState()
    }
  )

  async function getState() {
    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
    let stageVal = web3.utils.toDecimal(await auctionContract.getCurrentStage())
    setPresaleAvailable(stageVal == 1 ? true : false)
  }

  async function presaleMint() {
    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
    const funds = await signer.getBalance()
    
    if(funds.toString()  === '0') {
      notification.info({
        message: `Insufficient funds!`,
        description:
          'Please buy test ETH for rinkeby',
        placement: 'topRight'
      })
      return
    }
    const price = web3.utils.toWei(presalePrice, 'ether');
    
    // const gasPrice = await auctionContract.estimateGas.requestPresaleToken({ value: price })
    // console.log('gasPrice', gasPrice)
    await auctionContract
          .requestPresaleToken({ value: price })
          .then((tx) => {
            return tx.wait().then((receipt) => {
                // This is entered if the transaction receipt indicates success
                notification.info({
                  message: `Presale Success!`,
                  description:
                    'You bought 1 NFT token with 0.05ETH',
                  placement: 'topRight'
                });
                return true;
            }, (error) => {
                console.log('presale error', error)
                notification.info({
                  message: `Presale Fail!`,
                  description:
                    'Your address is not included in whitelist',
                  placement: 'topRight'
                });
            }
          )});

  }
  
  if(!presaleAvailable) return (
    <div className="flex justify-center">
      <div style={{ width: 900 }}>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Button type="primary" disabled>Mint</Button>  
        </div>
      </div>
    </div>
  )
  return (
    <div className="flex justify-center">
      <div style={{ width: 900 }}>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Button type="primary" onClick={() => presaleMint()}>Mint</Button>  
        </div>
      </div>
    </div>
  )
}
