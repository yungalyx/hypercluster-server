import { initializeApp } from "firebase/app";
import { getDatabase, ref, child, get, Database, push, update, increment } from "firebase/database";
import { Campaign, UserData } from "./interfaces";
import { generateReferralLink } from "./referral";

// TODO: Replace the following with your app's Firebase project configuration
// See: https://firebase.google.com/docs/web/learn-more#config-object
const firebaseConfig = {
  databaseURL: "https://hypercluster-9ff6e-default-rtdb.firebaseio.com/",
};


// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Realtime Database and get a reference to the service
//const database: Database = getDatabase(app);
const database = getDatabase(app);



// campaign name cannot include "/"
// todo: calls the factory smart contract and returns the address of the wallet to fund 
export function createCampaign(campaign_data: Campaign) {
  if (campaign_data.name.includes("/")) {
    return;
  } 
  const newCampaignKey = push(child(ref(database), "campaigns")).key;
  const updates:{[key: string]: any} = {};
  updates['/campaigns/' + newCampaignKey] = campaign_data;
  updates['/users/'] = [];

  return update(ref(database), updates);
}


// returns referralCode 
export function addReferralToCampaign(campaign_id: string, user_address: string, referrer: string): Promise<string> {
  return new Promise((reject, resolve) => {
    
    const dbref = ref(database, `campaign/${campaign_id}`);

    const referralCode = generateReferralLink(user_address, campaign_id);
  
    
    const updates:{[key: string]: any} = {};
    updates['/users/' + user_address] = { referralCount: 0, referralCode: referralCode};
    updates[`/users/${referrer}/referralCount`] = increment(1);
    
    //updates['/mapping' + uid + '/' + newPostKey] = postData;
    // todo: not finished yet, map them to graph 

    update(dbref, updates)
      .then(() => resolve(referralCode))
      .catch((err) => reject(err));

  })  
 
}


// returns referral code if exists, else returns empty string
export function getUserFromCampaign(campaign_id: string, user_address: string): Promise<UserData> {

  return new Promise((reject, resolve) => {
    const dbref = ref(database, `campaign/${campaign_id}`);
    get(child(dbref, `users/${user_address}`))
    .then((snapshot) => {
      if (snapshot.exists()) {
        console.log(snapshot.val());
        resolve(snapshot.val())
      } else {
        console.log("No data available");
        resolve(false)
      }
    }).catch((error) => {
      console.error(error);
      // reject(error)
    })
  })
};