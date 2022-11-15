#!/bin/bash
set -x

woolf_deployer=0x0cb659fa69424ccfc36ebc82dc651e77ae2386bbfee8ebe3c6faef9b6360aaf0

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}
#aptos move compile --package-dir WoolfResourceAccount --named-addresses woolf_deployer=${woolf_deployer}

#aptos move publish --package-dir WoolfResourceAccount --named-addresses woolf_deployer=${woolf_deployer}
aptos move publish --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

#aptos move run --function-id ${woolf_deployer}::WoolfResourceAccount::initialize_woolf_account
aptos move run --function-id ${woolf_deployer}::woolf::mint_nft
