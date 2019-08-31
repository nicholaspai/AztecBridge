const ZkAsset = artifacts.require('./ZkAsset.sol');

module.exports = async (deployer, network) => {
  if (network === 'ropsten') {
    const aztecContractAddresses = require('@aztec/contract-addresses')
    const networkIdMap = aztecContractAddresses.NetworkId
    const ropstenAddresses = aztecContractAddresses.getContractAddressesForNetwork(networkIdMap['Ropsten'])
    await deployer.deploy(
      ZkAsset,
      ropstenAddresses.ACE,
      '0x67450c8908e2701abfa6745be3949ad32acf42d8',
      1
    );  
  }
};
