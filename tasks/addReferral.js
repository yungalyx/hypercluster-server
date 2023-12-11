const fs = require("fs")
task("add-referral", "Adds a referral to the network").setAction(async (taskArgs, hre) => {
  // const referralCode = ""
  // const slotId = ""
  // const slotVersion = ""
  // try {
  //   const functionHash = ethers.utils.id("addReferral(string,uint8,uint64)").slice(0, 10)
  //   const encodedData = ethers.utils.defaultAbiCoder
  //     .encode(["string", "uint8", "uint64"], [referralCode, slotId, slotVersion])
  //     .slice(2)
  //   const data = functionHash + encodedData
  //   console.log("\nDATA\n\n" + data + "\n\n")
  // } catch (error) {
  //   console.log(error)
  // }

  const functionHash = ethers.utils
    .id("createCampaign((string,string,address,address,uint256,uint256,uint256,uint256,uint256,address))")
    .slice(0, 10)
  const encodedDataa = ethers.utils.defaultAbiCoder
    .encode(
      [["string", "string", "address", "address", "uint256", "uint256", "uint256", "uint256", "uint256", "address"]],
      [
        [
          "Gabriel",
          "testing",
          "0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4",
          "0x0429A2Da7884CA14E53142988D5845952fE4DF6a",
          "10",
          "100000000000000",
          "10",
          "0",
          "1000000",
          "0x5498BB86BC934c8D34FDA08E81D444153d0D06aD",
        ],
      ]
    )
    .slice(2)
  const dataa = functionHash + encodedDataa
  console.log("\nDATA\n\n" + dataa + "\n\n")

  // const sourceCode = fs.readFileSync("./hypercluser-validation.js").toString()
  // const functionHashh = ethers.utils.id("setSourceCode(string)").slice(0, 10)
  // const encodedData = ethers.utils.defaultAbiCoder.encode(["string"], [sourceCode]).slice(2)
  // const data = functionHashh + encodedData
  // console.log(data)
})
