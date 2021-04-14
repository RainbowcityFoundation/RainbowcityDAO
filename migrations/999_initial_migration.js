const ERC20Orchestrator = artifacts.require("ERC20Orchestrator");
const ERC20Orchestrator2 = artifacts.require("ERC20Orchestrator2");
const RbBankOrchestrator = artifacts.require("RbBankOrchestrator");
const RbtDepositOrchestrator = artifacts.require("RbtDepositOrchestrator");
const RbBank = artifacts.require("RainbowBank");
const RbtDeposit = artifacts.require("RbtDeposit721");
const ExchangeGovernance721Orchestrator = artifacts.require("ExchangeGovernance721Orchestrator");
const ExchangeGovernance721 = artifacts.require("ExchangeGovernance721");
const RBTCitynode = artifacts.require("RBTCitynode");
const RBTCitynodeOrchestrator = artifacts.require("RBTCitynodeOrchestrator");
const TokenExchangeMarketOrchestrator = artifacts.require("TokenExchangeMarketOrchestrator");
const TokenExchangeMarket = artifacts.require("TokenExchangeMarket");
const LoanMarketOrchestrator = artifacts.require("LoanMarketOrchestrator");
const LoanMarket = artifacts.require("LoanMarket");
const VipExchangeMarketOrchestrator = artifacts.require("VipExchangeMarketOrchestrator");
const VipExchangeMarket = artifacts.require("VipExchangeMarket");
const addressList = require("./addressList.json");

//mining
const RbConsensusOrchestrator = artifacts.require("RbConsensusOrchestrator");
const RbContributionOrchestrator = artifacts.require("RbContributionOrchestrator");
const RbinviteOrchestrator = artifacts.require("RbinviteOrchestrator");
const RbSeedExchangeOrchestrator = artifacts.require("RbSeedExchangeOrchestrator");
const RbSeedSubscriptionOrchestrator = artifacts.require("RbSeedSubscriptionOrchestrator");
const RbConsensus = artifacts.require("RbConsensus");
const RbContribution = artifacts.require("RbContribution");
const Rbinvite = artifacts.require("Rbinvite");
const RbSeedExchange = artifacts.require("RbSeedExchange");
const RbSeedSubscription = artifacts.require("RbSeedSubscription");
const RBT = artifacts.require("RBT");
const RBD = artifacts.require("RBD");
const RBB = artifacts.require("RBB");
const RBTC = artifacts.require("RBTC");
const RUSD = artifacts.require("RUSD");
const RBTEX = artifacts.require("RBTEX");
const RBTSEED = artifacts.require("RBTSeed");
const Core = artifacts.require("Core");
//const FoundationAddress = artifacts.require("Foundation");
const RbtVipOrchestrator = artifacts.require("RbtVipOrchestrator");
const RbtVoteOrchestrator = artifacts.require("RbtVoteOrchestrator");
const GovOrchestrator = artifacts.require("GovOrchestrator");
const GovOrchestrator2 = artifacts.require("GovOrchestrator2");
const FourRBTCommunityOrchestrator = artifacts.require("FourRBTCommunityOrchestrator");
const FourRBTCommunityOrchestrator2 = artifacts.require("FourRBTCommunityOrchestrator2");
const FundManagementOrchestrator = artifacts.require("FundManagementOrchestrator");
const FundManagement = artifacts.require("FundManagement");
const CityNode = artifacts.require("CityNode");
const VoteId = artifacts.require("VoteId");
const Impeach = artifacts.require("Impeach");
const Vote = artifacts.require("RainbowRbtVote");
const RainbowRbtVip = artifacts.require("RainbowRbtVip");
const RBTCommunityCharitableFund = artifacts.require("RBTCommunityCharitableFund");
const RBTCommunityGovernanceFund = artifacts.require("RBTCommunityGovernanceFund");
const RBTCommunityInvestmentFund = artifacts.require("RBTCommunityInvestmentFund");
const RBTCommunityRewardFund = artifacts.require("RBTCommunityRewardFund");
module.exports = function(deployer) {

    //定义 rbtEx, rbtVipOrchestrator,core,erc20Orchestrator,erc20Orchestrator2地址
    var rbtEx;


    var govOrchestrator;
    var govOrchestrator2;
    var fourRBTCommunityOrchestrator;
    var fourRBTCommunityOrchestrator2;
    var fundManagementOrchestrator;
    var fundManagement;
    var citynodeAddress;
    var voteIdAddress;
    var rbt;

    var rbConsensusOrchestrator;
    var rbContributionOrchestrator;
    var rbSeedExchangeOrchestrator;
    var rbSeedSubscriptionOrchestrator;
    var rbinviteOrchestrator;

    //定义 rbtEx, rbtVipOrchestrator,core,erc20Orchestrator,erc20Orchestrator2地址
    let rbBankOrchestrator, rbtDepositOrchestrator;
    let bank, deposit, exchange721, exchangeGovernance721s, tokenExchanges, tokenExchange, loanMarkets, loanMarket, rbtCitynodes, rbtCitynodeOrchestrators;
    //定义 rbtEx, rbtVipOrchestrator,core,erc20Orchestrator,erc20Orchestrator2地址
    let rbtVipOrchestrator, core, vipExchangeMarkets, vipExchange;
    let erc20Orchestrator, erc20Orchestrator2;
    let rbtAddress, rbdAddress, rbtexAddress, rbtSeedAddress, rbConsensus, rbContribution, rbSeedExchange, rbSeedSubscription, rbInviteInstance;
    let rbbAddress, rbtcAddress, rusdAddress, voteAddress;
    let vipAddress;
    let adminAddress;

    deployer.then(function() {
            //获取ERC20Orchestrator部署实例
            return ERC20Orchestrator.deployed();
        }).then(function(instance) {
            erc20Orchestrator = instance;
            //获取ERC20Orchestrator2部署实例
            return ERC20Orchestrator2.deployed();
        }).then(function(instance) {
            erc20Orchestrator2 = instance;
            //erc20Orchestrator 初始化，部署 rbt，rbd，rbtex,rbtseed
            return erc20Orchestrator.init(addressList["address"]);
        }).then(function(instance) {
            //erc20Orchestrator2 初始化,部署 rbb，rusd,rbtc
            return erc20Orchestrator2.init(addressList["address"]);
        }).then(function(instance) {
            return Core.deployed();
        }).then(function(instance) {
            //获取到core地址
            core = instance.address;
        }).then(function() {
            //获取erc20Orchestrator 中rbtex的地址
            return erc20Orchestrator.rbtex()
        }).then(function(instance) {
            //获取到rbtex地址
            return rbtexAddress = instance;
        }).then(function() {
            return RbtVipOrchestrator.deployed();
        }).then(function(instance) {
            rbtVipOrchestrator = instance;
            //初始化rbtVipOrchestrator部署vip合约
            return rbtVipOrchestrator.init(100, core, rbtexAddress, core);
        }).then(function() {
            //通过rbtVipOrchestrator获取vip的地址
            return rbtVipOrchestrator.vipAddress()
        }).then(function(instance) {
            //获取到vip部署合约的地址
            return vipAddress = instance;
        }).then(function() {
            RainbowRbtVip.networks["1234"] = { address: vipAddress };
            return RbtVoteOrchestrator.deployed();
        }).then(function(instance) {
            rbtVoteOrchestrator = instance;
            //初始化rbtVoteOrchestrator部署vote合约
            return rbtVoteOrchestrator.init(vipAddress, core);
        }).then(function() {
            //通过rbtVoteOrchestrator获取vote的地址
            return rbtVoteOrchestrator.voteAddress();
        }).then(function(instance) {
            //通过rbtVoteOrchestrator获取vote的地址
            voteAddress = instance;
        }).then(function(instance) {
            return RbBankOrchestrator.deployed();
        }).then(function(instance) {
            rbBankOrchestrator = instance;
            return RbtDepositOrchestrator.deployed();
        }).then(function(instance) {
            rbtDepositOrchestrator = instance;
        }).then(function(instance) {
            return rbBankOrchestrator.init(core);
        }).then(function() {
            //返回银行地址
            return rbBankOrchestrator.bank();
        }).then(function(instance) {
            bank = instance;
            return rbtDepositOrchestrator.init(core);
        }).then(function(instance) {
            //返回rbt地址
            return erc20Orchestrator.rbt();
        }).then(function(instance) {
            rbtAddress = instance;
            //返回deposit地址
            return rbtDepositOrchestrator.deposit();
        }).then(function(instance) {
            deposit = instance;
            return rbBankOrchestrator.input(rbtAddress, deposit);
        }).then(function(instance) {
            return rbtDepositOrchestrator.input(bank);

        }).then(function() {
            return GovOrchestrator.deployed();
        }).then(function(instance) {
            govOrchestrator = instance;
            return govOrchestrator.init(core);
        }).then(function(instance) {
            return govOrchestrator.cityNode();
        }).then(function(instance) {
            citynodeAddress = instance;
            CityNode.networks["1234"] = { address: citynodeAddress }
            console.log(citynodeAddress);
        }).then(function(instance) {
            return govOrchestrator.voteId();
        }).then(function(instance) {
            voteIdAddress = instance;
            VoteId.networks["1234"] = { address: voteIdAddress }
            console.log(voteIdAddress);
        }).then(function() {
            return GovOrchestrator2.deployed();
        }).then(function(instance) {
            govOrchestrator2 = instance;
            return govOrchestrator2.init(core, citynodeAddress, voteIdAddress);
        }).then(function() {
            return govOrchestrator2.impeach();
        }).then(function(instance) {
            Impeach.networks["1234"] = { address: instance }
        }).then(function() {
            return govOrchestrator2.vote();
        }).then(function(instance) {
            Vote.networks["1234"] = { address: voteAddress }
        }).then(function() {
            return FourRBTCommunityOrchestrator.deployed();
        }).then(function(instance) {
            fourRBTCommunityOrchestrator = instance;
            return fourRBTCommunityOrchestrator.init(core, voteIdAddress);
        }).then(function() {
            return fourRBTCommunityOrchestrator.RBTCommunityCharitableFundAddr();
        }).then(function(instance) {
            RBTCommunityCharitableFund.networks["1234"] = { address: instance }
        }).then(function() {
            return fourRBTCommunityOrchestrator.RBTCommunityGovernanceFundAddr();
        }).then(function(instance) {
            RBTCommunityGovernanceFund.networks["1234"] = { address: instance }
        }).then(function() {
            return FourRBTCommunityOrchestrator2.deployed();
        }).then(function(instance) {
            fourRBTCommunityOrchestrator2 = instance;
            return fourRBTCommunityOrchestrator2.init(core, voteIdAddress);
        }).then(function() {
            return fourRBTCommunityOrchestrator2.RBTCommunityInvestmentFundAddr();
        }).then(function(instance) {
            RBTCommunityInvestmentFund.networks["1234"] = { address: instance }
        }).then(function() {
            return fourRBTCommunityOrchestrator2.RBTCommunityRewardFundAddr();
        }).then(function(instance) {
            RBTCommunityRewardFund.networks["1234"] = { address: instance }
        }).then(function() {
            return FundManagementOrchestrator.deployed();
        }).then(function(instance) {
            fundManagementOrchestrator = instance;
            return fundManagementOrchestrator.init(core, voteIdAddress);
        }).then(function(instance) {
            return fundManagementOrchestrator.FundManagementAddr();
        }).then(function(instance) {
            FundManagement.networks["1234"] = { address: instance }
        }).then(() => {
            console.log("RBT:", rbtAddress);
            RBT.networks[1234] = { address: rbtAddress }
            return erc20Orchestrator.rbd()
        }).then(address => {
            rbdAddress = address;
            console.log("RBD:", rbdAddress);
            RBD.networks[1234] = { address: rbdAddress }
            return erc20Orchestrator.rbtex()
        }).then(address => {
            rbtexAddress = address;
            console.log("RBTEX:", rbtexAddress);
            RBTEX.networks[1234] = { address: rbtexAddress }
            return erc20Orchestrator.rbtseed()
        }).then(address => {
            rbtSeedAddress = address;
            console.log("SEED:", rbtSeedAddress);
            RBTSEED.networks[1234] = { address: rbtSeedAddress }
            return erc20Orchestrator2.rbb()
        }).then(address => {
            rbbAddress = address;
            console.log("RBB:", rbbAddress);
            RBB.networks[1234] = { address: rbbAddress }
            return erc20Orchestrator2.rbtc()
        }).then(address => {
            rbtcAddress = address;
            console.log("RBTC:", rbtcAddress);
            RBTC.networks[1234] = { address: rbtcAddress }
            return erc20Orchestrator2.rusd()
        }).then(address => {
            rusdAddress = address;
            console.log("RUSD:", rusdAddress);
            RUSD.networks[1234] = { address: rusdAddress }
            return RbConsensusOrchestrator.deployed()
        }).then(instance => {
            rbConsensusOrchestrator = instance
            return rbConsensusOrchestrator.init(rbtAddress, vipAddress);
        }).then(instance => {
            return rbConsensusOrchestrator.rbConsersusAddress();
        }).then(instance => {
            rbConsensus = instance;
            console.log("consensus", rbConsensus)
            RbConsensus.networks["1234"] = {
                address: rbConsensus
            }
            return RbContributionOrchestrator.deployed();
        }).then(instance => {
            rbContributionOrchestrator = instance;
            return rbContributionOrchestrator.init(rbdAddress, rbtAddress);
        }).then(instance => {
            return rbContributionOrchestrator.rbcontributionAddress();
        }).then(instance => {
            rbContribution = instance;
            console.log("rbcontribution", rbContribution)
            RbContribution.networks["1234"] = {
                address: rbContribution
            }
            return RbSeedExchangeOrchestrator.deployed();
        }).then(instance => {
            rbSeedExchangeOrchestrator = instance;
            return rbSeedExchangeOrchestrator.init(rbtSeedAddress, rbtAddress)
        })
        .then(instance => {
            return rbSeedExchangeOrchestrator.rbSeedExchangeAddress()
        }).then(instance => {
            rbSeedExchange = instance;
            console.log("rbseedexchange", rbSeedExchange)
            RbSeedExchange.networks["1234"] = {
                address: rbSeedExchange
            }
            return RbSeedSubscriptionOrchestrator.deployed();
        }).then(instance => {
            rbSeedSubscriptionOrchestrator = instance;
            return rbSeedSubscriptionOrchestrator.init(rbtSeedAddress)
        }).then(instance => {
            return rbSeedSubscriptionOrchestrator.RbSeedSubscriptionAddress()
        }).then(instance => {
            rbSeedSubscription = instance;
            console.log("rbSeedSubscription", rbSeedSubscription)
            RbSeedSubscription.networks["1234"] = {
                address: rbSeedSubscription
            }
            return RbinviteOrchestrator.deployed();
        }).then(instance => {
            rbinviteOrchestrator = instance;
            return rbinviteOrchestrator.init(rbtexAddress, rbtAddress, rbConsensus)
        }).then(instance => {
            return rbinviteOrchestrator.rbinviteAddress()
        }).then(instance => {
            rbinvite = instance;
            console.log("rbinvite", rbinvite)
            Rbinvite.networks["1234"] = {
                address: rbinvite
            }
        }).then(function() {
            return RbBankOrchestrator.deployed();
        }).then(function(instance) {
            rbBankOrchestrator = instance;
            return RbtDepositOrchestrator.deployed();
        }).then(function(instance) {
            rbtDepositOrchestrator = instance;
        }).then(function(instance) {
            return rbBankOrchestrator.init(core);
        }).then(function() {
            //返回银行地址
            return rbBankOrchestrator.bank();
        }).then(function(instance) {
            bank = instance;
            RbBank.networks["1234"] = { address: bank }
            return rbtDepositOrchestrator.init(core);
        }).then(function(instance) {
            return rbtDepositOrchestrator.deposit();
        }).then(function(instance) {
            deposit = instance;
            RbtDeposit.networks["1234"] = { address: deposit };
            return rbBankOrchestrator.input(rbtAddress, deposit);
        }).then(function(instance) {
            return rbtDepositOrchestrator.input(bank);
        }).then(function(instance) {
            return ExchangeGovernance721Orchestrator.deployed();
        }).then(function(instance) {
            exchangeGovernance721s = instance;
            return exchangeGovernance721s.init(core, deposit);

        }).then(function(instance) {
            return exchangeGovernance721s.exchangeGovernance721();
        }).then(function(instance) {
            exchange721 = instance
            ExchangeGovernance721.networks["1234"] = { address: exchange721 };
            return exchangeGovernance721s.elf();
        }).then(function(instance) {
            elf = instance;
            ExchangeGovernance721.networks["elf"] = { address: elf };
            return exchangeGovernance721s.envoy();
        }).then(function(instance) {
            envoy = instance;
            ExchangeGovernance721.networks["envoy"] = { address: envoy };
            return exchangeGovernance721s.partner();
        }).then(function(instance) {
            partner = instance;
            ExchangeGovernance721.networks["partner"] = { address: partner };
            return exchangeGovernance721s.node();
        }).then(function(instance) {
            node = instance;
            ExchangeGovernance721.networks["node"] = { address: node };
            return RBTCitynodeOrchestrator.deployed();
        }).then(function(instance) {
            rbtCitynodeOrchestrators = instance;
            return rbtCitynodeOrchestrators.init(core, exchange721);
        }).then(function(instance) {
            return rbtCitynodeOrchestrators.rbtCitynode();
        }).then(function(instance) {
            rbtCitynodes = instance;
            RBTCitynode.networks["1234"] = { address: rbtCitynodes };
            return exchangeGovernance721s.initCitynode(rbtCitynodes);
        }).then(function(instance) {
            return TokenExchangeMarketOrchestrator.deployed();
        }).then(function(instance) {
            tokenExchanges = instance;
            return tokenExchanges.init(core, rbtAddress, elf, envoy, partner, node);
        }).then(function(instance) {
            return tokenExchanges.tokenExchange();


        }).then(function(instance) {
            tokenExchange = instance
            TokenExchangeMarket.networks["1234"] = { address: tokenExchange };
            return LoanMarketOrchestrator.deployed();
        }).then(function(instance) {
            loanMarkets = instance;
            return loanMarkets.init(core, rbtAddress, deposit);
        }).then(function(instance) {
            return loanMarkets.loanMarket();
        }).then(function(instance) {
            loanMarket = instance
            LoanMarket.networks["1234"] = { address: loanMarket }

        }).then(function(instance) {
            return VipExchangeMarketOrchestrator.deployed();
        }).then(function(instance) {
            vipExchangeMarkets = instance;
            return vipExchangeMarkets.init(core, rbtAddress, vipAddress);
        }).then(function(instance) {
            return vipExchangeMarkets.vipExchange();
        }).then(function(instance) {
            vipExchange = instance;
            VipExchangeMarket.networks["1234"] = { address: vipExchange };
        })
};