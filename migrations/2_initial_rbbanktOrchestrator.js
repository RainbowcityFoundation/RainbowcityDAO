const RbBankOrchestrator = artifacts.require("RbBankOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(RbBankOrchestrator);
};
