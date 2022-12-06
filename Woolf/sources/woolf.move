module woolf_deployer::woolf {
    use std::error;
    use std::signer;
    use std::string;
    use std::vector;
    use std::debug;
    use std::bcs;
    use std::hash;

    use aptos_framework::account;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event::EventHandle;
    // use aptos_framework::timestamp;
    use aptos_std::table::{Self, Table};
    use aptos_token::token::{Self, TokenDataId, Token};

    use woolf_deployer::barn;
    use woolf_deployer::wool;
    use woolf_deployer::token_helper;
    use woolf_deployer::config;
    use woolf_deployer::utf8_utils;
    use woolf_deployer::random;
    use woolf_deployer::traits;
    use woolf_deployer::wool_pouch;

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

    struct SheepWolf has drop, store, copy {
        is_sheep: bool,
        fur: u8,
        head: u8,
        ears: u8,
        eyes: u8,
        nose: u8,
        mouth: u8,
        neck: u8,
        feet: u8,
        alpha_index: u8,
    }

    struct Dashboard has key {
        existing_combinations: Table<vector<u8>, bool>,
        rarities: vector<vector<u8>>,
        aliases: vector<vector<u8>>,
    }

    fun init_module(admin: &signer) {
        initialize_modules(admin);
    }

    fun initialize_modules(admin: &signer) {
        let admin_address: address = @woolf_deployer;

        if (!account::exists_at(admin_address)) {
            aptos_account::create_account(admin_address);
        };
        config::initialize(admin, admin_address);
        token_helper::initialize(admin);
        barn::initialize(admin);
        wool::initialize(admin);
        wool_pouch::initialize(admin);
        traits::initialize(admin);
        initialize(admin);
    }

    fun initialize(account: &signer) {
        let rarities: vector<vector<u8>> = vector::empty();
        let aliases: vector<vector<u8>> = vector::empty();
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // sheep
        // fur
        vector::push_back(&mut rarities, vector[15, 50, 200, 250, 255]);
        vector::push_back(&mut aliases, vector[4, 4, 4, 4, 4]);
        // head
        vector::push_back(
            &mut rarities,
            vector[190, 215, 240, 100, 110, 135, 160, 185, 80, 210, 235, 240, 80, 80, 100, 100, 100, 245, 250, 255]
        );
        vector::push_back(&mut aliases, vector[1, 2, 4, 0, 5, 6, 7, 9, 0, 10, 11, 17, 0, 0, 0, 0, 4, 18, 19, 19]);
        // ears
        vector::push_back(&mut rarities, vector[255, 30, 60, 60, 150, 156]);
        vector::push_back(&mut aliases, vector[0, 0, 0, 0, 0, 0]);
        // eyes
        vector::push_back(
            &mut rarities,
            vector[221, 100, 181, 140, 224, 147, 84, 228, 140, 224, 250, 160, 241, 207, 173, 84, 254, 220, 196, 140, 168, 252, 140, 183, 236, 252, 224, 255]
        );
        vector::push_back(
            &mut aliases,
            vector[1, 2, 5, 0, 1, 7, 1, 10, 5, 10, 11, 12, 13, 14, 16, 11, 17, 23, 13, 14, 17, 23, 23, 24, 27, 27, 27, 27]
        );
        // nose
        vector::push_back(&mut rarities, vector[175, 100, 40, 250, 115, 100, 185, 175, 180, 255]);
        vector::push_back(&mut aliases, vector[3, 0, 4, 6, 6, 7, 8, 8, 9, 9]);
        // mouth
        vector::push_back(
            &mut rarities,
            vector[80, 225, 227, 228, 112, 240, 64, 160, 167, 217, 171, 64, 240, 126, 80, 255]
        );
        vector::push_back(&mut aliases, vector[1, 2, 3, 8, 2, 8, 8, 9, 9, 10, 13, 10, 13, 15, 13, 15]);
        // neck
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);
        // feet
        vector::push_back(
            &mut rarities,
            vector[243, 189, 133, 133, 57, 95, 152, 135, 133, 57, 222, 168, 57, 57, 38, 114, 114, 114, 255]
        );
        vector::push_back(&mut aliases, vector[1, 7, 0, 0, 0, 0, 0, 10, 0, 0, 11, 18, 0, 0, 0, 1, 7, 11, 18]);
        // alphaIndex
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);

        // wolves
        // fur
        vector::push_back(&mut rarities, vector[210, 90, 9, 9, 9, 150, 9, 255, 9]);
        vector::push_back(&mut aliases, vector[5, 0, 0, 5, 5, 7, 5, 7, 5]);
        // head
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);
        // ears
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);
        // eyes
        vector::push_back(
            &mut rarities,
            vector[135, 177, 219, 141, 183, 225, 147, 189, 231, 135, 135, 135, 135, 246, 150, 150, 156, 165, 171, 180, 186, 195, 201, 210, 243, 252, 255]
        );
        vector::push_back(
            &mut aliases,
            vector[1, 2, 3, 4, 5, 6, 7, 8, 13, 3, 6, 14, 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 26, 26]
        );
        // nose
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);
        // mouth
        vector::push_back(&mut rarities, vector[239, 244, 249, 234, 234, 234, 234, 234, 234, 234, 130, 255, 247]);
        vector::push_back(&mut aliases, vector[1, 2, 11, 0, 11, 11, 11, 11, 11, 11, 11, 11, 11]);
        // neck
        vector::push_back(&mut rarities, vector[75, 180, 165, 120, 60, 150, 105, 195, 45, 225, 75, 45, 195, 120, 255]);
        vector::push_back(&mut aliases, vector[1, 9, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 14, 12, 14]);
        // feet
        vector::push_back(&mut rarities, vector[255]);
        vector::push_back(&mut aliases, vector[0]);
        // alphaIndex
        vector::push_back(&mut rarities, vector[8, 160, 73, 255]);
        vector::push_back(&mut aliases, vector[2, 3, 3, 3]);

        move_to(account, Dashboard {
            existing_combinations: table::new(),
            rarities,
            aliases,
        });
    }

    /// Set if minting is enabled for this collection token minter
    public entry fun set_minting_enabled(minter: &signer, minting_enabled: bool) acquires CollectionTokenMinter {
        let minter_address = signer::address_of(minter);
        assert!(minter_address == @woolf_deployer, error::permission_denied(ENOT_AUTHORIZED));
        let collection_token_minter = borrow_global_mut<CollectionTokenMinter>(minter_address);
        collection_token_minter.minting_enabled = minting_enabled;
    }

    public fun mint_cost(token_index: u64): u64 {
        if (token_index <= config::paid_tokens()) {
            return 0
        } else if (token_index <= config::max_tokens() * 2 / 5) {
            return 2000 * config::octas()
        } else if (token_index <= config::max_tokens() * 4 / 5) {
            return 4000 * config::octas()
        };
        8000 * config::octas()
    }

    fun issue_token(_receiver: &signer, token_index: u64, t: SheepWolf): Token {
        let SheepWolf {
            is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index
        } = t;
        let token_name = if (is_sheep) config::token_name_sheep_prefix() else config::token_name_wolf_prefix();
        string::append(&mut token_name, utf8_utils::to_string(token_index));
        // Create the token, and transfer it to the user
        let tokendata_id = token_helper::ensure_token_data(token_name);
        let token_id = token_helper::create_token(tokendata_id);

        let (property_keys, property_values, property_types) = traits::get_name_property_map(
            is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index
        );
        let creator_addr = token_helper::get_token_signer_address();
        token_id = token_helper::set_token_props(
            creator_addr,
            token_id,
            property_keys,
            property_values,
            property_types
        );

        traits::update_token_traits(token_id, is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index);

        // FIXME set token_uri
        // let _token_uri_string = traits::token_uri(signer::address_of(_receiver), token_id);
        // let _token_uri_string = traits::token_uri_internal(is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index);
        let token_uri_string = config::tokendata_url_prefix();
        string::append(&mut token_uri_string, utf8_utils::to_string(token_index));
        string::append(&mut token_uri_string, string::utf8(b".json"));
        let creator = token_helper::get_token_signer();
        token_helper::set_token_uri(&creator, tokendata_id, token_uri_string);

        // // TODO keep or delete
        // traits::update_token_traits(
        //     token_id, is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index
        // );

        // event::emit_event<TokenMintingEvent>(
        //     &mut collection_token_minter.token_minting_events,
        //     TokenMintingEvent {
        //         token_receiver_address: receiver_addr,
        //         token_data_id: collection_token_minter.token_data_id,
        //     }
        // );
        token::withdraw_token(&creator, token_id, 1)
    }

    /// Mint an NFT to the receiver.
    public entry fun mint(receiver: &signer, amount: u64, stake: bool) acquires Dashboard {
        // NOTE: make receiver op-in in order to random select and directly transfer token to receiver
        token::initialize_token_store(receiver);
        token::opt_in_direct_transfer(receiver, true);

        let receiver_addr = signer::address_of(receiver);
        assert!(config::is_enabled(), error::unavailable(ENOT_ENABLED));
        assert!(amount > 0 && amount <= config::max_single_mint(), error::out_of_range(EINVALID_MINTING));

        let token_supply = token_helper::collection_supply();
        assert!(token_supply + amount <= config::max_tokens(), error::out_of_range(EALL_MINTED));

        if (token_supply < config::paid_tokens()) {
            assert!(token_supply + amount <= config::paid_tokens(), error::out_of_range(EALL_MINTED));
            let price = config::mint_price() * amount;
            // FIXME
            coin::transfer<AptosCoin>(receiver, config::fund_destination_address(), price);
        };

        let total_wool_cost: u64 = 0;
        let tokens: vector<Token> = vector::empty<Token>();
        let seed: vector<u8>;
        let i = 0;
        while (i < amount) {
            seed = random::seed(&receiver_addr);
            let token_index = token_helper::collection_supply() + 1; // from 1
            let sheep_wolf_traits = generate_traits(seed);
            let token = issue_token(receiver, token_index, sheep_wolf_traits);
            // let token_id = token::get_token_id(&token);
            // debug::print(&token_id);
            let recipient: address = select_recipient(receiver_addr, seed, token_index);
            if (!stake || recipient != receiver_addr) {
                debug::print(&111);
                // FIXME send to thief
                // token_helper::transfer_to(recipient, token_id);

                token::direct_deposit_with_opt_in(recipient, token);
            } else {
                debug::print(&222);
                // token_helper::transfer_to(@woolf_deployer, token_id);
                vector::push_back(&mut tokens, token);
            };
            // wool cost
            total_wool_cost = total_wool_cost + mint_cost(token_index);

            i = i + 1;
        };
        if (total_wool_cost > 0) {
            // burn WOOL
            // FIXME need burn cap
            wool::transfer(receiver, @woolf_deployer, total_wool_cost);
        };

        if (stake) {
            // FIXME who is the owner address???
            // let creator_addr = token_helper::get_token_signer_address();
            barn::add_many_to_barn_and_pack_internal(receiver_addr, tokens);
        } else {
            vector::destroy_empty(tokens);
        }
    }

    // the first 20% (ETH purchases) go to the minter
    // the remaining 80% have a 10% chance to be given to a random staked wolf
    fun select_recipient(sender: address, seed: vector<u8>, token_index: u64): address {
        let rand = random::rand_u64_range_with_seed(seed, 0, 10);
        if (token_index <= config::paid_tokens() || rand > 0)
            return sender; // top 10 bits haven't been used
        let thief = barn::random_wolf_owner(seed);
        if (thief == @0x0) return sender;
        return thief
    }

    // generates traits for a specific token, checking to make sure it's unique
    fun generate_traits(seed: vector<u8>): SheepWolf acquires Dashboard {
        let t = select_traits(seed);
        let trait_hash = struct_to_hash(&t);
        let dashboard = borrow_global_mut<Dashboard>(@woolf_deployer);
        if (!table::contains(&dashboard.existing_combinations, trait_hash)) {
            table::add(&mut dashboard.existing_combinations, trait_hash, true);
            return t
        };
        generate_traits(random::seed_no_sender())
    }

    fun struct_to_hash(s: &SheepWolf): vector<u8> {
        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, bcs::to_bytes(&s.is_sheep));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.fur));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.head));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.eyes));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.mouth));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.neck));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.ears));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.feet));
        vector::append<u8>(&mut info, bcs::to_bytes(&s.alpha_index));
        let hash: vector<u8> = hash::sha3_256(info);
        hash
    }

    fun select_traits(_seed: vector<u8>): SheepWolf acquires Dashboard {
        let dashboard = borrow_global<Dashboard>(@woolf_deployer);
        let is_sheep = random::rand_u64_range_no_sender(0, 100) >= 10;
        let shift = if (is_sheep) 0 else 9;
        SheepWolf {
            is_sheep,
            fur: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 0 + shift),
            head: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 1 + shift),
            ears: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 2 + shift),
            eyes: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 3 + shift),
            nose: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 4 + shift),
            mouth: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 5 + shift),
            neck: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 6 + shift),
            feet: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 7 + shift),
            alpha_index: select_trait(dashboard, random::rand_u64_range_no_sender(0, 255), 8 + shift),
        }
    }

    fun select_trait(dashboard: &Dashboard, seed: u64, trait_type: u64): u8 {
        let trait = seed % vector::length(vector::borrow(&dashboard.rarities, trait_type));
        if (seed < (*vector::borrow(vector::borrow(&dashboard.rarities, trait_type), trait) as u64)) {
            return (trait as u8)
        };
        *vector::borrow(vector::borrow(&dashboard.aliases, trait_type), trait)
    }

    //
    // test
    //

    // #[test_only]
    // use std::string;
    // #[test_only]
    // use aptos_framework::block;
    #[test_only]
    use woolf_deployer::utils::setup_timestamp;

    // #[test(aptos = @0x1, account_addr = @woolf_deployer)]
    // fun test_generate(aptos: &signer, account_addr: address) acquires Dashboard {
    //     block::initialize_modules(aptos, 1);
    //     let token_id = token::create_token_id_raw(
    //         account_addr,
    //         config::collection_name(),
    //         string::utf8(b"123"),
    //         0
    //     );
    //     generate(token_id, random::seed_no_sender());
    // }

    #[test(aptos = @0x1, admin = @woolf_deployer)]
    fun test_select_traits(aptos: &signer, admin: &signer) acquires Dashboard {
        setup_timestamp(aptos);
        // block::initialize_modules(aptos, 1);
        initialize(admin);
        select_traits(random::seed_no_sender());
    }

    #[test]
    fun test_struct_to_hash() {
        let sw = SheepWolf {
            is_sheep: false,
            fur: 1,
            head: 1,
            ears: 1,
            eyes: 1,
            nose: 1,
            mouth: 1,
            neck: 1,
            feet: 1,
            alpha_index: 1,
        };
        let hash = struct_to_hash(&sw);
        // debug::print(&hash);
        assert!(
            hash == vector[221, 61, 243, 38, 36, 70, 50, 235, 234, 246, 152,
                66, 26, 160, 62, 165, 60, 27, 51, 24, 219, 125, 95, 216, 122,
                202, 224, 140, 185, 217, 181, 187],
            1
        );
    }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1234, fund_address = @woolf_deployer_fund)]
    fun test_mint(aptos: &signer, admin: &signer, account: &signer, fund_address: &signer) acquires Dashboard {
        setup_timestamp(aptos);
        // block::initialize_modules(aptos, 2);
        initialize_modules(admin);

        let account_addr = signer::address_of(account);

        account::create_account_for_test(account_addr);
        // account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(fund_address));
        wool::register_coin(account);
        wool::register_coin(admin);
        wool::register_coin(fund_address);
        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(fund_address);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            aptos,
            string::utf8(b"TC"),
            string::utf8(b"TC"),
            8,
            false,
        );

        let coins = coin::mint<AptosCoin>(200000000, &mint_cap);
        coin::deposit(signer::address_of(account), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_burn_cap(burn_cap);
        wool::mint_internal(account_addr, 10 * config::octas());

        assert!(config::is_enabled(), 0);
        mint(account, 1, false);
        let token_id = token_helper::build_token_id(string::utf8(b"Sheep #1"), 1);
        debug::print(&token_id);
        assert!(token_helper::collection_supply() == 1, 1);
        debug::print(&token::balance_of(signer::address_of(account), token_id));
        assert!(token::balance_of(signer::address_of(account), token_id) == 1, 2)
    }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1234, fund_address = @woolf_deployer_fund)]
    fun test_mint_with_stake(
        aptos: &signer,
        admin: &signer,
        account: &signer,
        fund_address: &signer
    ) acquires Dashboard {
        setup_timestamp(aptos);
        // block::initialize_modules(aptos, 2);
        initialize_modules(admin);

        account::create_account_for_test(signer::address_of(account));
        // account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(fund_address));
        wool::register_coin(account);
        wool::register_coin(admin);
        wool::register_coin(fund_address);

        coin::register<AptosCoin>(account);
        coin::register<AptosCoin>(fund_address);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<AptosCoin>(
            aptos,
            string::utf8(b"TC"),
            string::utf8(b"TC"),
            8,
            false,
        );

        let coins = coin::mint<AptosCoin>(200000000, &mint_cap);
        coin::deposit(signer::address_of(account), coins);
        coin::destroy_mint_cap(mint_cap);
        coin::destroy_freeze_cap(freeze_cap);
        coin::destroy_burn_cap(burn_cap);
        wool::mint_internal(signer::address_of(account), 10 * config::octas());

        token::initialize_token_store(admin);
        token::opt_in_direct_transfer(admin, true);

        assert!(config::is_enabled(), 0);
        mint(account, 1, true);

        let token_id = token_helper::build_token_id(string::utf8(b"Wolf #1"), 1);
        // debug::print(&token_id);
        assert!(token_helper::collection_supply() == 1, 1);
        // debug::print(&token::balance_of(signer::address_of(account), token_id));
        assert!(token::balance_of(signer::address_of(account), token_id) == 0, 2)
    }
}
