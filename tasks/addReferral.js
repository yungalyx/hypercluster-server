task("add-referral", "Adds a referral to the network").setAction(async (taskArgs, hre) => {
  const referral = "0xe54Aa9FA11BC842Bf39089f0Da4E63c94a91Eea9"
  if (referral == "") throw Error("Please specify a referral address")
  try {
    const functionHash = ethers.utils.id("addReferral(address)").slice(0, 10)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address"], [referral]).slice(2)
    const data = functionHash + encodedData
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }
})
