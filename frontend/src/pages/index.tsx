import {
  DAPP_ADDRESS,
  APTOS_FAUCET_URL,
  APTOS_NODE_URL
} from "../config/constants";
import { useWallet } from "@manahippo/aptos-wallet-adapter";
import { MoveResource } from "@martiandao/aptos-web3-bip44.js/dist/generated";
import { useState } from "react";
import React from "react";
import {
  AptosAccount,
  WalletClient,
  HexString,
  AptosClient,
} from "@martiandao/aptos-web3-bip44.js";

import { CodeBlock } from "../components/CodeBlock";

import newAxios from "../utils/axios_utils";

// import { TypeTagVector } from "@martiandao/aptos-web3-bip44.js/dist/aptos_types";
// import {TypeTagParser} from "@martiandao/aptos-web3-bip44.js/dist/transaction_builder/builder_utils";
export default function Home() {

  const { account, signAndSubmitTransaction } = useWallet();
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const [resource, setResource] = useState<MoveResource>();
  const [resource_v2, setResourceV2] = useState();
  const [mintTx, setMintTx] = useState('');
  const [stakeTx, setStakeTx] = useState('');
  const [claimTx, setClaimTx] = useState('');
  const [tokens, setTokens] = useState<string[]>([]);

  const [mintInput, updateMintInput] = useState<{
    stake: number;
    amount: number;
  }>({
    stake: 0,
    amount: 1,
  });

  const [stakeInput, updateStakeInput] = useState<{
    collection: string;
    name: string;
    propertyVersion: number;
  }>({
    collection: "Woolf Game NFT",
    name: "",
    propertyVersion: 1,
  });

  const [claimInput, updateClaimInput] = useState<{
    collection: string;
    name: string;
    propertyVersion: number;
  }>({
    collection: "Woolf Game NFT",
    name: "",
    propertyVersion: 1,
  });

  async function mint_nft() {
    const result = await signAndSubmitTransaction(
      mint(),
      { gas_unit_price: 100 }
    );
    if (result) {
      console.log(result);
      setMintTx(result.hash);
    }
  }

  async function stake_nft() {
    const result = await signAndSubmitTransaction(
      stake(),
      { gas_unit_price: 100 }
    );
    if (result) {
      console.log(result);
      setStakeTx(result.hash);
    }
  }

  async function claim_nft() {
    const result = await signAndSubmitTransaction(
      claim(),
      { gas_unit_price: 100 }
    );
    if (result) {
      console.log(result);
      setClaimTx(result.hash);
    }
  }

  async function register_coin() {
    const result = await signAndSubmitTransaction(
      register(),
      { gas_unit_price: 100 }
    );
    if (result) {
      console.log(result);
    }
  }

  // async function get_resources() {
  //   client.aptosClient.getAccountResources(account!.address!.toString()).then(value =>
  //     console.log(value)
  //   );
  // }

  // async function get_table() {
  //   // client.aptosClient.getTableItem()
  // }

  async function getTokens() {
    const result = await client.getTokens(account!.address!.toString());
    if (result) {
      console.log(result);
      setTokens(result.map(e => e.token.name))
    }
  }

  async function getStaked() {
    console.log(await client.getTokenIds(account!.address!.toString()));
  }

  // async function faas_test() {
  //   newAxios.post(
  //     '/api/v1/run?name=DID.Renderer&func_name=get_module_doc',
  //     {
  //       "params": [
  //       ]
  //     },
  //   ).then(
  //     value => {
  //       console.log(value.data);
  //     }
  //   );
  // }
  // async function get_did_resource_v2() {
  //   newAxios.post(
  //     '/api/v1/run?name=DID.Renderer&func_name=gen_did_document',
  //     { "params": [account!.address!.toString()] },
  //   ).then(
  //     value => {
  //       console.log(value.data)
  //       setResourceV2(value.data)
  //     }
  //   );
  // }

  // async function get_did_resource() {
  //   client.aptosClient.getAccountResource(account!.address!.toString(), DAPP_ADDRESS + "::addr_aggregator::AddrAggregator").then(
  //     setResource
  //   );
  // }

  // function log_acct() {
  //   console.log(resource)
  //   console.log(account!.address!.toString());
  // }

  function mint() {
    const { amount, stake } = mintInput;
    return {
      type: "entry_function_payload",
      function: DAPP_ADDRESS + "::woolf::mint",
      type_arguments: [],
      arguments: [
        amount,
        stake ? true : false,
      ],
    };
  }

  function stake() {
    const { collection, name, propertyVersion } = stakeInput;
    return {
      type: "entry_function_payload",
      function: DAPP_ADDRESS + "::barn::add_many_to_barn_and_pack",
      type_arguments: [],
      arguments: [
        collection,
        name,
        propertyVersion,
      ],
    };
  }

  function claim() {
    const { collection, name, propertyVersion } = claimInput;
    return {
      type: "entry_function_payload",
      function: DAPP_ADDRESS + "::barn::claim_many_from_barn_and_pack",
      type_arguments: [],
      arguments: [
        collection,
        name,
        propertyVersion,
      ],
    };
  }

  function register() {
    return {
      type: "entry_function_payload",
      function: DAPP_ADDRESS + "::wool::register_coin",
      type_arguments: [],
      arguments: [],
    };
  }

  return (
    <div>
      <p><b>Module Path:</b> {DAPP_ADDRESS}::woolf</p>
      <input
        placeholder="Enter mint amount"
        className="mt-8 p-4 input input-bordered input-primary"
        onChange={(e) =>
          updateMintInput({ ...mintInput, amount: parseInt(e.target.value) })
        }
      />
      <select
        value={mintInput.stake}
        className="ml-4"
        onChange={(e) => {
          updateMintInput({ ...mintInput, stake: parseInt(e.target.value) })
        }}
      >
        <option value="0">Not Stake</option>
        <option value="1">Stake</option>
      </select>
      <br></br>
      <br></br>
      <button
        onClick={mint_nft}
        className={
          "btn btn-primary font-bold text-white rounded p-4 shadow-lg"
        }>
        Mint NFT
      </button>
      {mintTx && <a href={`https://explorer.aptoslabs.com/txn/${mintTx}`}> view transaction </a>}
      <br></br>
      <button
        onClick={getTokens}
        className={
          "btn btn-primary font-bold mt-4  text-white rounded p-4 shadow-lg"
        }>
        Get Tokens
      </button>
      <br></br>
      <ol className="mt-4">{tokens && tokens.map(e => <p key={e}>{e}</p>)}</ol>
      <br></br>
      <button
        onClick={register_coin}
        className={
          "btn btn-primary font-bold mt-4 text-white rounded p-4 shadow-lg"
        }>
        Register Coin
      </button>
      <br></br>
      <input
        placeholder="Enter collection name"
        className="mt-4 p-4 input input-bordered input-primary"
        value={stakeInput.collection}
        onChange={(e) =>
          updateStakeInput({ ...stakeInput, collection: e.target.value })
        }
      />
      <input
        placeholder="Enter token name"
        className="ml-4 mt-4 p-4 input input-bordered input-primary"
        value={stakeInput.name}
        onChange={(e) =>
          updateStakeInput({ ...stakeInput, name: e.target.value })
        }
      />
      <input
        placeholder="Enter propertyVersion"
        className="ml-4 mt-4 p-4 input input-bordered input-primary"
        value={stakeInput.propertyVersion}
        onChange={(e) =>
          updateStakeInput({ ...stakeInput, propertyVersion: parseInt(e.target.value) })
        }
      />
      <br></br>
      <button
        onClick={stake_nft}
        className={
          "btn btn-primary font-bold mt-4 text-white rounded p-4 shadow-lg"
        }>
        Stake
      </button>
      {stakeTx && <a href={`https://explorer.aptoslabs.com/txn/${stakeTx}`}> view transaction </a>}
      <br></br>
      <button
        onClick={getStaked}
        className={
          "btn btn-primary font-bold mt-4  text-white rounded p-4 shadow-lg"
        }>
        Get Staked
      </button>
      <br></br>
      <input
        placeholder="Enter collection name"
        className="mt-8 p-4 input input-bordered input-primary"
        value={claimInput.collection}
        onChange={(e) =>
          updateClaimInput({ ...claimInput, collection: e.target.value })
        }
      />
      <input
        placeholder="Enter token name"
        className="ml-4 mt-8 p-4 input input-bordered input-primary"
        value={claimInput.name}
        onChange={(e) =>
          updateClaimInput({ ...claimInput, name: e.target.value })
        }
      />
      <input
        placeholder="Enter propertyVersion"
        className="ml-4 mt-8 p-4 input input-bordered input-primary"
        value={claimInput.propertyVersion}
        onChange={(e) =>
          updateClaimInput({ ...claimInput, propertyVersion: parseInt(e.target.value) })
        }
      />
      <br></br>
      <button
        onClick={claim_nft}
        className={
          "btn btn-primary font-bold mt-4 text-white rounded p-4 shadow-lg"
        }>
        Claim
      </button>
      {claimTx && <a href={`https://explorer.aptoslabs.com/txn/${claimTx}`}> view transaction </a>}
    </div>
  );
}
