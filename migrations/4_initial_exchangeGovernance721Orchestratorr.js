const ExchangeGovernance721Orchestrator = artifacts.require("ExchangeGovernance721Orchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(ExchangeGovernance721Orchestrator);
};
