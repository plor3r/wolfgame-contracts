#!/bin/bash
set -x

woolf_deployer=0x2ac6f117e7ddef2a2a7b9df99bc4fcc5243e9f32043e7239259bf45b3e3d9970

aptos account fund-with-faucet --account ${woolf_deployer}

aptos move compile --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}
aptos move compile --package-dir WoolfRiskyGame --named-addresses woolf_deployer=${woolf_deployer}

aptos move test --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}
aptos move test --package-dir WoolfRiskyGame --named-addresses woolf_deployer=${woolf_deployer}

aptos move publish --assume-yes --package-dir Woolf --named-addresses woolf_deployer=${woolf_deployer}
aptos move publish --assume-yes --package-dir WoolfRiskyGame --named-addresses woolf_deployer=${woolf_deployer}

## mint woolf nft
#aptos move run --assume-yes --function-id ${woolf_deployer}::woolf::mint --args u64:1 bool:false
#
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::add_many_to_barn_and_pack --args string:"Woolf Game NFT" string:"Wolf #2" u64:1

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
#aptos move run --assume-yes --function-id ${woolf_deployer}::barn::claim_many_from_barn_and_pack --args string:"Woolf Game NFT" string:"Wolf #1" u64:1

## Risky Game
#aptos move run --assume-yes --function-id ${woolf_deployer}::risky_game::setup