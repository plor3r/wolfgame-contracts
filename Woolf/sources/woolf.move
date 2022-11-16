module woolf_deployer::woolf {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::{Self, EventHandle};
    // use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenDataId};
    // use aptos_framework::resource_account;

    // use woolf_deployer::WoolfResourceAccount;
    use woolf_deployer::wool;
    use woolf_deployer::token_helper;
    use woolf_deployer::config;
    use woolf_deployer::utf8_utils;

    /// The Naming Service contract is not enabled
    const ENOT_ENABLED: u64 = 1;
    /// Action not authorized because the signer is not the owner of this module
    const ENOT_AUTHORIZED: u64 = 1;
    /// The collection minting is disabled
    const EMINTING_DISABLED: u64 = 3;
    /// All minted
    const EALL_MINTED: u64 = 4;
    /// Invalid minting
    const EINVALID_MINTING: u64 = 5;


    //
    // constants
    //

    // 69.42 APT
    // const MINT_PRICE: u64 = 6942000000;
    // const MAX_TOKENS: u64 = 50000;
    // const PAID_TOKENS: u64 = 10000;
    // const MAX_SINGLE_MINT: u64 = 10;

    // testing config
    const MINT_PRICE: u64 = 50000;
    const MAX_TOKENS: u64 = 5;
    const PAID_TOKENS: u64 = 1;
    const MAX_SINGLE_MINT: u64 = 10;

    // tokenTraits?
    // existingCombinations?

    struct Chars has store {
        // list of probabilities for each trait type
        // 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
        rarities: vector<vector<u8>>,
        // list of aliases for Walker's Alias algorithm
        // 0 - 9 are associated with Sheep, 10 - 18 are associated with Wolves
        aliases: vector<vector<u8>>,
    }

    struct TokenMintingEvent has drop, store {
        token_receiver_address: address,
        token_data_id: TokenDataId,
    }

    // This struct stores an NFT collection's relevant information
    struct CollectionTokenMinter has key {
        minting_enabled: bool,
        token_minting_events: EventHandle<TokenMintingEvent>,
    }

    struct Woolf {}

    fun init_module(admin: &signer) {
        let admin_address: address = @woolf_deployer;

        if (!account::exists_at(admin_address)) {
            aptos_account::create_account(admin_address);
        };

        config::initialize_v1(admin, admin_address);
        token_helper::initialize(admin);
    }

    fun init_internal(account: &signer) {}

    /// Set if minting is enabled for this collection token minter
    public entry fun set_minting_enabled(minter: &signer, minting_enabled: bool) acquires CollectionTokenMinter {
        let minter_address = signer::address_of(minter);
        assert!(minter_address == @woolf_deployer, error::permission_denied(ENOT_AUTHORIZED));
        let collection_token_minter = borrow_global_mut<CollectionTokenMinter>(minter_address);
        collection_token_minter.minting_enabled = minting_enabled;
    }

    public fun mint_cost(token_id: u64): u64 {
        if (token_id <= PAID_TOKENS) {
            return 0
        } else if (token_id <= MAX_TOKENS * 2 / 5) {
            return 2000 * config::octas()
        } else if (token_id <= MAX_TOKENS * 4 / 5) {
            return 4000 * config::octas()
        };
        8000 * config::octas()
    }

    /// Mint an NFT to the receiver.
    public entry fun mint_nft(receiver: &signer, amount: u64) {
        let receiver_addr = signer::address_of(receiver);
        assert!(config::is_enabled(), error::unavailable(ENOT_ENABLED));

        assert!(amount > 0 && amount <= MAX_SINGLE_MINT, error::out_of_range(EINVALID_MINTING));

        let token_supply = token_helper::collection_supply();
        assert!(token_supply + amount <= MAX_TOKENS, error::out_of_range(EALL_MINTED));

        if (token_supply < PAID_TOKENS) {
            assert!(token_supply + amount <= PAID_TOKENS, error::out_of_range(EALL_MINTED));
            // TODO: fee and transfer
            let price = MINT_PRICE * amount;
            coin::transfer<AptosCoin>(receiver, config::fund_destination_address(), price);
        };

        let i = 0;
        let total_wool_cost: u64 = 0;
        while (i < amount) {
            let new_token_num = token_helper::collection_supply() + 1;
            let token_name: String = utf8_utils::u128_to_string((new_token_num as u128));

            // Create the token, and transfer it to the user
            let tokendata_id = token_helper::ensure_token_data(token_name);
            let token_id = token_helper::create_token(tokendata_id);

            // let (property_keys, property_values, property_types) = get_name_property_map(
            //     subdomain_name,
            //     name_expiration_time_secs
            // );
            // token_id = token_helper::set_token_props(
            //     token_helper::get_token_signer_address(),
            //     property_keys,
            //     property_values,
            //     property_types,
            //     token_id
            // );
            token_helper::transfer_token_to(receiver, token_id);

            // // mint token to the receiver
            // let resource_signer = account::create_signer_with_capability(&collection_token_minter.signer_cap);
            // let token_id = token::mint_token(&resource_signer, collection_token_minter.token_data_id, 1);
            // token::direct_transfer(&resource_signer, receiver, token_id, 1);
            //
            // event::emit_event<TokenMintingEvent>(
            //     &mut collection_token_minter.token_minting_events,
            //     TokenMintingEvent {
            //         token_receiver_address: receiver_addr,
            //         token_data_id: collection_token_minter.token_data_id,
            //     }
            // );
            //
            // // mutate the token properties to update the property version of this token
            // let (creator_address, collection, name) = token::get_token_data_id_fields(&collection_token_minter.token_data_id);
            // token::mutate_token_properties(
            //     &resource_signer,
            //     receiver_addr,
            //     creator_address,
            //     collection,
            //     name,
            //     0, // token_property_version
            //     1, // amount
            //     vector::empty<String>(),
            //     vector::empty<vector<u8>>(),
            //     vector::empty<String>(),
            // );
            total_wool_cost = total_wool_cost + mint_cost(new_token_num);
            i = i + 1;
        };
        if (total_wool_cost > 0) {
            // burn WOOL
            wool::burn_from(receiver_addr, total_wool_cost);
        };
    }
}