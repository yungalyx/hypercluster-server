task("reach-milestone", "Reach a milestone").setAction(async (taskArgs, hre) => {
  try {
    const functionHash = ethers.utils.id("reachMilestone()").slice(0, 10)

    const data = functionHash
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }
})
