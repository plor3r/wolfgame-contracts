#!/bin/bash
set -x

woolf_deployer=0xf87acad2d46e507ac5b4191ba93a23a6ec60b60e4d35ad6ff05d73f7f43eefad

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:true

aptos move run --assume-yes --function-id ${woolf_deployer}::wool::mint --args address:${woolf_deployer} u64:1000000000000
