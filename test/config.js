require('dotenv').config() 
module.exports = {
    web3Provider: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
    networkName: `Ropsten`,
    tokensToMint: 10,
    // ZK Settings
    scaleFactor: 1e18,
    // User Roles:
    depositorKey: process.env.ROPSTEN_CUSD_USER, // Creates new zk CUSD
    redeemerKey: process.env.ROPSTEN_CUSD_USER_2, // Redeems zk CUSD for ERC20 CUSD
    // Admin Roles:
    minterKey: process.env.CUSD_MINTER_ROPSTEN // Allowed to issue new CUSD to users

}