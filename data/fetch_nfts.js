const Web3 = require('web3');
const fs = require('fs');

const web3 = new Web3('https://eth-mainnet.g.alchemy.com/v2/mBAg20t2aed3VikQGvsfgwrDS_e3M_or');
//const web3 = new Web3('http://127.0.0.1:8545');
const contractAddress = '0xEB834ae72B30866af20a6ce5440Fa598BfAd3a42';

const abi = [
  {
    "constant": true,
    "inputs": [
      {
        "name": "_tokenId",
        "type": "uint256"
      }
    ],
    "name": "tokenURI",
    "outputs": [
      {
        "name": "",
        "type": "string"
      }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function",
  },
];

function sleep(millis) {
    return new Promise(resolve => setTimeout(resolve, millis));
}

async function main() {
    for(let i = 65; i <= 13809; i++) {
        await sleep(500);
        new web3.eth.Contract(abi, contractAddress).methods.tokenURI(i).call().then(res => {
        //  console.log(res);
          fs.writeFile(`nfts/${i}`, res,  function (err) {
              if (err) return console.log(err);
              console.log(`Writing ${i}`);
            })
        });
    }
}

main()