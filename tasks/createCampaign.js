task("create-campaign", "Creates a new Hypercluster Campaign").setAction(async (taskArgs, hre) => {
  const params = {
    rewardTokenAddress: "0xbE9044946343fDBf311C96Fb77b2933E2AdA8B5D",
    rootReferral: "0xbE9044946343fDBf311C96Fb77b2933E2AdA8B5D",
    rewardPercentPerMilestone: 10,
    totalSupply: 1000000,
    startIn: 10,
    endIn: 100,
    metadata: "YourMetadataString",
  }
  try {
    const functionHash = ethers.utils
      .id("createCampaign((address,address,uint256,uint256,uint256,uint256,string))")
      .slice(2, 10) // start from index 2 to get the 8 characters

    const encodedData = ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256", "uint256", "uint256", "uint256", "string"],
      [
        params.rewardTokenAddress,
        params.rootReferral,
        params.rewardPercentPerMilestone,
        params.totalSupply,
        params.startIn,
        params.endIn,
        params.metadata,
      ]
    )

    const data = functionHash + encodedData
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }
})
