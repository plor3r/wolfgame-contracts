module woolf_deployer::wool {
    use std::string;
    use std::error;
    use std::signer;
    use aptos_framework::coin::{Self, MintCapability, BurnCapability};

    friend woolf_deployer::woolf;
    friend woolf_deployer::barn;

    const ENO_CAPABILITIES: u64 = 1;
    const ENOT_ADMIN: u64 = 2;

    struct Wool {}

    struct Caps has key {
        mint: MintCapability<Wool>,
        burn: BurnCapability<Wool>,
    }

    public(friend) fun initialize(admin: &signer) {
        let (burn, freeze, mint) = coin::initialize<Wool>(
            admin, string::utf8(b"Woolf Game"), string::utf8(b"WOOL"), 8, true);
        coin::destroy_freeze_cap(freeze);
        move_to(admin, Caps { mint, burn });
        coin::register<Wool>(admin);
    }

    fun has_capability(account_addr: address): bool {
        exists<Caps>(account_addr)
    }

    public entry fun register_coin(account: &signer) {
        if (!coin::is_account_registered<Wool>(signer::address_of(account))) {
            coin::register<Wool>(account);
        };
    }

    #[test_only]
    public(friend) fun register_coin_test(account: &signer) {
        if (!coin::is_account_registered<Wool>(signer::address_of(account))) {
            coin::register<Wool>(account);
        };
    }

    public(friend) fun mint_internal(
        to: address, amount: u64
    ) acquires Caps {
        let account_addr = @woolf_deployer;

        assert!(
            has_capability(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let mint_cap = &borrow_global<Caps>(account_addr).mint;
        let coins_minted = coin::mint<Wool>(amount, mint_cap);

        coin::deposit<Wool>(to, coins_minted);
    }

    public entry fun mint_to(account: &signer, to: address, amount: u64) acquires Caps {
        assert!(signer::address_of(account) == @woolf_deployer, error::permission_denied(ENOT_ADMIN));
        mint_internal(to, amount);
    }

    // Admin burn
    public entry fun burn_from(account: &signer, from: address, amount: u64) acquires Caps {
        let account_addr = signer::address_of(account);
        assert!(account_addr == @woolf_deployer, error::permission_denied(ENOT_ADMIN));
        let admin = @woolf_deployer;
        assert!(
            has_capability(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );
        let burn_cap = &borrow_global<Caps>(admin).burn;
        coin::burn_from<Wool>(from, amount, burn_cap);
    }

    // burn self
    public entry fun burn(
        account: &signer,
        amount: u64,
    ) acquires Caps {
        let account_addr = signer::address_of(account);
        assert!(
            has_capability(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );
        let burn_cap = &borrow_global<Caps>(account_addr).burn;
        let to_burn = coin::withdraw<Wool>(account, amount);
        coin::burn(to_burn, burn_cap);
    }
}