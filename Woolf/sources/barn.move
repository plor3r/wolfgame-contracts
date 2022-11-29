// Barn
module woolf_deployer::barn {
    use std::error;
    use std::signer;
    use std::vector;
    // use std::debug;
    use std::string::String;

    use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenId, Token};
    use aptos_std::table::{Self, Table};
    use aptos_std::debug;

    use woolf_deployer::random;
    use woolf_deployer::wool;
    use woolf_deployer::token_helper;
    use woolf_deployer::traits;

    friend woolf_deployer::woolf;

    // maximum alpha score for a Wolf
    const MAX_ALPHA: u8 = 8;
    // sheep earn 10000 $WOOL per day
    const DAILY_WOOL_RATE: u64 = 10000 * 100000000;
    // sheep must have 2 days worth of $WOOL to unstake or else it's too cold

    // FIXME const MINIMUM_TO_EXIT: u64 = 2 * 86400;
    const MINIMUM_TO_EXIT: u64 = 60;
    const ONE_DAY_IN_SECOND: u64 = 86400;
    // wolves take a 20% tax on all $WOOL claimed
    const WOOL_CLAIM_TAX_PERCENTAGE: u64 = 20;
    // there will only ever be (roughly) 2.4 billion $WOOL earned through staking
    const MAXIMUM_GLOBAL_WOOL: u64 = 2400000000 * 100000000;

    //
    // Errors
    //
    const EINVALID_CALLER: u64 = 0;
    const EINVALID_OWNER: u64 = 1;
    const ESTILL_COLD: u64 = 2;
    const ENOT_IN_PACK: u64 = 3;

    // struct to store a stake's token, owner, and earning values
    struct Stake has key, store {
        token: Token,
        value: u64,
        owner: address,
    }

    struct Barn has key {
        items: Table<TokenId, Stake>,
    }

    struct Pack has key {
        items: Table<u8, vector<Stake>>,
        pack_indices: Table<TokenId, u64>,
    }

    struct Data has key {
        // amount of $WOOL earned so far
        total_wool_earned: u64,
        // number of Sheep staked in the Barn
        total_sheep_staked: u64,
        // the last time $WOOL was claimed
        last_claim_timestamp: u64,
        // total alpha scores staked
        total_alpha_staked: u64,
        // any rewards distributed when no wolves are staked
        unaccounted_rewards: u64,
        // amount of $WOOL due for each alpha point staked
        wool_per_alpha: u64,
    }

    public(friend) fun initialize(framework: &signer) {
        move_to(framework, Barn { items: table::new<TokenId, Stake>() });
        move_to(framework, Pack { items: table::new<u8, vector<Stake>>(), pack_indices: table::new<TokenId, u64>() });
        move_to(framework, Data {
            total_wool_earned: 0,
            total_sheep_staked: 0,
            last_claim_timestamp: 0,
            total_alpha_staked: 0,
            unaccounted_rewards: 0,
            wool_per_alpha: 0,
        });
    }

    public entry fun add_many_to_barn_and_pack(
        staker: &signer,
        collection_name: String,
        token_name: String,
        property_version: u64,
    ) acquires Barn, Pack, Data {
        let token_id = token_helper::create_token_id(collection_name, token_name, property_version);
        let token = token::withdraw_token(staker, token_id, 1);
        let tokens = vector<Token>[token];
        add_many_to_barn_and_pack_internal(signer::address_of(staker), tokens);
    }

    // adds Sheep and Wolves to the Barn and Pack
    public(friend) fun add_many_to_barn_and_pack_internal(
        owner: address,
        tokens: vector<Token>
    ) acquires Barn, Pack, Data {
        let i = vector::length<Token>(&tokens);
        while (i > 0) {
            let token = vector::pop_back(&mut tokens);
            let token_id = token::get_token_id(&token);
            if (traits::is_sheep(token_id)) {
                add_sheep_to_barn(owner, token);
            } else {
                add_wolf_to_pack(owner, token);
            };
            i = i - 1;
        };
        vector::destroy_empty(tokens)
    }

    // adds a single Sheep to the Barn
    fun add_sheep_to_barn(owner: address, token: Token) acquires Barn, Data {
        update_earnings();
        let token_id = token::get_token_id(&token);
        let stake = Stake {
            token,
            value: timestamp::now_seconds(),
            owner: owner,
        };
        let data = borrow_global_mut<Data>(@woolf_deployer);
        data.total_sheep_staked = data.total_sheep_staked + 1;

        let barn = borrow_global_mut<Barn>(@woolf_deployer);
        table::add(&mut barn.items, token_id, stake);
    }

    // adds a single Wolf to the Pack
    fun add_wolf_to_pack(owner: address, token: Token) acquires Pack, Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let token_id = token::get_token_id(&token);

        // Portion of earnings ranges from 8 to 5
        let alpha = alpha_for_wolf(owner, token_id);
        data.total_alpha_staked = data.total_alpha_staked + (alpha as u64);

        let stake = Stake {
            token,
            value: data.wool_per_alpha,
            owner: owner,
        };

        // Add the wolf to the Pack
        let pack = borrow_global_mut<Pack>(@woolf_deployer);
        if (!table::contains(&mut pack.items, alpha)) {
            table::add(&mut pack.items, alpha, vector::empty());
        };

        let token_pack = table::borrow_mut(&mut pack.items, alpha);
        vector::push_back(token_pack, stake);

        // Store the location of the wolf in the Pack
        let token_index = vector::length(token_pack) - 1;
        table::upsert(&mut pack.pack_indices, token_id, token_index);
    }

    // add $WOOL to claimable pot for the Pack
    fun pay_wolf_tax(data: &mut Data, amount: u64) {
        // let data = borrow_global_mut<Data>(@woolf_deployer);
        if (data.total_alpha_staked == 0) {
            // if there's no staked wolves
            data.unaccounted_rewards = data.unaccounted_rewards + amount; // keep track of $WOOL due to wolves
            return
        };
        // makes sure to include any unaccounted $WOOL
        data.wool_per_alpha = data.wool_per_alpha + (amount + data.unaccounted_rewards) / data.total_alpha_staked;
        data.unaccounted_rewards = 0;
    }

    /** CLAIMING / UNSTAKING */

    public entry fun claim_many_from_barn_and_pack(
        staker: &signer,
        // creator: address,
        collection_name: String, //the name of the collection owned by Creator
        token_name: String,
        property_version: u64,
    ) acquires Barn, Pack, Data {
        let token_id = token_helper::create_token_id(collection_name, token_name, property_version);
        let token_ids = vector<TokenId>[token_id];
        claim_many_from_barn_and_pack_internal(staker, token_ids, true);
    }

    // realize $WOOL earnings and optionally unstake tokens from the Barn / Pack
    // to unstake a Sheep it will require it has 2 days worth of $WOOL unclaimed
    public entry fun claim_many_from_barn_and_pack_internal(
        account: &signer,
        token_ids: vector<TokenId>,
        unstake: bool
    ) acquires Data, Barn, Pack {
        update_earnings();
        let owed: u64 = 0;
        let i: u64 = 0;
        while (i < vector::length(&token_ids)) {
            if (traits::is_sheep(*vector::borrow(&token_ids, i))) {
                owed = owed + claim_sheep_from_barn(account, *vector::borrow(&token_ids, i), unstake);
            } else {
                owed = owed + claim_wolf_from_pack(account, *vector::borrow(&token_ids, i), unstake);
            };
            i = i + 1;
        };
        if (owed == 0) { return };
        wool::mint_internal(signer::address_of(account), owed);
    }

    // realize $WOOL earnings for a single Sheep and optionally unstake it
    // if not unstaking, pay a 20% tax to the staked Wolves
    // if unstaking, there is a 50% chance all $WOOL is stolen
    fun claim_sheep_from_barn(owner: &signer, token_id: TokenId, unstake: bool): u64 acquires Barn, Data {
        let barn = borrow_global_mut<Barn>(@woolf_deployer);
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let stake = table::borrow_mut(&mut barn.items, token_id);
        assert!(signer::address_of(owner) == stake.owner, error::permission_denied(EINVALID_OWNER));
        assert!(
            !(unstake && timestamp::now_seconds() - stake.value < MINIMUM_TO_EXIT),
            error::invalid_state(ESTILL_COLD)
        );
        let owed: u64;
        if (data.total_wool_earned < MAXIMUM_GLOBAL_WOOL) {
            owed = ((timestamp::now_seconds() - stake.value) * DAILY_WOOL_RATE) / ONE_DAY_IN_SECOND;
        } else if (stake.value > data.last_claim_timestamp) {
            owed = 0; // $WOOL production stopped already
        } else {
            // stop earning additional $WOOL if it's all been earned
            owed = ((data.last_claim_timestamp - stake.value) * DAILY_WOOL_RATE) / ONE_DAY_IN_SECOND;
        };
        if (unstake) {
            if (random::rand_u64_range_no_sender(0, 2) == 0) {
                // 50% chance of all $WOOL stolen
                pay_wolf_tax(data, owed);
                owed = 0;
            };
            // send back Sheep
            let Stake { token, value: _, owner: _ } = table::remove(&mut barn.items, token_id);
            token::deposit_token(owner, token);
            data.total_sheep_staked = data.total_sheep_staked - 1;
        };
        // TODO emit SheepClaimed(tokenId, owed, unstake);
        owed
    }

    // realize $WOOL earnings for a single Wolf and optionally unstake it
    // Wolves earn $WOOL proportional to their Alpha rank
    fun claim_wolf_from_pack(owner: &signer, token_id: TokenId, unstake: bool): u64 acquires Pack, Data {
        let alpha = alpha_for_wolf(signer::address_of(owner), token_id);
        debug::print(&300);
        let pack = borrow_global_mut<Pack>(@woolf_deployer);
        let stake_vector = table::borrow_mut(&mut pack.items, alpha);
        debug::print(stake_vector);
        let token_index = table::borrow(&mut pack.pack_indices, token_id);
        debug::print(token_index);
        // find the index
        let stake = vector::borrow_mut(stake_vector, *token_index);
        let data = borrow_global_mut<Data>(@woolf_deployer);
        debug::print(&301);
        assert!(signer::address_of(owner) == stake.owner, error::permission_denied(EINVALID_OWNER));
        let owed = (alpha as u64) * (data.wool_per_alpha - stake.value); // Calculate portion of tokens based on Alpha
        debug::print(&owed);
        if (unstake) {
            data.total_alpha_staked = data.total_alpha_staked - (alpha as u64);
            // Shuffle current position to last and then pop
            let last_index = vector::length(stake_vector) - 1;
            vector::swap(stake_vector, *token_index, last_index);
            // update indice
            let token_index = table::borrow(&mut pack.pack_indices, token_id);
            table::upsert(&mut pack.pack_indices, token_id, *token_index);

            let Stake { token, value: _, owner: _ } = vector::pop_back(stake_vector);
            // Send back Wolf
            token::deposit_token(owner, token);
        } else {
            stake.value = data.wool_per_alpha;
            // stake.owner = signer::address_of(owner);
            // stake.token = token;
        };
        // TODO emit WolfClaimed(tokenId, owed, unstake);
        owed
    }

    /** ACCOUNTING */

    fun alpha_for_wolf(token_owner: address, token_id: TokenId): u8 {
        let (_, _, _, _, _, _, _, _, _, alpha_index) = traits::get_token_traits(token_owner, token_id);
        MAX_ALPHA - alpha_index // alpha index is 0-3
    }

    // tracks $WOOL earnings to ensure it stops once 2.4 billion is eclipsed
    fun update_earnings() acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        if (data.total_wool_earned < MAXIMUM_GLOBAL_WOOL) {
            data.total_wool_earned = data.total_wool_earned +
                (timestamp::now_seconds() - data.last_claim_timestamp)
                    * data.total_sheep_staked * DAILY_WOOL_RATE / ONE_DAY_IN_SECOND;
            data.last_claim_timestamp = timestamp::now_seconds();
        }
    }

    // chooses a random Wolf thief when a newly minted token is stolen
    public(friend) fun random_wolf_owner(seed: vector<u8>): address acquires Pack, Data {
        let pack = borrow_global<Pack>(@woolf_deployer);
        let data = borrow_global<Data>(@woolf_deployer);
        if (data.total_alpha_staked == 0) {
            return @0x0
        };
        let bucket = random::rand_u64_range_with_seed(seed, 0, data.total_alpha_staked);
        let cumulative: u64 = 0;
        // loop through each bucket of Wolves with the same alpha score
        let i = MAX_ALPHA - 3;
        // let wolves: &vector<Stake> = &vector::empty();
        while (i <= MAX_ALPHA) {
            let wolves = table::borrow(&pack.items, i);
            cumulative = cumulative + vector::length(wolves) * (i as u64);
            i = i + 1;
            // if the value is not inside of that bucket, keep going
            if (bucket < cumulative) {
                // get the address of a random Wolf with that alpha score
                return vector::borrow(wolves, random::rand_u64_with_seed(seed) % vector::length(wolves)).owner
            }
        };
        @0x0
    }

    public fun assert_unpaused() {}

    //
    // Tests
    //
    #[test_only]
    use std::string;
    #[test_only]
    use woolf_deployer::config;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use woolf_deployer::utils::setup_timestamp;
    // #[test_only]
    // use std::string::String;
    // #[test_only]
    // use aptos_framework::aptos_account;

    // #[test(aptos = @0x1, account = @woolf_deployer)]
    // fun test_add_sheep_to_barn(aptos: &signer, account: &signer) acquires Barn, Data {
    //     setup_timestamp(aptos);
    //     initialize(account);
    //
    //     let account_addr = signer::address_of(account);
    //     let token_id = token::create_token_id_raw(
    //         account_addr,
    //         config::collection_name_v1(),
    //         string::utf8(b"123"),
    //         0
    //     );
    //     add_sheep_to_barn(account_addr, token_id);
    //
    //     let barn = borrow_global<Barn>(@woolf_deployer);
    //     assert!(table::contains(&barn.items, token_id), 1);
    // }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1234)]
    fun test_add_many_to_barn_and_pack(aptos: &signer, admin: &signer, account: &signer) acquires Barn, Pack, Data {
        account::create_account_for_test(signer::address_of(account));
        account::create_account_for_test(signer::address_of(admin));

        setup_timestamp(aptos);
        token_helper::initialize(admin);
        initialize(admin);
        traits::initialize(admin);
        config::initialize(admin, signer::address_of(admin));

        token::initialize_token_store(admin);
        token::opt_in_direct_transfer(admin, true);

        let account_addr = signer::address_of(account);
        let tokendata_id = token_helper::ensure_token_data(string::utf8(b"Wolf #123"));
        let token_id = token_helper::create_token(tokendata_id);

        let creator_addr = token_helper::get_token_signer_address();
        let (property_keys, property_values, property_types) = traits::get_name_property_map(
            true, 1, 0, 0, 2, 1, 0, 1, 0, 1
        );
        token_id = token_helper::set_token_props(
            creator_addr,
            token_id,
            property_keys,
            property_values,
            property_types,
        );
        traits::update_token_traits(token_id, true, 1, 0, 0, 2, 1, 0, 1, 0, 1);
        token_helper::transfer_token_to(account, token_id);
        assert!(token::balance_of(account_addr, token_id) == 1, 1);

        debug::print(&token_id);

        add_many_to_barn_and_pack(account, config::collection_name_v1(), string::utf8(b"Wolf #123"), 1);

        assert!(token::balance_of(account_addr, token_id) == 0, 2);
        let barn = borrow_global<Barn>(@woolf_deployer);
        assert!(table::contains(&barn.items, token_id) == true, 3);
    }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1111)]
    fun test_add_wolf_to_pack(aptos: &signer, admin: &signer, account: &signer) acquires Pack, Data {
        account::create_account_for_test(signer::address_of(account));
        account::create_account_for_test(signer::address_of(admin));
        setup_timestamp(aptos);
        token_helper::initialize(admin);
        initialize(admin);
        traits::initialize(admin);
        config::initialize(admin, signer::address_of(admin));

        let tokendata_id = token_helper::ensure_token_data(string::utf8(b"123"));
        let token_id = token_helper::create_token(tokendata_id);

        let creator_addr = token_helper::get_token_signer_address();
        let (property_keys, property_values, property_types) = traits::get_name_property_map(
            false, 1, 0, 0, 2, 1, 0, 1, 0, 1
        );
        token_id = token_helper::set_token_props(
            creator_addr,
            token_id,
            property_keys,
            property_values,
            property_types,
        );
        traits::update_token_traits(token_id, false, 1, 0, 0, 2, 1, 0, 1, 0, 1);
        token_helper::transfer_token_to(admin, token_id);
        // debug::print(&token_id);
        // let creator = token_helper::get_token_signer();
        let token = token::withdraw_token(admin, token_id, 1);

        add_wolf_to_pack(@woolf_deployer, token);

        // let alpha = alpha_for_wolf(account_addr, token_id);
        // let pack = borrow_global_mut<Pack>(@woolf_deployer);
        // let token_pack = table::borrow(&mut pack.items, alpha);
        // assert!(vector::length(token_pack) == 1, 1);
    }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1111)]
    fun test_claim_sheep_from_barn(aptos: &signer, admin: &signer, account: &signer) acquires Barn, Pack, Data {
        account::create_account_for_test(signer::address_of(account));
        account::create_account_for_test(signer::address_of(admin));

        setup_timestamp(aptos);
        token_helper::initialize(admin);
        initialize(admin);
        traits::initialize(admin);
        config::initialize(admin, signer::address_of(admin));

        token::initialize_token_store(admin);
        token::opt_in_direct_transfer(admin, true);

        let account_addr = signer::address_of(account);
        let tokendata_id = token_helper::ensure_token_data(string::utf8(b"Wolf #123"));
        let token_id = token_helper::create_token(tokendata_id);

        let creator_addr = token_helper::get_token_signer_address();
        let (property_keys, property_values, property_types) = traits::get_name_property_map(
            true, 1, 0, 0, 2, 1, 0, 1, 0, 1
        );
        token_id = token_helper::set_token_props(
            creator_addr,
            token_id,
            property_keys,
            property_values,
            property_types,
        );
        traits::update_token_traits(token_id, true, 1, 0, 0, 2, 1, 0, 1, 0, 1);
        token_helper::transfer_token_to(account, token_id);
        assert!(token::balance_of(account_addr, token_id) == 1, 1);
        add_many_to_barn_and_pack(account, config::collection_name_v1(), string::utf8(b"Wolf #123"), 1);

        timestamp::update_global_time_for_test_secs(200);
        debug::print(&timestamp::now_seconds());
        let data = borrow_global_mut<Data>(@woolf_deployer);
        debug::print(&data.total_sheep_staked);
        claim_sheep_from_barn(account, token_id, true);
    }

    #[test(aptos = @0x1, admin = @woolf_deployer, account = @0x1111)]
    fun test_claim_wolf_from_pack(aptos: &signer, admin: &signer, account: &signer) acquires Pack, Data {
        account::create_account_for_test(signer::address_of(account));
        account::create_account_for_test(signer::address_of(admin));
        setup_timestamp(aptos);
        token_helper::initialize(admin);
        initialize(admin);
        traits::initialize(admin);
        config::initialize(admin, signer::address_of(admin));

        let tokendata_id = token_helper::ensure_token_data(string::utf8(b"123"));
        let token_id = token_helper::create_token(tokendata_id);

        let creator_addr = token_helper::get_token_signer_address();
        let (property_keys, property_values, property_types) = traits::get_name_property_map(
            false, 1, 0, 0, 2, 1, 0, 1, 0, 1
        );
        token_id = token_helper::set_token_props(
            creator_addr,
            token_id,
            property_keys,
            property_values,
            property_types,
        );
        traits::update_token_traits(token_id, false, 1, 0, 0, 2, 1, 0, 1, 0, 1);
        token_helper::transfer_token_to(admin, token_id);
        // debug::print(&token_id);
        // let creator = token_helper::get_token_signer();
        let token = token::withdraw_token(admin, token_id, 1);

        add_wolf_to_pack(signer::address_of(account), token);

        debug::print(&123456);
        assert!(token::balance_of(signer::address_of(account), token_id) == 0, 1);
        claim_wolf_from_pack(account, token_id, true);
        assert!(token::balance_of(signer::address_of(account), token_id) == 1, 1);
    }
}