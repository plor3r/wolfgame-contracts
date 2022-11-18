// Barn
module woolf_deployer::barn {
    use aptos_framework::timestamp;
    use aptos_token::token::TokenId;
    use aptos_std::table::{Self, Table};
    use aptos_std::debug;
    use std::vector;

    use woolf_deployer::random;
    use woolf_deployer::random::rand_u64_with_seed;

    friend woolf_deployer::woolf;

    // maximum alpha score for a Wolf
    const MAX_ALPHA: u8 = 8;

    const EINVALID_CALLER: u64 = 0;

    // struct to store a stake's token, owner, and earning values
    struct Stake has key, store, drop {
        token_id: TokenId,
        value: u64,
        owner: address,
    }

    struct Barn has key, store {
        items: Table<TokenId, Stake>,
    }

    struct Pack has key, store {
        total_alpha_staked: u64,
        items: Table<u8, vector<Stake>>
    }

    public(friend) fun initialize(framework: &signer) {
        move_to(framework, Barn { items: table::new() });
        move_to(framework, Pack { total_alpha_staked: 0, items: table::new<u8, vector<Stake>>() });
    }

    public(friend) fun add_many_to_barn_and_pack(account: address, token_ids: vector<TokenId>) acquires Barn, Pack {
        // assert!(account == @woolf_deployer, EINVALID_CALLER);
        let i = 0;
        while (i < vector::length<TokenId>(&token_ids)) {
            // TODO transfer token to this
            let token_id = vector::borrow(&token_ids, i);
            if (is_sheep(*token_id)) {
                add_sheep_to_barn(account, *token_id);
            } else {
                add_wolf_to_pack(account, *token_id);
            };
            i = i + 1;
        };
    }

    fun is_sheep(_token_id: TokenId): bool {
        // let t = woolf::get_token_traits(token_id);
        // debug::print(&token_id);
        true
    }

    fun add_sheep_to_barn(account: address, token_id: TokenId) acquires Barn {
        let stake = Stake {
            token_id: token_id,
            value: timestamp::now_seconds(),
            owner: account,
        };
        let barn = borrow_global_mut<Barn>(@woolf_deployer);
        table::upsert(&mut barn.items, token_id, stake);
    }

    fun add_wolf_to_pack(account: address, token_id: TokenId) acquires Pack {
        let alpha = alpha_for_wolf(token_id);
        let wool_per_alpha = 0;
        let stake = Stake {
            token_id: token_id,
            value: wool_per_alpha,
            owner: account,
        };
        let pack = borrow_global_mut<Pack>(@woolf_deployer);
        pack.total_alpha_staked = pack.total_alpha_staked + (alpha as u64);
        if (!table::contains(&mut pack.items, alpha)) {
            table::add(&mut pack.items, alpha, vector::empty());
        };
        let token_pack = table::borrow_mut(&mut pack.items, alpha);
        vector::push_back(token_pack, stake);
    }

    fun alpha_for_wolf(_token_id: TokenId): u8 {
        let alpha_index = 0;
        MAX_ALPHA - alpha_index // alpha index is 0-3
    }

    // chooses a random Wolf thief when a newly minted token is stolen
    public(friend) fun random_wolf_owner(seed: vector<u8>): address acquires Pack {
        let pack = borrow_global<Pack>(@woolf_deployer);
        if (pack.total_alpha_staked == 0) {
            return @0x0
        };
        let bucket = random::rand_u64_range_with_seed(seed, 0, pack.total_alpha_staked);
        let cumulative: u64 = 0;
        // loop through each bucket of Wolves with the same alpha score
        let i = MAX_ALPHA - 3;
        // let wolves: &vector<Stake> = &vector::empty();
        while (i <= MAX_ALPHA) {
            let wolves = table::borrow(&pack.items, i);
            cumulative = cumulative + vector::length(wolves) * (i as u64);
            debug::print(&i);

            i = i + 1;
            // if the value is not inside of that bucket, keep going
            if (bucket < cumulative) {
                // get the address of a random Wolf with that alpha score
                return vector::borrow(wolves, rand_u64_with_seed(seed) % vector::length(wolves)).owner
            }
        };
        @0x0
    }

    //
    // Tests
    //
    #[test_only]
    use std::signer;
    #[test_only]
    use std::string;
    #[test_only]
    use woolf_deployer::config;
    #[test_only]
    use aptos_token::token;

    #[test(aptos = @0x1, account = @woolf_deployer)]
    fun test_add_sheep_to_barn(aptos: &signer, account: &signer) acquires Barn {
        timestamp::set_time_has_started_for_testing(aptos);
        // Set the time to a nonzero value to avoid subtraction overflow.
        timestamp::update_global_time_for_test_secs(100);
        let account_addr = signer::address_of(account);
        let token_id = token::create_token_id_raw(
            account_addr,
            config::collection_name_v1(),
            string::utf8(b"123"),
            0
        );
        initialize(account);
        add_sheep_to_barn(account_addr, token_id);
        let barn = borrow_global<Barn>(@woolf_deployer);
        assert!(table::contains(&barn.items, token_id), 1);
    }

    #[test(account = @woolf_deployer)]
    fun test_add_wolf_to_pack(account: &signer) acquires Pack {
        let account_addr = signer::address_of(account);
        let token_id = token::create_token_id_raw(
            account_addr,
            config::collection_name_v1(),
            string::utf8(b"123"),
            0
        );
        initialize(account);
        add_wolf_to_pack(account_addr, token_id);
        let alpha = alpha_for_wolf(token_id);
        let pack = borrow_global_mut<Pack>(@woolf_deployer);
        let token_pack = table::borrow(&mut pack.items, alpha);
        assert!(vector::length(token_pack) == 1, 1);
    }
}