import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { HyperclusterFactory } from "../typechain-types";


describe("Hypercluster", function() {

  async function generateFixtures() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const lockedAmount = ONE_GWEI;
    const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const HCF = await ethers.getContractFactory("HyperclusterFactory");
    const hyperclusterfactory = await HCF.deploy();

    return { hyperclusterfactory, unlockTime, lockedAmount, owner, otherAccount };
  }

  describe("local tests", function() {
 
    it("Should get the address of a newly deployed campaign", async function() {
      let {hyperclusterfactory, unlockTime, lockedAmount, owner, otherAccount}  = await loadFixture(generateFixtures);
    
      const campaign = await hyperclusterfactory.createCampaign("Test Campaign", "0xae6444fEb36d2B0e4Dc93f1f012882d7C5DB8F2D", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E");
      const campaign2 = await hyperclusterfactory.createCampaign("Test Campaign 2", "0xae6444fEb36d2B0e4Dc93f1f012882d7C5DB8F2D", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E");
      console.log(await hyperclusterfactory.getCampaigns())
      

     
    });

  })

  describe("integration tests", function() {


    it("should set status to active upon getting funded", async function() {

    })

    it("should correctly fetch the price of reward token on deposition", async function() {
      
    })
  

  })



  describe("Create Campaigns", function() {
  
    

    it("should correctly set status to active when token is deposited", async function() {
      
    })

    it("should correctly fetch prices")

  })


  describe("Add referrers", function() {

 
  })



  describe("Withdraw", function() {

  })

})