// General imports
require('dotenv').config()
const fs = require('fs')

// Web3
const Web3 = require('web3')
const ROPSTEN_PROVIDER='https://ropsten.infura.io/v3/08e218c158154582a6523eb1d36e6120'
const web3 = new Web3(ROPSTEN_PROVIDER)

// Aztec imports
const aztecContractAddresses = require('@aztec/contract-addresses')
const networkIdMap = aztecContractAddresses.NetworkId // Map network-name to network-id
const utils = require('@aztec/dev-utils')
const aztec = require('aztec.js')
const secp256k1 = require('@aztec/secp256k1')
const aztecContractArtifacts = require('@aztec/contract-artifacts')

// Ethereum imports
const CUSDABI = JSON.parse(fs.readFileSync('./artifacts/MetaToken.json'))['abi']
const WT0ABI = JSON.parse(fs.readFileSync('./artifacts/Wt0.json'))['abi']

// Global pre-run setup
const NET = "Ropsten"
const AMOUNT_OF_TOKENS_TO_MINT = 10
const availableAddresses = aztecContractAddresses.getContractAddressesForNetwork(networkIdMap[NET])
const contractAddresses = require('./address-book').contracts
const userAddresses = require('./address-book').users
const CusdAddress = contractAddresses['CUSD_ROPSTEN']
const Wt0Address = contractAddresses['WT0_ROPSTEN']
const ZKAssetAddress = contractAddresses['ZK20_ROPSTEN']
const ownerACE = userAddresses['ACE_OWNER']
const ownerCUSD = userAddresses['CUSD_OWNER']
const ownerWT0 = userAddresses['WT0_OWNER']
const minterCUSD = userAddresses['CUSD_MINTER']
const user = userAddresses['USER']

// Load contracts
const AceContract = new web3.eth.Contract(aztecContractArtifacts.ACE.abi, availableAddresses.ACE)
const CusdContract = new web3.eth.Contract(CUSDABI, CusdAddress)
const Wt0Contract = new web3.eth.Contract(WT0ABI, Wt0Address)
const ZKAssetContract = new web3.eth.Contract(aztecContractArtifacts.ZkAsset.abi, ZKAssetAddress)

contract('Pre-Test: Detecting Deployed Contracts', async (accounts) => {

    describe('Test Web3 instance', async () => {
        const web3Version = "1.2.1"
        it(`Version is ${web3Version}`, async () => {
            assert.equal(web3.version.toString(), web3Version)
        })
        it(`Provider is ${ROPSTEN_PROVIDER}`, async () => {
            assert.equal(web3.currentProvider.host, ROPSTEN_PROVIDER)
        })
        it(`Listening to peers`, async () => {
            assert(await web3.eth.net.isListening())
        })
        it(`Has a Block number`, async () => {
            let blockNumber = await web3.eth.getBlockNumber()
            assert(blockNumber > 0)
        })     
    })
    describe('Test ACE Contract', () => {
        it('ACE Contract has the correct owner', async () => {
            let owner = await AceContract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerACE))
        })
    })
    describe('Test CUSD Contract', () => {
        it('Total supply > 0', async () => {
            let totalSupply = await CusdContract.methods.totalSupply().call()
            let totalSupplyEther = web3.utils.fromWei(totalSupply.toString(), 'ether')
            assert(totalSupplyEther > 0)
        })
        it('CUSD Contract has the correct owner', async () => {
            let owner = await CusdContract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerCUSD))
        })
    })
    describe('Test WT0 Contract', () => {
        it('Total supply > 0', async () => {
            let totalSupply = await Wt0Contract.methods.totalSupply().call()
            let totalSupplyEther = web3.utils.fromWei(totalSupply.toString(), 'ether')
            assert(totalSupplyEther > 0)
        })
        it('Wt0 Contract has the correct owner', async () => {
            let owner = await Wt0Contract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerWT0))
        })
        it('Wt0 Contract is connected to the correct CUSD address', async () => {
            let cusdAddress = await Wt0Contract.methods.cusdAddress().call()
            assert.equal(web3.utils.toChecksumAddress(cusdAddress), web3.utils.toChecksumAddress(CusdAddress))
        })
    })
    describe('Test ZK-CUSD Contract', () => {
        it('Contract is references correct ERC20 and ACE contract addresses', async () => {
            let aceAddress = await ZKAssetContract.methods.ace().call()
            let erc20Address = await ZKAssetContract.methods.linkedToken().call()
            assert.equal(web3.utils.toChecksumAddress(erc20Address), web3.utils.toChecksumAddress(CusdAddress))
            assert.equal(web3.utils.toChecksumAddress(aceAddress), web3.utils.toChecksumAddress(AceContract.options.address))    
        })
    })

})

contract('1. Distribute ERC20 to a new holder', async (accounts) => {
    const amountToMint = AMOUNT_OF_TOKENS_TO_MINT
    const minterKey = `0x${process.env.CUSD_MINTER_ROPSTEN}`
    let minter = web3.eth.accounts.privateKeyToAccount(minterKey)
    describe('Testing issuer of new ERC20', () => {
        it('Minter has correct address', async () => {
            assert.equal(minter.address, minterCUSD)
        })
        it('Minter has enough balance', async () => {
            let balance = await web3.eth.getBalance(minter.address)
            let balanceEther = web3.utils.fromWei(balance, 'ether')
            assert(balanceEther > 0.1)
        })
    })

    describe(`Minting CUSD to user`, () => {
        let balance
        it('User has a balance', async () => {
            balance = await CusdContract.methods.balanceOf(user).call()
            assert(balance > 0)
        })

        it(`Minting ${amountToMint}...`, async () => {
            let amountToMintEther = web3.utils.toWei(amountToMint.toString(), 'ether')
            let mintTransaction = Wt0Contract.methods.mintCUSD(user, amountToMintEther)
            let gasEstimate = await mintTransaction.estimateGas({ from: minter.address })
            let signedTransaction = await minter.signTransaction({
                gas: gasEstimate,
                gasPrice: web3.utils.toWei('30', 'gwei'),
                to: Wt0Contract.options.address,
                data: mintTransaction.encodeABI()
            })
            let pendingHash = await web3.eth.sendSignedTransaction(
                signedTransaction.rawTransaction
            )
            // @DEBUG:
            console.log(`Pending block hash: `, pendingHash.blockHash)  
            console.log(`Pending transaction hash: `, pendingHash.transactionHash)        
        })

        let postBalance
        it('User has the correct post-mint balance', async () => {
            let amountMintedEther = web3.utils.toWei(amountToMint.toString(), 'ether')
            postBalance = await CusdContract.methods.balanceOf(user).call()
            assert.equal(parseFloat(postBalance), parseFloat(balance)+parseFloat(amountMintedEther))
        })
    })

})

contract('2.  Holder approves ACE to spend its ERC20', async (accounts) => {
    const amountToApprove = AMOUNT_OF_TOKENS_TO_MINT
    const userKey = `0x${process.env.ROPSTEN_CUSD_USER}`
    let holder = web3.eth.accounts.privateKeyToAccount(userKey)
    describe('Testing holder of new ERC20', () => {
        it('User has correct address', async () => {
            assert.equal(holder.address, user)
        })
        it('User has enough balance', async () => {
            let balance = await web3.eth.getBalance(holder.address)
            let balanceEther = web3.utils.fromWei(balance, 'ether')
            assert(balanceEther > 0.1)
        })
    })

    // describe(`Approving ACE to spend CUSD`, () => {
    //     let allowance
    //     it('ACE has an allowance', async () => {
    //         allowance = await CusdContract.methods.allowance(holder.address, AceContract.options.address).call()
    //         console.log(allowance)
    //         assert(allowance > 0)
    //     })
    //     it(`Approving...`, async () => {
    //         let amountToApproveEther = web3.utils.toWei(amountToApprove.toString(), 'ether')
    //         let _transaction = CusdContract.methods.approve(AceContract.options.address, amountToApproveEther)
    //         let gasEstimate = await _transaction.estimateGas({ from: holder.address })
    //         let signedTransaction = await holder.signTransaction({
    //             gas: gasEstimate,
    //             gasPrice: web3.utils.toWei('30', 'gwei'),
    //             to: CusdContract.options.address,
    //             data: _transaction.encodeABI()
    //         })
    //         let pendingHash = await web3.eth.sendSignedTransaction(
    //             signedTransaction.rawTransaction
    //         )
    //         // @DEBUG:
    //         console.log(`Pending block hash: `, pendingHash.blockHash)  
    //         console.log(`Pending transaction hash: `, pendingHash.transactionHash)        
    //     })
    //     let postAllowance
    //     it('User has the correct post-mint allowance', async () => {
    //         let amountApprovedEther = web3.utils.toWei(amountToApprove.toString(), 'ether')
    //         postAllowance = await CusdContract.methods.allowance(holder.address, AceContract.options.address).call()
    //         assert.equal(parseFloat(postAllowance), parseFloat(allowance)+parseFloat(amountApprovedEther))
    //     })
    // })
})
// contract('2. Convert ERC20 => ZK-ERC20')

// contract('3 Distribute ZK-ERC20 Confidentially')

// contract('4. Convert ZK-ERC20 => ERC20')