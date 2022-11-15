module woolf_deployer::Wool {
    use std::string;
    use std::error;
    use std::signer;
    use aptos_framework::coin::{Self, MintCapability, BurnCapability};

    const ENO_CAPABILITIES: u64 = 1;

    const DEPLOYER: address = @woolf_deployer;

    struct Wool {}

    struct Caps has key {
        mint: MintCapability<Wool>,
        burn: BurnCapability<Wool>,
    }

    fun init_module(admin: &signer) {
        let (burn, freeze, mint) = coin::initialize<Wool>(
            admin, string::utf8(b"Woolf Game"), string::utf8(b"WOOL"), 8, true);
        coin::destroy_freeze_cap(freeze);
        move_to(admin, Caps { mint, burn });
        coin::register<Wool>(admin);
    }

    public fun has_capability(account_addr: address): bool {
        exists<Caps>(account_addr)
    }

    public entry fun register_coin(account: &signer) {
        if (!coin::is_account_registered<Wool>(signer::address_of(account))) {
            coin::register<Wool>(account);
        };
    }

    public entry fun mint(
        account: &signer,
        to: address, amount: u64
    ) acquires Caps {
        let account_addr = signer::address_of(account);

        assert!(
            has_capability(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );

        let mint_cap = &borrow_global<Caps>(account_addr).mint;
        let coins_minted = coin::mint<Wool>(amount, mint_cap);

        // if (!coin::is_account_registered<Wool>(to)) {
        //     coin::register<Wool>(to);
        // };
        coin::deposit<Wool>(to, coins_minted);
    }

    public entry fun burn_from(account_addr: address, amount: u64) acquires Caps {
        assert!(
            has_capability(account_addr),
            error::not_found(ENO_CAPABILITIES),
        );
        let burn_cap = &borrow_global<Caps>(account_addr).burn;
        coin::burn_from<Wool>(account_addr, amount, burn_cap);
    }

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