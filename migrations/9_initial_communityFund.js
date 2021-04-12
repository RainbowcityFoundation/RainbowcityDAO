const FourRBTCommunityOrchestrator = artifacts.require("FourRBTCommunityOrchestrator");
const FourRBTCommunityOrchestrator2 = artifacts.require("FourRBTCommunityOrchestrator2");


module.exports = function (deployer) {
    deployer.deploy(FourRBTCommunityOrchestrator);
    deployer.deploy(FourRBTCommunityOrchestrator2);
};

