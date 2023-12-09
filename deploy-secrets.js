
const { ethers } = require("ethers");
const dotenv = require("dotenv")
dotenv.config()


const {
  SubscriptionManager,
  SecretsManager,
  simulateScript,
  ResponseListener,
  ReturnType,
  decodeResult,
  FulfillmentCode,
} = require("@chainlink/functions-toolkit");
const { AnkrProvider } = require("@ethersproject/providers");



const consumerAddress = "0x954F64310224f66Dc99847718B309e3EB72DA64A"; // REPLACE this with your Functions consumer address
const subscriptionId = 1828; // REPLACE this with your subscription ID
const routerAddress = "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0" // "0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C";
const linkTokenAddress = "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"; // "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
const donId = "fun-avalanche-fuji-1";
const gatewayUrls = [
  "https://01.functions-gateway.testnet.chain.link/",
  "https://02.functions-gateway.testnet.chain.link/",
];
const explorerUrl = "https://testnet.snowtrace.io/.com";

const slotIdNumber = 0; // slot ID where to upload the secrets
const expirationTimeMinutes = 60; // expiration time in minutes of the secrets

const privateKey = process.env.PRIVATEKEY;


const provider = new ethers.providers.AnkrProvider("https://rpc.ankr.com/avalanche_fuji/eff2c904e4548df2a09e6ade9d3328fc3cbca720835e87a09d12c8d89f2f3056")
AnkrProvider()
const wallet = new ethers.Wallet(privateKey);

const signer = wallet.connect(provider); // create ethers signer for signing transactions


const deploySecrets = async () => {

  const secretsManager = new SecretsManager({
    signer: signer,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });
  await secretsManager.initialize();

  const encryptedSecrets = await secretsManager.encryptSecrets({
      ZX_SCOPE_KEY: process.env.NEXT_PUBLIC_ZX_SCOPE_KEY ?? "",
      NEXT_JS_ENDPOINT: process.env.NEXT_PUBLIC_ENDPOINT ?? "",
    })

  console.log(
    `Upload encrypted secret to gateways ${gatewayUrls}. slotId ${slotIdNumber}. Expiration in minutes: ${expirationTimeMinutes}`
  );

  const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
      encryptedSecretsHexstring: encryptedSecrets.encryptedSecrets,
      gatewayUrls: gatewayUrls,
      slotId: 5,
      minutesUntilExpiration: expirationTimeMinutes,
    })

  if (!uploadResult.success) throw new Error(`Encrypted secrets not uploaded to ${gatewayUrls}`);

  console.log(
    `\n✅ Secrets uploaded properly to gateways ${gatewayUrls}! Gateways response: `,
    uploadResult
  );

  

  encryptedSecretsReference = await secretsManager.buildDONHostedEncryptedSecretsReference({
    slotId: slotIdNumber,
    version: uploadResult.version,
  });

}


deploySecrets().catch((e) => {
  console.error(e);
  process.exit(1);
});