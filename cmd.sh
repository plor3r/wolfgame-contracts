#!/bin/bash
set -x

woolf_deployer=0x1b994bc46bc268a65c1cd2cdc3dbd8f16204d6d94552b58e8546a8871ecd11b4

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}
#aptos move compile --package-dir WoolfResourceAccount --named-addresses woolf_deployer=${woolf_deployer}

#aptos move publish --package-dir WoolfResourceAccount --named-addresses woolf_deployer=${woolf_deployer}
aptos move publish --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

#aptos move run --function-id ${woolf_deployer}::WoolfResourceAccount::initialize_woolf_account
aptos move run --function-id ${woolf_deployer}::woolf::mint_nft --args u64:1
