// Barn
module woolf_deployer::barn {
    use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenId};
    use aptos_std::table::{Self, Table};
    use aptos_std::debug;
    use std::vector;
    use std::signer;
    use std::string;

    friend woolf_deployer::woolf;
    use woolf_deployer::config;

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
        items: Table<TokenId, vector<Stake>>
    }

    public(friend) fun initialize(framework: &signer) {
        move_to(framework, Barn { items: table::new() });
        move_to(framework, Pack { total_alpha_staked: 0, items: table::new<TokenId, vector<Stake>>() });
    }

    public(friend) fun add_many_to_barn_and_pack(account: address, token_ids: vector<TokenId>) acquires Barn, Pack {
        // assert!(account == @woolf_deployer, EINVALID_CALLER);
        let i = 0;
        while (i < vector::length<TokenId>(&token_ids)) {
            // TODO transfer token to this

            let token_id = vector::borrow(&token_ids, i);
            if (isSheep(*token_id)) {
                add_sheep_to_barn(account, *token_id);
            } else {
                add_wolf_to_pack(account, *token_id);
            };

            i = i + 1;
        };
    }

    fun isSheep(token_id: TokenId): bool {
        debug::print(&token_id);
        false
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
        if (!table::contains(&mut pack.items, token_id)) {
            table::add(&mut pack.items, token_id, vector::empty());
        };
        let token_pack = table::borrow_mut(&mut pack.items, token_id);
        vector::push_back(token_pack, stake);
    }

    fun alpha_for_wolf(token_id: TokenId): u8 {
        debug::print(&token_id);
        let alpha_index = 0;
        MAX_ALPHA - alpha_index // alpha index is 0-3
    }

    #[test(account = @woolf_deployer)]
    fun test_add_sheep_to_barn(account: &signer, ) acquires Barn {
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
    fun test_add_wolf_to_pack(account: &signer, ) acquires Pack {
        let account_addr = signer::address_of(account);
        let token_id = token::create_token_id_raw(
            account_addr,
            config::collection_name_v1(),
            string::utf8(b"123"),
            0
        );
        initialize(account);
        add_wolf_to_pack(account_addr, token_id);
        let pack = borrow_global_mut<Pack>(@woolf_deployer);
        let token_pack = table::borrow(&mut pack.items, token_id);
        assert!(vector::length(token_pack) == 1, 1);
    }
}