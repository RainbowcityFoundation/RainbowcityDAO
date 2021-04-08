const ERC20Orchestrator = artifacts.require("ERC20Orchestrator");
const ERC20Orchestrator2 = artifacts.require("ERC20Orchestrator2");

module.exports = function (deployer) {
  deployer.deploy(ERC20Orchestrator);
  deployer.deploy(ERC20Orchestrator2);
};
