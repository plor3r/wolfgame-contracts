#!/bin/bash
set -x

woolf_deployer=0x68ad9b69df44984ba94baf5ba75d45566e3a8cfbdc647eedb8b5aa50dac1b2db

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

# mint woolf nft
aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:false

# mint wool coin
aptos move run --assume-yes --function-id ${woolf_deployer}::wool::mint_to --args address:${woolf_deployer} u64:1000000000000


## download source code
#aptos move download --url https://fullnode.devnet.aptoslabs.com --account ${woolf_deployer} --output-dir awolf --package woolf