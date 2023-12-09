const { SecretsManager } = require("@chainlink/functions-toolkit")
const process = require("process")
const path = require("path")

task("functions-upload-secrets-don", "Encrypts secrets and uploads them to the DON")
  .addParam(
    "slotid",
    "Storage slot number 0 or higher - if the slotid is already in use, the existing secrets for that slotid will be overwritten"
  )
  .addOptionalParam(
    "ttl",
    "Time to live - minutes until the secrets hosted on the DON expire (defaults to 10, and must be at least 5)",
    100,
    types.int
  )
  .addOptionalParam(
    "configpath",
    "Path to Functions request config file",
    `${__dirname}/../../Functions-request-config.js`,
    types.string
  )
  .setAction(async (taskArgs) => {

    const gatewayUrls = [
      "https://01.functions-gateway.testnet.chain.link/",
      "https://02.functions-gateway.testnet.chain.link/",
    ];
    // const signer = await ethers.getSigner()

    const provider = new ethers.providers.JsonRpcProvider("https://ethereum-sepolia.publicnode.com");
    const signer = new ethers.Wallet(process.env.WALLET_PK, provider);
    console.log(await signer.getChainId())


    const functionsRouterAddress = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"; // networks[network.name]["functionsRouter"]
    const donId = 'fun-ethereum-sepolia-1'

    const slotId = parseInt(taskArgs.slotid)
    const minutesUntilExpiration = taskArgs.ttl

    const secretsManager = new SecretsManager({
      signer,
      functionsRouterAddress,
      donId,
    })
    await secretsManager.initialize()

    // Get the secrets object from  Functions-request-config.js or other specific request config.
    // const requestConfig = require(path.isAbsolute(taskArgs.configpath)
    //   ? taskArgs.configpath
    //   : path.join(process.cwd(), taskArgs.configpath))

    // if (!requestConfig.secrets || requestConfig.secrets.length === 0) {
    //   console.log("No secrets found in the request config.")
    //   return
    // }

    const secrets = {
      endpoint: "https://hypercluster-frontend.vercel.app",
      zkScopeApiKey: "1727571741574721536",
    }

    console.log("Encrypting secrets and uploading to DON...")
    const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets)

    const {
      version, // Secrets version number (corresponds to timestamp when encrypted secrets were uploaded to DON)
      success, // Boolean value indicating if encrypted secrets were successfully uploaded to all nodes connected to the gateway
    } = await secretsManager.uploadEncryptedSecretsToDON({
      encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
      gatewayUrls,
      slotId,
      minutesUntilExpiration,
    })

    console.log(version)

    const encryptedSecretsReference = await secretsManager.buildDONHostedEncryptedSecretsReference({
      slotId,
      version,
    })
    console.log(
      `\nYou can now use slotId ${slotId} and version ${version} and reference ${encryptedSecretsReference} to reference the encrypted secrets hosted on the DON.`
    )
  })
