const referral_code = args[0]
const referral_address = args[1]

if (referral_address.length != 42) {
  throw Error("invalid address")
}

if (!secrets.zkScopeApiKey) {
  throw Error("0xScope api key missing")
}

const response1 = await Functions.makeHttpRequest({
  url: `https://api.0xscope.com/v2/kye/riskyScore?address=${referral_address}&chain=ethereum`,
  method: 'GET',
  headers: {
      "API-KEY": secrets.zkScopeApiKey, 
      accept: "*/*"
  }
})

if (response1.data.code === 1603) {
  throw Error(response1.data.message);
} else if (response1.data.totalScore > 75) {
  return Functions.encodeString("Bot")
}

try {
  const res = await Functions.makeHttpRequest({
    url: `${secrets.endpoint}/api/resolve?ref=${referral_code}`,
    method: 'GET',
  })
  const { referrer } = await res.json();
  return Functions.encodeString(referrer);
} catch {
  return Functions.encodeString("Invalid")
}
