const Web3 = require('web3');
const fs = require('fs');

const web3 = new Web3('https://eth-mainnet.g.alchemy.com/v2/mBAg20t2aed3VikQGvsfgwrDS_e3M_or');
// traits
const contractAddress = '0xae05B31E679a3b352d8493C09DCcE739DA5B2070';

const abi = [
{
"inputs":[{"internalType":"uint8","name":"","type":"uint8"},{"internalType":"uint8","name":"","type":"uint8"}],
"name":"traitData",
"outputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"png","type":"string"}],
"stateMutability":"view",
"type":"function"}];

function sleep(millis) {
    return new Promise(resolve => setTimeout(resolve, millis));
}

async function main() {
    let a = [6, 8, 11, 13, 16]
    let datas = [5, 20, 6, 28, 10, 16, 1, 19, 1,  9, 1, 1, 27, 1, 13, 15,1, 4];
//    for(let i = 0; i < datas.length; i++) {
    a.forEach( i => {
        for (let j = 0; j < datas[i]; j++) {
//            console.log(`${i}_${j}`);
//            await sleep(500);
            new web3.eth.Contract(abi, contractAddress).methods.traitData(i, j).call().then(res => {
    //          console.log(res);
              fs.writeFile(`traits_data/${i}_${j}.json`,JSON.stringify({name: res.name, png: res.png}),  function (err) {
                  if (err) return console.log(err);
                  console.log(`Writing ${i}_${j}`);
                })
            });
        }
    })
}

main()