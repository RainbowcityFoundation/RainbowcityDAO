const VipExchangeMarketOrchestrator = artifacts.require("VipExchangeMarketOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(VipExchangeMarketOrchestrator);
};
