const LoanMarketOrchestrator = artifacts.require("LoanMarketOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(LoanMarketOrchestrator);
};
