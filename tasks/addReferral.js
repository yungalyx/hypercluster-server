const { networks } = require("../networks")
task("add-referral", "Adds a referral to the network").setAction(async (taskArgs, hre) => {
  if (network.name === "hardhat") {
    throw Error(
      'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
    )
  }
  const referral = ""
  if (referral == "") throw Error("Please specify a referral address")
  try {
    const functionHash = ethers.utils.id("addReferral(address)").slice(0, 10)
    console.log(functionHash)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address"], [referral]).slice(2)
    const data = functionHash + encodedData
    console.log(data)
  } catch (error) {
    console.log(error)
  }
})
