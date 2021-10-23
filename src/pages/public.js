import { ethers } from 'ethers'
import { useEffect, useState } from 'react'
import web3 from 'web3'
import { Slider, InputNumber, Button, notification, Row, Col } from 'antd'

import { contractAddress } from '../config'

import AuctionNFT from '../artifacts/contracts/AuctionNFT.json'

export const Public = ({signer}) => {
  const [publicAvailable, setPublicAvailable] = useState(false)
  const [inputValue, setInputValue] = useState(1)
  useEffect(() => {getState()}, [])
  
  async function getState() {
    const auctionContract = new ethers.Contract(contractAddress, AuctionNFT.abi, signer)
    let stageVal = web3.utils.toDecimal(await auctionContract.getCurrentStage())
    console.log('stage', stageVal)
    setPublicAvailable(stageVal === 2 ? true : false)
  }

  async function publicMint() {
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
    let currentPrice = await auctionContract.getCurrentPrice()
    
    await auctionContract
        .requestPublicToken({ value: currentPrice.toString() })
        .then((tx) => {
          return tx.wait().then((receipt) => {
              // This is entered if the transaction receipt indicates success
              notification.info({
                message: `PublicMint Success!`,
                description:
                  'You bought 1 NFT token with ' + web3.utils.fromWei(currentPrice.toString(), 'ether') + 'ETH',
                placement: 'topRight'
              });
              return true;
          }, (error) => {
              // This is entered if the status of the receipt is failure
              console.log('public error', error)
              notification.info({
                message: `PublicMint Fail!`,
                description:
                  'Trasaction is failed!',
                placement: 'topRight'
              });
          }
        )});

  }

  if(!publicAvailable) return (
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
          <Row>
            <Col span={12}>
              <Slider
                min={1}
                max={20}
                onChange={(val) => {setInputValue(val)}}
                value={inputValue}
              />
            </Col>
            <Col span={4}>
              <InputNumber
                min={1}
                max={20}
                style={{ margin: '0 16px' }}
                value={inputValue}
                onChange={(val)=> {setInputValue(val)}}
              />
            </Col>
          </Row>
        </div>
        <div className="grid grid-cols-2 gap-4 pt-8">
          <Button type="primary" onClick={() => publicMint()}>Mint</Button>  
        </div>
      </div>
    </div>
  )
}

