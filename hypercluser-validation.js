const referral_code = args[0]
const referral_address = args[1]

if (!secrets.zkScopeApiKey) {
  throw Error("KEY")
}

if (!secrets.hyperclusterKey) {
  throw Error("KEY")
}

try {
  const response1 = await Functions.makeHttpRequest({
    url: `https://api.0xscope.com/v2/kye/riskyScore?address=${referral_address}&chain=ethereum`,
    method: "GET",
    headers: {
      "API-KEY": secrets.zkScopeApiKey,
      accept: "*/*",
    },
  })

  if (response1.data.data.totalScore > 75) {
    throw Error("BOT")
  }
} catch (err) {
  throw Error("API")
}

try {
  const res = await Functions.makeHttpRequest({
    url: `https://hypercluster-frontend.vercel.app/api/resolve?ref=${referral_code}`,
    method: "GET",
  })

  const referrer = res.data.referrer
  return Functions.encodeString(referrer)
} catch {
  throw Error("INVALID")
}
