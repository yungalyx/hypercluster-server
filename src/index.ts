import { createCampaign } from "./helpers/firebase";
import { generatePrivateReferralLink, generateReferralLink, resolveReferralLink } from "./helpers/referral";

const express = require("express")
const cors = require("cors")

const app = express();
const port = 8888;




app.use(cors());

app.get('/', (req: any, res: { send: (arg0: string) => void; }) => {
  res.send('Express + TypeScript Server');
});

app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});


// business routes:

// updating campaign or creating new campaign
app.put("/create", function(req: any, res: any) {
  const conditions: object = req.body; 
})

// fetches information about the campaign
app.get("/campaign/:id", function(req: any, res: any) {
  

})

app.post("/signup", function(req: any, res: any) {
  

})



// user routes

app.post("/register", async function(req: any, res: any) {
  const {referrer, campaign_id, referring} = resolveReferralLink(req.params.ref); 

  

  // const referralcode = req.query.referral;
  // // var newUser = new User({username: req.body.username,referral: req.body.referral});
                  
  // User.register(newUser, req.body.password, function(error, user){
  //     if(error){
  //         console.log(error)
  //         req.flash("signerror", error.message)
  //         return res.redirect("/register")
  //     }
      //Do the referral link creation stuff here, don't know for sure
          
   
})