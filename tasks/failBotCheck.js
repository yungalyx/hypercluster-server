task("fail-bot-check", "Fails a bot").setAction(async (taskArgs, hre) => {
  const bot = "0xe54Aa9FA11BC842Bf39089f0Da4E63c94a91Eea9"
  if (bot == "") throw Error("Please specify a bot address")
  try {
    const functionHash = ethers.utils.id("failBotCheck(address)").slice(0, 10)

    const encodedData = ethers.utils.defaultAbiCoder.encode(["address"], [bot]).slice(2)
    const data = functionHash + encodedData
    console.log("\nDATA\n\n" + data + "\n\n")
  } catch (error) {
    console.log(error)
  }
})
