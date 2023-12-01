// checks ANTIBOT


function confirmUserIsNotBot(address: string) {
    
}



async function getRiskScore(address: string) {

    return new Promise((reject, resolve) => {
        fetch(`https://api.0xscope.com/v2/kye/riskyScore?address=${address}&chain=ethereum`, {
            headers: {
                "API-KEY": "1727571741574721536", 
                accept: "*/*"
            }
        })
            .then(res => res.json)
            .then(data => {
                console.log(data);
                resolve(data)
            })
            .catch(err => reject(err))
    })
}

async function getTwitterScore(address: string) {
     return new Promise((reject, resolve) => {
        fetch(`https://api.0xscope.com/v2/social/twitterInfo?address=${address}&chain=ethereum`, {
            headers: {
                "API-KEY": "1727571741574721536", 
                accept: "*/*"
            }
        })
            .then(res => res.json)
            .then(data => {
                console.log(data);
                resolve(data)
            })
            .catch(err => reject(err))
    })
}
