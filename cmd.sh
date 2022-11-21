#!/bin/bash
set -x

woolf_deployer=0x5d33d0a24264cb91850b932061ed8581b742adb86f950528510f5b054eeede4f

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

## mint woolf nft
#aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:false
#
## mint wool coin
#aptos move run --assume-yes --function-id ${woolf_deployer}::wool::mint_to --args address:0xf2db9526accac625e00dac4c3d3aa27bf55ec7d24b0723c1d1a35b42757b3a1e u64:1000000000000


## download source code
#aptos move download --url https://fullnode.devnet.aptoslabs.com --account ${woolf_deployer} --output-dir awolf --package woolf