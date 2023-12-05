import { CipherKey, createCipheriv, createDecipheriv } from "node:crypto"
import dotenv from "dotenv"
import { DecryptedRefferalCodeResponse } from "./interfaces";
dotenv.configDotenv()

const ek = Buffer.from(process.env.ENCRYPTION_KEY as string, 'hex');
const iv = Buffer.from(process.env.INVARIANT as string, 'hex');

const cipher = createCipheriv("aes-256-cbc", ek, iv)
const decipher = createDecipheriv('aes-256-cbc', ek, iv);


// generates a referal link that can only be used by a specific address
export function generatePrivateReferralLink(referrer_address: string, referee_address: string, campaign_id: string) {

  const cipher = createCipheriv('aes-256-cbc', ek, iv);

  const plaintext =  referrer_address + "/" + campaign_id + "/" + referee_address;

  // Update the cipher with the plaintext
  let encryptedBuffer = cipher.update(plaintext, 'utf-8', 'hex');

  // // Finalize the encryption
  encryptedBuffer += cipher.final('hex');

  return encryptedBuffer;

}

// generates a referral link that can be used by anyone
export function generateReferralLink(referrer_address: string, campaign_id: string): string {

  const cipher = createCipheriv('aes-256-cbc', ek, iv);
  const plaintext = referrer_address + "/" + campaign_id;

  // Update the cipher with the plaintext
  let encryptedBuffer = cipher.update(plaintext, 'utf-8', 'hex');

  // // Finalize the encryption
  encryptedBuffer += cipher.final('hex');

  return encryptedBuffer;
}

export function resolveReferralLink(encrypted: string): DecryptedRefferalCodeResponse {
  // Create a decipher using AES-CBC with the same key and IV

  const decipher = createDecipheriv('aes-256-cbc', ek, iv);
 
  // // Update the decipher with the encrypted data
  let decryptedBuffer = decipher.update(encrypted, 'hex', 'utf-8');

  // // Finalize the decryption
  decryptedBuffer += decipher.final('utf-8');

  const data = decryptedBuffer.split("/");

  if (data.length === 3) {
    return {
      referrer: data[0],
      campaign_id: data[1],
      referring: data[2]
    }
  } else if (data.length == 2) {
    return {
      referrer: data[0],
      campaign_id: data[1],
    }
  } else {
    return {
      referrer: "",
      campaign_id: "",
      referring: ""
    }
  }

}