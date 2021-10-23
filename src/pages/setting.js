import { ethers } from 'ethers'
import { useState } from 'react'
import { Button, notification, Input } from 'antd'
import web3 from 'web3'

import { contractAddress } from "../config";

import AuctionNFT from '../artifacts/contracts/AuctionNFT.json'

export const Setting = ({signer}) => {
  const [baseUrl, setBaseUrl] = useState('')
  const [stagingValue, setStagingValue] = useState(0)
  const [whiteLst, setWhiteLst] = useState('')
//   useEffect(() => {}, [])

  async function sendChangeWhitelistRequest() {

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

      const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
      
      const params = whiteLst.split(',')
      await auctionContract.setWhiteList( params )
        .then((tx) => {
            return tx.wait().then((receipt) => {
                // This is entered if the transaction receipt indicates success
                notification.info({
                    message: `Setting whitelist success!`,
                    placement: 'topRight'
                });
                return true;
            }, (error) => {
                // This is entered if the status of the receipt is failure
                console.log('whitelist error', error)
                notification.info({
                  message: `Setting whitelist Fail!`,
                  placement: 'topRight'
                });
            }
    )});
  }
  
  async function sendChangeStageRequest() {
    if( parseInt(stagingValue) < 0 && parseInt(stagingValue) > 3 ) {
        notification.info({
            message: `Invalid Value!`,
            description: 'Stage Value must be 0(Stop minting except owner), 1(Presale) or 2(Public Minting)',
            placement: 'topRight'
        });
    }
    
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

    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
      
    await auctionContract
        .setStage( web3.utils.toNumber(stagingValue))
        .then((tx) => {
            return tx.wait().then((receipt) => {
                // This is entered if the transaction receipt indicates success
                notification.info({
                  message: `Setting stage success!`,
                  placement: 'topRight'
                });
                return true;
            }, (error) => {
                // This is entered if the status of the receipt is failure
                console.log('stage error', error)
                notification.info({
                  message: `Setting stage Fail!`,
                  placement: 'topRight'
                });
            }
        )});
  }

  async function sendChangeBaseUrlRequest() {
    if( baseUrl === '' ) {
        notification.info({
            message: `Invalid Value!`,
            description: 'Please input ipfs base url',
            placement: 'topRight'
        });
    }
    
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

    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
      
    await auctionContract
        .setBaseURI(baseUrl)
        .then((tx) => {
            return tx.wait().then((receipt) => {
                // This is entered if the transaction receipt indicates success
                notification.info({
                message: `Transaction success!`,
                placement: 'topRight'
                });
                return true;
            }, (error) => {
                // This is entered if the status of the receipt is failure
                console.log('baseURI error', error)
                notification.info({
                message: `Trasaction Fail!`,
                placement: 'topRight'
                });
            }
        )});
  }

  return (
    <div className="flex justify-center">
      <div style={{ width: 900 }}>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Input placeholder="0x00000000001,0x00000000002" onChange={(e) => setWhiteLst(e.target.value)} />
          <Button type="primary" onClick={() => sendChangeWhitelistRequest()}>Set Whitelist</Button>  
        </div>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Input placeholder="1: Presale, 2: Public Minting" onChange={(e) => setStagingValue(e.target.value)} />
          <Button type="primary" onClick={() => sendChangeStageRequest()}>Set Stage</Button>  
        </div>
        <div className="grid grid-cols-4 gap-4 pt-8">
          <label>ex: https://gateway.pinata.cloud/ipfs/QmSUvFVSExddCZfrfDTDfpEfNTpuKAVRksiJsrHidAwsXh/</label>
        </div>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Input placeholder="https://gateway.pinata.cloud/ipfs/QmSUvFVSExddCZfrfDTDfpEfNTpuKAVRksiJsrHidAwsXh/" onChange={(e) => setBaseUrl(e.target.value)} />
          <Button type="primary" onClick={() => sendChangeBaseUrlRequest()}>Set baseUrl</Button>  
        </div>
      </div>
    </div>
  )
}
