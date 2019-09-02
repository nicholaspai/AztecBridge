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
const { JoinSplitProof, note } = aztec
const secp256k1 = require('@aztec/secp256k1')
const aztecContractArtifacts = require('@aztec/contract-artifacts')

// Ethereum imports
const CUSDABI = JSON.parse(fs.readFileSync('./artifacts/MetaToken.json'))['abi']
const WT0ABI = JSON.parse(fs.readFileSync('./artifacts/Wt0.json'))['abi']

// Global pre-run setup
const NET = "Ropsten"
const AMOUNT_OF_TOKENS_TO_MINT = 10

// Load addresses
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
const user2 = userAddresses['USER-2']

// Load contracts
const AceContract = new web3.eth.Contract(aztecContractArtifacts.ACE.abi, availableAddresses.ACE)
const CusdContract = new web3.eth.Contract(CUSDABI, CusdAddress)
const Wt0Contract = new web3.eth.Contract(WT0ABI, Wt0Address)
const ZKAssetContract = new web3.eth.Contract(aztecContractArtifacts.ZkAsset.abi, ZKAssetAddress)

contract(`Detecting Contracts on network (${NET})`, async (accounts) => {

    describe('Testing Web3 instance', () => {
        const web3Version = "1.2.1"
        it(`- version is ${web3Version}`, async () => {
            assert.equal(web3.version.toString(), web3Version)
        })
        it(`- provider is ${ROPSTEN_PROVIDER}`, async () => {
            assert.equal(web3.currentProvider.host, ROPSTEN_PROVIDER)
        })
        it(`- listening to peers`, async () => {
            assert(await web3.eth.net.isListening())
        })
        it(`- has a Block number`, async () => {
            let blockNumber = await web3.eth.getBlockNumber()
            assert(blockNumber > 0)
        })     
    })
    describe('ACE Contract', () => {
        it('- has the correct owner', async () => {
            let owner = await AceContract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerACE))
        })
        it('- has set the correct flags', async () => {
            const registry = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
            assert(!registry.canAdjustSupply)
            assert(registry.canConvert)
        })
    })
    describe('CUSD Contract', () => {
        it('- total supply > 0', async () => {
            let totalSupply = await CusdContract.methods.totalSupply().call()
            let totalSupplyEther = web3.utils.fromWei(totalSupply.toString(), 'ether')
            assert(totalSupplyEther > 0)
        })
        it('- has the correct owner', async () => {
            let owner = await CusdContract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerCUSD))
        })
    })
    describe('WT0 Contract', () => {
        it('- total supply > 0', async () => {
            let totalSupply = await Wt0Contract.methods.totalSupply().call()
            let totalSupplyEther = web3.utils.fromWei(totalSupply.toString(), 'ether')
            assert(totalSupplyEther > 0)
        })
        it('- has the correct owner', async () => {
            let owner = await Wt0Contract.methods.owner().call()
            assert.equal(web3.utils.toChecksumAddress(owner), web3.utils.toChecksumAddress(ownerWT0))
        })
        it('- is linked to the correct CUSD address', async () => {
            let cusdAddress = await Wt0Contract.methods.cusdAddress().call()
            assert.equal(web3.utils.toChecksumAddress(cusdAddress), web3.utils.toChecksumAddress(CusdAddress))
        })
    })
    describe('ZK-CUSD Contract', () => {
        it('- linked to expected ERC20 address', async () => {
            let erc20Address = await ZKAssetContract.methods.linkedToken().call()
            assert.equal(web3.utils.toChecksumAddress(erc20Address), web3.utils.toChecksumAddress(CusdAddress))
        })
        it('- linked to expected ACE address', async () => {
            let aceAddress = await ZKAssetContract.methods.ace().call()
            assert.equal(web3.utils.toChecksumAddress(aceAddress), web3.utils.toChecksumAddress(AceContract.options.address))
        })
    })

})

contract('ERC20-CUSD', async (accounts) => {
    const amountToMint = AMOUNT_OF_TOKENS_TO_MINT
    const minterKey = `0x${process.env.CUSD_MINTER_ROPSTEN}`
    let minter = web3.eth.accounts.privateKeyToAccount(minterKey)
    describe('Minting tokens to depositor', () => {
        describe('minter:Minter', () => {
            it('- is expected address', async () => {
                assert.equal(minter.address, minterCUSD)
            })
            it('- has enough balance', async () => {
                let balance = await web3.eth.getBalance(minter.address)
                let balanceEther = web3.utils.fromWei(balance, 'ether')
                assert(balanceEther > 0.1, `User only has ${balanceEther} ETH`)
            })
        }) 
        describe(`wt0.mintCUSD`, () => {
            let balance
            it('- user has a balance', async () => {
                balance = await CusdContract.methods.balanceOf(user).call()
                assert(balance > 0)
            })
    
            it(`- minting ${amountToMint} tokens`, async () => {
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
                // console.log(`Pending block hash: `, pendingHash.blockHash)  
                // console.log(`Pending transaction hash: `, pendingHash.transactionHash)       
                assert(pendingHash.status)   
            })
    
            let postBalance
            it('- user balance is expected post-mint', async () => {
                let amountMintedEther = web3.utils.toWei(amountToMint.toString(), 'ether')
                postBalance = await CusdContract.methods.balanceOf(user).call()
                assert.equal(parseFloat(postBalance), parseFloat(balance)+parseFloat(amountMintedEther))
            })
        })
    })

})

contract('ZK-CUSD', async (accounts) => {
    // @dev: We have to use “secp256k1” because AZTEC needs the accounts’ public keys, not just their Ethereum addresses

    // Keys: Switch roles by editing these variables
    const depositorKey = `0x${process.env.ROPSTEN_CUSD_USER}`
    const redeemerKey = `0x${process.env.ROPSTEN_CUSD_USER_2}`

    // Depositor: Deposits public ERC20 into private zk notes
    const amountToDeposit = AMOUNT_OF_TOKENS_TO_MINT
    const depositPublicValue = amountToDeposit *-1 // Converting public notes into new private notes, should be negative
    let depositor = secp256k1.accountFromPrivateKey(depositorKey)
    let depositorAccount = web3.eth.accounts.privateKeyToAccount(depositorKey) // Ethereum account
    const amountToDepositWei = parseFloat(web3.utils.toWei(amountToDeposit.toString(), 'ether'))

    // Confidential transfers have no public delta!
    const transferPublicValue = 0
    
    // Redeemer: Withdraws private zk notes to public ERC20
    // We have to use “secp256k1” because AZTEC needs the accounts’ public keys, not just their addresses
    const amountToRedeem = AMOUNT_OF_TOKENS_TO_MINT - 4
    const redeemPublicValue = amountToRedeem  // Creating new public notes, should be positive
    let redeemer = secp256k1.accountFromPrivateKey(redeemerKey)
    let redeemerAccount = web3.eth.accounts.privateKeyToAccount(redeemerKey) // Ethereum account
    const amountToRedeemWei = parseFloat(web3.utils.toWei(amountToRedeem.toString(), 'ether'))

    describe(`A depositor (${depositorAccount.address.substring(0,6)}) wants to deposit ${amountToDeposit} ERC20 into private notes, and send ${amountToRedeem} zk-notes to a redeemer (${redeemerAccount.address.substring(0,6)})`, () => {
        describe('Increase allowances to cover all confidential transfers', () => {

            /**
             * Invariants
             */
            let startingAllowanceDepositor
            let startingAllowanceRedeemer
            const aceAddress = AceContract.options.address
            describe(`Using increaseApproval() instead of approve() due to security issues with the latter`, () => {
                it(`- detected ACE's allowance`, async () => {
                    startingAllowanceDepositor = await CusdContract.methods.allowance(depositorAccount.address, aceAddress).call()
                    startingAllowanceRedeemer = await CusdContract.methods.allowance(redeemerAccount.address, aceAddress).call()
                    assert(parseFloat(startingAllowanceDepositor) >= 0)
                    assert(parseFloat(startingAllowanceRedeemer) >= 0)
                })
                it(`- increases allowance for ACE to spend on behalf of depositor +${amountToDeposit}`, async () => {
                    let user = depositorAccount
                    // Increase allowance for ACE to spend on behalf of minter of new zk notes
                    let amountToApproveWei = amountToDepositWei
                    let _approveTransaction = CusdContract.methods.increaseApproval(aceAddress, amountToApproveWei.toString())
                    let gasEstimateApprove = await _approveTransaction.estimateGas({ from: user.address })
                    let signedApproveTransaction = await user.signTransaction({
                        gas: gasEstimateApprove,
                        gasPrice: web3.utils.toWei('30', 'gwei'),
                        to: CusdContract.options.address,
                        data: _approveTransaction.encodeABI()
                    })
                    let pendingApproveHash = await web3.eth.sendSignedTransaction(
                        signedApproveTransaction.rawTransaction
                    )
                    // @DEBUG:
                    // console.log(`Pending increase allowance hash: `, pendingApproveHash.transactionHash) 
                    assert(pendingApproveHash.status)
                })
                it(`- increases allowance for ACE to spend on behalf of redeemer +${amountToRedeem}`, async () => {
                    let user = redeemerAccount
                    // Increase allowance for ACE to spend on behalf of receiver of minted zk notes
                    let amountToApproveWei = amountToRedeemWei
                    let _approveTransaction = CusdContract.methods.increaseApproval(aceAddress, amountToApproveWei.toString())
                    let gasEstimateApprove = await _approveTransaction.estimateGas({ from: user.address })
                    let signedApproveTransaction = await user.signTransaction({
                        gas: gasEstimateApprove,
                        gasPrice: web3.utils.toWei('30', 'gwei'),
                        to: CusdContract.options.address,
                        data: _approveTransaction.encodeABI()
                    })
                    let pendingApproveHash = await web3.eth.sendSignedTransaction(
                        signedApproveTransaction.rawTransaction
                    )
                    // @DEBUG:
                    // console.log(`Pending increase allowance hash: `, pendingApproveHash.transactionHash)  
                    assert(pendingApproveHash.status)
                })
                it(`- allowances are increased as expected`, async () => {
                    allowanceDepositor = await CusdContract.methods.allowance(depositorAccount.address, aceAddress).call()
                    allowanceRedeemer = await CusdContract.methods.allowance(redeemerAccount.address, aceAddress).call()
                    assert.equal(parseFloat(allowanceDepositor), parseFloat(startingAllowanceDepositor)+amountToDepositWei)
                    assert.equal(parseFloat(allowanceRedeemer), parseFloat(startingAllowanceRedeemer)+amountToRedeemWei)
                })
            })
        })

        // Store output notes to use in future private transactions
        let depositOutputNotes
        let transferOutputNotes
        let redeemOutputNotes

        describe('Creates new zk notes', () => {
            /**
             * AZTEC notes
             */
            let notes
            before(async () => {
                // Create notes
                const partialAmount = 5 // Used to create more notes arbitrarily, in practice helps preserve privacy
                notes = [ // @dev: note amounts must be positive
                    // Notes used to create new zk notes for depositor
                    await note.create(depositor.publicKey, partialAmount),
                    await note.create(depositor.publicKey, amountToDeposit-partialAmount) // TODO: Check if amount is ever negative
                ]
            })

            let depositProof 
            let depositProofData
            let depositSignatures
            it('- constructs JoinSplitProofs from Aztec.notes', async () => {
                // @dev: store output notes
                depositOutputNotes = notes

                const inputNotes = [] // For Public to Private, set input notes array to empty
                const outputNotes = depositOutputNotes
                const txnSender = depositorAccount.address
                const publicTokenOwner = txnSender // Owner is converting their own notes between public and private realms
                depositProof = new JoinSplitProof(
                    inputNotes, 
                    outputNotes, 
                    txnSender, 
                    depositPublicValue, 
                    publicTokenOwner
                )
                depositProofData = depositProof.encodeABI(ZKAssetContract.options.address)
                const inputNoteOwners = []
                depositSignatures = depositProof.constructSignatures(
                    ZKAssetContract.options.address, 
                    inputNoteOwners
                )
            })
            it(`- approve ACE top spend public value`, async () => {
                const signer = depositorAccount
                // Any proof that results in the transfer of public value has to be first approved by the owner of the 
                // public tokens for it to be valid. This allows ACE to transfer the value of the tokens consumed 
                // in the proof and acts as an additional security measure when dealing with ERC20s
                let _transaction = AceContract.methods.publicApprove(
                    ZKAssetContract.options.address, 
                    depositProof.hash, 
                    depositPublicValue
                )
                let _gasEstimate = await _transaction.estimateGas({ from: signer.address })
                let signedTransaction = await signer.signTransaction({
                    gas: _gasEstimate,
                    gasPrice: web3.utils.toWei('30', 'gwei'),
                    to: AceContract.options.address,
                    data: _transaction.encodeABI()
                })
                let pendingHash = await web3.eth.sendSignedTransaction(
                    signedTransaction.rawTransaction
                )
                // @DEBUG:
                // console.log(`Pending block hash: `, pendingHash.blockHash)  
                // console.log(`Pending transaction hash: `, pendingHash.transactionHash)
                assert(pendingHash.status)
            })

            /** 
             * Testing Invariants 
             * 
             * */
            let depositorBalancePreDeposit, redeemerBalancePreDeposit
            let supplyPreDeposit
            it(`- token balances and total supply are positive integers`, async () => {
                depositorBalancePreDeposit = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                redeemerBalancePreDeposit = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                supplyPreDeposit = parseFloat(await CusdContract.methods.totalSupply().call())
                assert(depositorBalancePreDeposit > 0)
                assert(redeemerBalancePreDeposit > 0)
                assert(supplyPreDeposit > 0)
            })
            let registrySupplyPreDeposit
            it(`- ACE note registry has a total supply (scalingFactor is 1e18)`, async () => {
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupplyPreDeposit = parseFloat(registryObject.totalSupply)
                assert(registrySupplyPreDeposit >= 0)
            })


            it(`- sign and send confidential transfer of JS proof`, async () => {
                const signer = depositorAccount

                // Execute confidential transfer
                let _transaction = ZKAssetContract.methods.confidentialTransfer(
                    depositProofData, 
                    depositSignatures
                )
                let _gasEstimate = await _transaction.estimateGas({ from: signer.address })
                let signedTransaction = await signer.signTransaction({
                    gas: _gasEstimate,
                    gasPrice: web3.utils.toWei('30', 'gwei'),
                    to: ZKAssetContract.options.address,
                    data: _transaction.encodeABI()
                })
                let pendingHash = await web3.eth.sendSignedTransaction(
                    signedTransaction.rawTransaction
                )
                // @DEBUG:
                // console.log(`Pending block hash: `, pendingCTHash.blockHash)  
                // console.log(`Pending Confidential Transfer hash: `, pendingHash.transactionHash)   
                assert(pendingHash.status)  
            })
            it('- notes were registered properly', async () => {
                let note
                let expectedOwners = [ depositorAccount.address, depositorAccount.address ]
                for (let i = 0; i < depositOutputNotes.length; i++) {
                    note = await AceContract.methods.getNote(
                        ZKAssetContract.options.address,
                        depositOutputNotes[i].noteHash
                    ).call()
                    assert.equal(note.noteOwner, expectedOwners[i])
                }
            })
            it('- token balances and supply match expectations', async () => {
                const expectedDepositorBalancePostDeposit = depositorBalancePreDeposit - amountToDepositWei
                const expectedRedeemerBalancePostDeposit = redeemerBalancePreDeposit
                const expectedSupplyPostDeposit = supplyPreDeposit
                const expectedRegistrySupplyPostDeposit = registrySupplyPreDeposit + amountToDeposit

                // ACE note registry
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupply = parseFloat(registryObject.totalSupply)    
                assert.equal(expectedRegistrySupplyPostDeposit, registrySupply)

                // Balances
                let balance = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                assert.equal(balance, expectedDepositorBalancePostDeposit)
                balance = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                assert.equal(balance, expectedRedeemerBalancePostDeposit)

                // Supply
                let supply = parseFloat(await CusdContract.methods.totalSupply().call())
                assert.equal(supply, expectedSupplyPostDeposit)
            })

        })

        describe('Transfer zk notes to redeemer', () => {
            /**
             * AZTEC notes
             */
            let notes
            before(async () => {
                // Create notes
                notes = [ // @dev: note amounts must be positive
                     // Notes used to transfer zk notes to redeemer
                    await note.create(redeemer.publicKey, amountToRedeem), // redeemer receives this amount
                    await note.create(depositor.publicKey, amountToDeposit-amountToRedeem) // depositor retains this amount
                ]
            })

            let transferProof 
            let transferProofData
            let transferSignatures
            it('- constructs JoinSplitProofs from Aztec.notes', async () => {
                // @dev: store output notes
                transferOutputNotes = notes

                const inputNotes = depositOutputNotes
                const outputNotes = transferOutputNotes
                const txnSender = depositorAccount.address
                const publicTokenOwner = depositorAccount.address
                transferProof = new JoinSplitProof(
                    inputNotes, 
                    outputNotes, 
                    txnSender, 
                    transferPublicValue, 
                    publicTokenOwner
                )
                transferProofData = transferProof.encodeABI(ZKAssetContract.options.address)
                const inputNoteOwners = [depositor, depositor]
                transferSignatures = transferProof.constructSignatures(
                    ZKAssetContract.options.address, 
                    inputNoteOwners
                )
            })

            /** 
             * Testing Invariants 
             * 
             * */
            let depositorBalancePreTransfer, redeemerBalancePreTransfer
            let supplyPreTransfer
            it(`- token balances and total supply are positive integers`, async () => {
                depositorBalancePreTransfer = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                redeemerBalancePreTransfer = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                supplyPreTransfer = parseFloat(await CusdContract.methods.totalSupply().call())
                assert(depositorBalancePreTransfer > 0)
                assert(redeemerBalancePreTransfer > 0)
                assert(supplyPreTransfer > 0)
            })
            let registrySupplyPreTransfer
            it(`- ACE note registry has a total supply (scalingFactor is 1e18)`, async () => {
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupplyPreTransfer = parseFloat(registryObject.totalSupply)
                assert(registrySupplyPreTransfer >= 0)
            })


            it(`- sign and send confidential transfer of JS proof`, async () => {
                const signer = depositorAccount

                // Execute confidential transfer
                let _transaction = ZKAssetContract.methods.confidentialTransfer(
                    transferProofData, 
                    transferSignatures
                )
                let _gasEstimate = await _transaction.estimateGas({ from: signer.address })
                let signedTransaction = await signer.signTransaction({
                    gas: _gasEstimate,
                    gasPrice: web3.utils.toWei('30', 'gwei'),
                    to: ZKAssetContract.options.address,
                    data: _transaction.encodeABI()
                })
                let pendingHash = await web3.eth.sendSignedTransaction(
                    signedTransaction.rawTransaction
                )
                // @DEBUG:
                // console.log(`Pending block hash: `, pendingCTHash.blockHash)  
                // console.log(`Pending Confidential Transfer hash: `, pendingHash.transactionHash)   
                assert(pendingHash.status)  
            })
            it('- notes were registered properly', async () => {
                let note
                let expectedOwners = [ redeemerAccount.address, depositorAccount.address ]
                for (let i = 0; i < transferOutputNotes.length; i++) {
                    note = await AceContract.methods.getNote(
                        ZKAssetContract.options.address,
                        transferOutputNotes[i].noteHash
                    ).call()
                    assert.equal(note.noteOwner, expectedOwners[i])
                }
            })
            it('- token balances and supply match expectations', async () => {
                const expectedDepositorBalancePostTransfer = depositorBalancePreTransfer
                const expectedRedeemerBalancePostTransfer = redeemerBalancePreTransfer
                const expectedSupplyPostTransfer = supplyPreTransfer
                const expectedRegistrySupplyPostTransfer = registrySupplyPreTransfer
    
                // ACE note registry
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupply = parseFloat(registryObject.totalSupply)    
                assert.equal(expectedRegistrySupplyPostTransfer, registrySupply)

                // Balances
                let balance = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                assert.equal(balance, expectedDepositorBalancePostTransfer)
                balance = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                assert.equal(balance, expectedRedeemerBalancePostTransfer)

                // Supply
                let supply = parseFloat(await CusdContract.methods.totalSupply().call())
                assert.equal(supply, expectedSupplyPostTransfer)
            })
        })

        describe('Redeem zk notes for ERC20 tokens', () => {
            /**
             * AZTEC notes
             */
            let notes
            before(async () => {
                // Create notes
                notes = [ transferOutputNotes[0] ]
            })

            let redeemProof 
            let redeemProofData
            let redeemSignatures
            it('- constructs JoinSplitProofs from Aztec.notes', async () => {
                // @dev: store output notes
                redeemOutputNotes = notes

                const inputNotes = redeemOutputNotes
                const outputNotes = []
                const txnSender = redeemerAccount.address
                const publicTokenOwner = redeemerAccount.address
                redeemProof = new JoinSplitProof(
                    inputNotes, 
                    outputNotes, 
                    txnSender, 
                    redeemPublicValue, 
                    publicTokenOwner
                )
                redeemProofData = redeemProof.encodeABI(ZKAssetContract.options.address)
                const inputNoteOwners = [redeemer]
                redeemSignatures = redeemProof.constructSignatures(
                    ZKAssetContract.options.address, 
                    inputNoteOwners
                )
            })
            it(`- approve ACE top spend public value`, async () => {
                const signer = redeemerAccount
                // Any proof that results in the transfer of public value has to be first approved by the owner of the 
                // public tokens for it to be valid. This allows ACE to transfer the value of the tokens consumed 
                // in the proof and acts as an additional security measure when dealing with ERC20s
                let _transaction = AceContract.methods.publicApprove(
                    ZKAssetContract.options.address, 
                    redeemProof.hash, 
                    redeemPublicValue
                )
                let _gasEstimate = await _transaction.estimateGas({ from: signer.address })
                let signedTransaction = await signer.signTransaction({
                    gas: _gasEstimate,
                    gasPrice: web3.utils.toWei('30', 'gwei'),
                    to: AceContract.options.address,
                    data: _transaction.encodeABI()
                })
                let pendingHash = await web3.eth.sendSignedTransaction(
                    signedTransaction.rawTransaction
                )
                // @DEBUG:
                // console.log(`Pending block hash: `, pendingHash.blockHash)  
                // console.log(`Pending transaction hash: `, pendingHash.transactionHash)
                assert(pendingHash.status)
            })

            /** 
             * Testing Invariants 
             * 
             * */
            let depositorBalancePreRedeem, redeemerBalancePreRedeem
            let supplyPreRedeem
            it(`- token balances and total supply are positive integers`, async () => {
                depositorBalancePreRedeem = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                redeemerBalancePreRedeem = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                supplyPreRedeem = parseFloat(await CusdContract.methods.totalSupply().call())
                assert(depositorBalancePreRedeem > 0)
                assert(redeemerBalancePreRedeem > 0)
                assert(supplyPreRedeem > 0)
            })
            let registrySupplyPreRedeem
            it(`- ACE note registry has a total supply (scalingFactor is 1e18)`, async () => {
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupplyPreRedeem = parseFloat(registryObject.totalSupply)
                assert(registrySupplyPreRedeem >= 0)
            })
            it(`- sign and send confidential transfer of JS proof`, async () => {
                const signer = redeemerAccount

                // Execute confidential transfer
                let _transaction = ZKAssetContract.methods.confidentialTransfer(
                    redeemProofData, 
                    redeemSignatures
                )
                let _gasEstimate = await _transaction.estimateGas({ from: signer.address })
                let signedTransaction = await signer.signTransaction({
                    gas: _gasEstimate,
                    gasPrice: web3.utils.toWei('30', 'gwei'),
                    to: ZKAssetContract.options.address,
                    data: _transaction.encodeABI()
                })
                let pendingHash = await web3.eth.sendSignedTransaction(
                    signedTransaction.rawTransaction
                )
                // @DEBUG:
                // console.log(`Pending block hash: `, pendingCTHash.blockHash)  
                // console.log(`Pending Confidential Transfer hash: `, pendingHash.transactionHash)   
                assert(pendingHash.status)  
            })
            it('- notes were registered properly', async () => {
                let note
                let expectedOwners = [ redeemerAccount.address ]
                for (let i = 0; i < redeemOutputNotes.length; i++) {
                    note = await AceContract.methods.getNote(
                        ZKAssetContract.options.address,
                        transferOutputNotes[i].noteHash
                    ).call()
                    assert.equal(note.noteOwner, expectedOwners[i])
                }
            })
            it('- token balances and supply match expectations', async () => {
                const expectedDepositorBalancePostRedeem = depositorBalancePreRedeem
                const expectedRedeemerBalancePostRedeem = redeemerBalancePreRedeem + amountToRedeemWei
                const expectedSupplyPostRedeem = supplyPreRedeem
                const expectedRegistrySupplyPostRedeem = registrySupplyPreRedeem - amountToRedeem
    
                // ACE note registry
                let registryObject = await AceContract.methods.getRegistry(ZKAssetContract.options.address).call()
                registrySupply = parseFloat(registryObject.totalSupply)    
                assert.equal(expectedRegistrySupplyPostRedeem, registrySupply)

                // Balances
                let balance = parseFloat(await CusdContract.methods.balanceOf(depositorAccount.address).call())
                assert.equal(balance, expectedDepositorBalancePostRedeem)
                balance = parseFloat(await CusdContract.methods.balanceOf(redeemerAccount.address).call())
                assert.equal(balance, expectedRedeemerBalancePostRedeem)

                // Supply
                let supply = parseFloat(await CusdContract.methods.totalSupply().call())
                assert.equal(supply, expectedSupplyPostRedeem)
            })
        })
    })
})