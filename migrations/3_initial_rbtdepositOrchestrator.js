const RbtDepositOrchestrator = artifacts.require("RbtDepositOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(RbtDepositOrchestrator);
};
