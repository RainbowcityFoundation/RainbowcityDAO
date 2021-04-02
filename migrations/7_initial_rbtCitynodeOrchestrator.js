const RBTCitynodeOrchestrator = artifacts.require("RBTCitynodeOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(RBTCitynodeOrchestrator);
};
