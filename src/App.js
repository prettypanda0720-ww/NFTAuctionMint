// import logo from './logo.svg';
import './styles/App.css';
import { useEffect, useState } from 'react'
import { Tabs, Button } from 'antd';
import { Presale } from './pages/presale';
import { Public } from './pages/public';
import { MyNfts } from './pages/my-nfts';
import { Setting } from './pages/setting';
import Web3Modal from "web3modal"
import { ethers } from 'ethers'

const { TabPane } = Tabs;

function callback(key) {
  
}

export const App = () => {

  const [signer, setSigner] = useState({})
  const [walletAddress, setWalletAddress] = useState('')
  
  useEffect(() => {
      // connectWallet()
    }
  )
  async function connectWallet() {
    const web3Modal = new Web3Modal({
      network: "rinkeby",
      cacheProvider: true,
    });
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner()
    // console.log('signer', signer)
    setSigner(signer)
    // setWalletAddress(signer.getAddress)
    const address = await signer.getAddress()
    setWalletAddress(address)
  }

  if(walletAddress === '') {
    return (
      <div className="main-layout">
        <Button type="primay" onClick={() => connectWallet()}>Connect Wallet</Button>
      </div>      
    )
  } else {
    return (
      <div className="main-layout">
        <Button type="primay" disabled>{walletAddress}</Button>
        <Tabs defaultActiveKey="1" onChange={callback}>
          <TabPane tab="Presale" key="1">
            <Presale signer={signer}/>
          </TabPane>
          <TabPane tab="Public Mint" key="2">
            <Public signer={signer}/>
          </TabPane>
          <TabPane tab="My NFTs" key="3">
            <MyNfts signer={signer}/>
          </TabPane>
          <TabPane tab="Settings" key="4">
            <Setting signer={signer}/>
          </TabPane>
        </Tabs>
      </div>      
    )
  }
  
}

export default App;
