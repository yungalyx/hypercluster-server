import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { HyperclusterFactory } from "../typechain-types";
import hcc_json from "../artifacts/contracts/HyperclusterCampaign.sol/HyperclusterCampaign.json"
import { equal } from "assert";
import {ERC20ABI} from "../src/helpers/ABI";
import { generateReferralLink } from "../src/helpers/referral";


describe("Hypercluster", function() {


  async function mainnetFixtures() {
    
    // set up impersonater
    
    const impersonate = "0xC72d57b880A988D120141f09328F7daEf527a8b0";
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [impersonate],
    });
    const impersonater = await ethers.getSigner(impersonate);
    

    const [Alice] = await ethers.getSigners();

    // set up test addresses 
    const WETH = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
    const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"; //"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const DAI =  "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";// "0x6B175474E89094C44Da98b954EedeAC495271d0F";


    const mainnet_function_router = "0x65Dcc24F8ff9e51F10DCc7Ed1e4e2A61e6E14bd6";

    // price feeds
    const ETH_APE_USD = "0xD10aBbC76679a20055E167BB80A24ac851b37056";

    



    // deploy facotry 
    const HyperclusterFactoryContract = await ethers.getContractFactory("HyperclusterFactory");
    const hyperclusterfactory = await HyperclusterFactoryContract.deploy(mainnet_function_router);
    await hyperclusterfactory.waitForDeployment()


    
    let usdc_contract = new ethers.Contract(USDC, ERC20ABI, impersonater);
   
    const dai_contract = new ethers.Contract(DAI, ERC20ABI, impersonater)
  
    // const weth_contract = new ethers.Contract(WETH, utils.ercAbi, impersonater)
    return { hyperclusterfactory, Alice, WETH, USDC, DAI, mainnet_function_router, ETH_APE_USD, impersonater, dai_contract, usdc_contract };


  }

  describe("local tests", function() {
 
    it("Should get the address of a newly deployed campaign", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater}  = await loadFixture(mainnetFixtures);

      await hyperclusterfactory.createCampaign("Test Campaign", USDC, ETH_APE_USD); // constructors do not return any data

      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];

      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);
     
      expect(await hyperclusterCampaign.getAddress()).to.equal(address);
    
    });


    it("Should get price from a new campaign", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater}  = await loadFixture(mainnetFixtures);
      const campaign = await hyperclusterfactory.createCampaign("Test Campdwaign", USDC, ETH_APE_USD);
      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];
   
      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);
     
      console.log(await hyperclusterCampaign.getStartPrice()) // 8 contract decimals apparently 
      
    });

    it("Should correctly set status to active when token is deposited", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater, usdc_contract}  = await loadFixture(mainnetFixtures);
      const campaign = await hyperclusterfactory.createCampaign("Test Campdwaign", USDC, ETH_APE_USD);
      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];
   
      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);
    
      const approval = await usdc_contract.connect(impersonater).approve(address, '99999999999999999999999999'); // approves swapRouter address 
    
      await hyperclusterCampaign.connect(impersonater).deposit(500);

      expect(await hyperclusterCampaign.isActive()).to.equal(true);

      
    });

    it("Should disallow adding referrals when contract is not active", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater, usdc_contract, Alice}  = await loadFixture(mainnetFixtures);
      const campaign = await hyperclusterfactory.createCampaign("Test Campdwaign", USDC, ETH_APE_USD);
      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];
   
      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);
    
      const refLink = generateReferralLink(impersonater.address, "Test Capdwaign");
      await expect(hyperclusterCampaign.connect(impersonater).acceptReferral(Alice.address, refLink)).to.be.revertedWith("Campaign is not active");

    })


    it("Should disallow adding yourself", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater, usdc_contract, Alice}  = await loadFixture(mainnetFixtures);
      const campaign = await hyperclusterfactory.createCampaign("Test Campdwaign", USDC, ETH_APE_USD);
      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];
   
      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);

      // activates campaign
      const approval = await usdc_contract.connect(impersonater).approve(address, '99999999999999999999999999'); // approves swapRouter address 
      await hyperclusterCampaign.connect(impersonater).deposit(500);

      // adds yourself
      const refLink = generateReferralLink(impersonater.address, "Test Capdwaign");

      await expect(hyperclusterCampaign.connect(impersonater).acceptReferral(impersonater.address, refLink)).to.be.revertedWith("You cannot refer yourself");

    })

    it("Should allow valid referrals to be added", async function() {
      let {hyperclusterfactory, USDC, ETH_APE_USD, impersonater, usdc_contract, Alice}  = await loadFixture(mainnetFixtures);
      const campaign = await hyperclusterfactory.createCampaign("Test Campdwaign", USDC, ETH_APE_USD);
      const campaigns = await hyperclusterfactory.getCampaigns();
      const address = campaigns[0];
   
      let hyperclusterCampaign = new ethers.Contract(address, hcc_json.abi, impersonater);


      // activates campaign
      const approval = await usdc_contract.connect(impersonater).approve(address, '99999999999999999999999999'); // approves swapRouter address 
      await hyperclusterCampaign.connect(impersonater).deposit(500);

      // adds someone else
      const refLink = generateReferralLink(impersonater.address, "Test Capdwaign");
      await hyperclusterCampaign.connect(impersonater).acceptReferral(Alice.address, refLink);

      console.log(await hyperclusterCampaign.getUser(impersonater.address))

      expect(await hyperclusterCampaign.getUser(impersonater.address)).to.equal(refLink);

    })

    it("Should correctly distribute rewards to the correct caller", async function() {



    })


  })

})