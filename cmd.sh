#!/bin/bash
set -x

woolf_deployer=0x76465c5a665cda57337312ed9409ead2d8a7e371073cff66fb4f28ad2767822f

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

rm -rf Woolf/build/Woolf/sources

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}

aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::set_minting_enabled --args bool:true

## mint woolf nft
#aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:false
#aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:true
#
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::add_many_to_barn_and_pack --args string:"Woolf Game NFT" string:"Wolf #2" u64:1
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::add_many_to_barn_and_pack --args string:"Woolf Game NFT" string:"Sheep #1" u64:1

#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::add_many_to_barn_and_pack_with_index --args u64:1

## mint wool coin
#aptos move run --assume-yes --function-id ${woolf_deployer}::wool::register_coin

#aptos move run --assume-yes --function-id ${woolf_deployer}::wool::mint_to --args address:0xf2db9526accac625e00dac4c3d3aa27bf55ec7d24b0723c1d1a35b42757b3a1e u64:1000000000000

## mint pouch
#aptos move run --assume-yes --function-id ${woolf_deployer}::wool_pouch::mint_without_claimable --args address:0xf2db9526accac625e00dac4c3d3aa27bf55ec7d24b0723c1d1a35b42757b3a1e u64:10000000000000 u64:1
#aptos move run --assume-yes --function-id ${woolf_deployer}::wool_pouch::mint --args address:0xf2db9526accac625e00dac4c3d3aa27bf55ec7d24b0723c1d1a35b42757b3a1e u64:10000000000000 u64:1

#aptos move run --assume-yes --function-id ${woolf_deployer}::wool_pouch::claim --args u64:1

## download source code
#aptos move download --url https://fullnode.devnet.aptoslabs.com --account ${woolf_deployer} --output-dir awolf --package woolf

## claim
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::claim_many_from_barn_and_pack --args string:"Woolf Game NFT" string:"Sheep #1" u64:1
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::claim_many_from_barn_and_pack_with_index --args u64:1

## Risky Game
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::setup
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::set_paused --args bool:false
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::play_it_safe_one --args u64:1 bool:false
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::take_a_risk_one --args u64:3
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::execute_risk_one --args u64:3 bool:false


#curl --request POST \
#  --url https://fullnode.devnet.aptoslabs.com/v1/view \
#  --header 'Content-Type: application/json' \
#  --data '{
#  "function": "0x1e1e2f6639e82e62b41c001d8d6e5076df8b1a310c1164c7d3382cf2b70953e6::barn::max_alpha",
#  "type_arguments": [],
#  "arguments": []
#}'