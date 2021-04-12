// const Core = artifacts.require("Core");
// const RBTEX = artifacts.require("RBTEX");
// const FoundationAddress = artifacts.require("Foundation");
const GovOrchestrator = artifacts.require("GovOrchestrator");


module.exports = function (deployer) {
    deployer.deploy(GovOrchestrator);

};
