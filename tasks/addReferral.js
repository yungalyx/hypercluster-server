const fs = require("fs")
task("add-referral", "Adds a referral to the network").setAction(async (taskArgs, hre) => {
  const referralCode = ""
  const slotId = ""
  const slotVersion = ""
  try {
    const functionHash = ethers.utils.id("addReferral(string,uint8,uint64)").slice(0, 10)
    const encodedData = ethers.utils.defaultAbiCoder
      .encode(["string", "uint8", "uint64"], [referralCode, slotId, slotVersion])
      .slice(2)
    const data = functionHash + encodedData
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }

  const functionHash = ethers.utils.id("reachMilestone()").slice(0, 10)
  console.log(functionHash)

  const sourceCode = fs.readFileSync("./hypercluser-validation.js").toString()
  const functionHashh = ethers.utils.id("setSourceCode(string)").slice(0, 10)
  const encodedData = ethers.utils.defaultAbiCoder.encode(["string"], [sourceCode]).slice(2)
  const data = functionHashh + encodedData
  console.log(data)
})
