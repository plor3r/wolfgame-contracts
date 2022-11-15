import os
import json
from aptos_sdk.account import Account, AccountAddress
from aptos_sdk.client import FaucetClient, RestClient

NODE_URL = os.getenv(
    "APTOS_NODE_URL", "https://fullnode.devnet.aptoslabs.com/v1"
)
FAUCET_URL = os.getenv(
    "APTOS_FAUCET_URL",
    "https://tap.devnet.prod.gcp.aptosdev.com",  # "https://faucet.testnet.aptoslabs.com"
)

collection_name = "Woolf Game NFT"
# address = AccountAddress(
#     bytes.fromhex(
#         "d30b276bedaca15f4859e0fea63c2199b63210fab96ba6852c2000a320f2a1f"
#     )
# )
address_str = "0xc999b94b0715375e45c4fc4bb0dbc85da9bb3b8a5dc715881efc5a1333aafeb4"
token_name = "1"
property_version = 0

rest_client = RestClient(NODE_URL)
faucet_client = FaucetClient(FAUCET_URL, rest_client)

collection_data = rest_client.get_collection(address_str, collection_name)
print(
    f"Woolf Game collection: {json.dumps(collection_data, indent=4, sort_keys=True)}"
)

token_data = rest_client.get_token_data(
    address_str, collection_name, token_name, property_version
)
print(f"Woolf Game token data: {json.dumps(token_data, indent=4, sort_keys=True)}")
