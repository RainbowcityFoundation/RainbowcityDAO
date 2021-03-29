const TokenExchangeMarketOrchestrator = artifacts.require("TokenExchangeMarketOrchestrator");

module.exports = function (deployer) {
  
  deployer.deploy(TokenExchangeMarketOrchestrator);
};
