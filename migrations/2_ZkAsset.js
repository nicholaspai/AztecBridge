const ZkAsset = artifacts.require('./ZkAsset.sol');
const ZkAssetMintable = artifacts.require('./ZkAssetMintable.sol');
const ERC20_SCALING_FACTOR = 1000000000000000000
const LINKED_ERC20_ADDRESS = '0x67450c8908e2701abfa6745be3949ad32acf42d8'

module.exports = async (deployer, network) => {
  if (network === 'ropsten') {
    const aztecContractAddresses = require('@aztec/contract-addresses')
    const networkIdMap = aztecContractAddresses.NetworkId
    const ropstenAddresses = aztecContractAddresses.getContractAddressesForNetwork(networkIdMap['Ropsten'])
    
    // Public => Private
    await deployer.deploy(
      ZkAsset,
      ropstenAddresses.ACE,
      LINKED_ERC20_ADDRESS,
      ERC20_SCALING_FACTOR.toString(10)
    );  
    
    // Private native
    await deployer.deploy(
      ZkAssetMintable,
      ropstenAddresses.ACE,
      LINKED_ERC20_ADDRESS,
      ERC20_SCALING_FACTOR.toString(10),
    );
  }
};
