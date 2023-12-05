task("claim-rewards", "Claims campaign rewards").setAction(async (taskArgs, hre) => {
  const destinationSelector = "112231"
  if (destinationSelector == "") throw Error("Please specify a destinationSelector address")
  try {
    const functionHash = ethers.utils.id("claimRewards(uint64)").slice(0, 10)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["uint64"], [destinationSelector]).slice(2)
    const data = functionHash + encodedData
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }
})
