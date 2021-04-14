const FundManagementOrchestrator = artifacts.require("FundManagementOrchestrator");

module.exports = function (deployer) {

    deployer.deploy(FundManagementOrchestrator);
};