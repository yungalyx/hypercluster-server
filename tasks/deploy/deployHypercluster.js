const { networks } = require("../../networks")
const fs = require("fs")
task("deploy-hypercluster", "Deploys the Hypercluster contract")
  .addOptionalParam("verify", "Set to true to verify contract", false, types.boolean)
  .setAction(async (taskArgs) => {
    console.log(`Deploying Hypercluster contract to ${network.name}`)

    console.log("\n__Compiling Contracts__")
    await run("compile")

    const sourceCode = fs.readFileSync("./hypercluser-validation.js").toString()
    const hyperclusterFactory = await ethers.getContractFactory("Hypercluster")
    const hypercluster = await hyperclusterFactory.deploy(sourceCode)

    console.log(`\nWaiting blocks for transaction ${hypercluster.deployTransaction.hash} to be confirmed...`)

    await hypercluster.deployTransaction.wait(networks[network.name])

    console.log("\nDeployed Hypercluster contract to:", hypercluster.address)

    if (network.name === "localFunctionsTestnet") {
      return
    }

    const verifyContract = taskArgs.verify
    if (
      network.name !== "localFunctionsTestnet" &&
      verifyContract &&
      !!networks[network.name].verifyApiKey &&
      networks[network.name].verifyApiKey !== "UNSET"
    ) {
      try {
        console.log("\nVerifying contract...")
        await run("verify:verify", {
          address: hypercluster.address,
          constructorArguments: [sourceCode],
        })
        console.log("Contract verified")
      } catch (error) {
        if (!error.message.includes("Already Verified")) {
          console.log(
            "Error verifying contract.  Ensure you are waiting for enough confirmation blocks, delete the build folder and try again."
          )
          console.log(error)
        } else {
          console.log("Contract already verified")
        }
      }
    } else if (verifyContract && network.name !== "localFunctionsTestnet") {
      console.log(
        "\nPOLYGONSCAN_API_KEY, ETHERSCAN_API_KEY or FUJI_SNOWTRACE_API_KEY is missing. Skipping contract verification..."
      )
    }

    console.log(`\n Hypercluster contract deployed to ${hypercluster.address} on ${network.name}`)
  })
