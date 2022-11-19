#!/bin/bash
set -x

woolf_deployer=0xd403b2ad63581c89ace407c4ed6834a6fc544163a71a39c9f57cf432e7a852d6

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

# mint woolf nft
aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:false

# mint wool coin
aptos move run --assume-yes --function-id ${woolf_deployer}::wool::mint --args address:${woolf_deployer} u64:1000000000000
