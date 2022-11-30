module woolf_deployer::wool_pouch {
    use std::signer;
    use std::error;
    use aptos_std::table::Table;
    use aptos_std::table;
    use aptos_framework::account;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    use woolf_deployer::wool;
    use std::vector;

    //
    // Errors
    //
    const ENOT_OWNER: u64 = 1;
    const ENOT_CONTROLLERS: u64 = 2;
    const EINSUFFICIENT_POUCH: u64 = 3;
    const EPAUSED: u64 = 4;
    const EPOUCH_NOT_FOUND: u64 = 5;
    const ENO_MORE_EARNINGS_AVAILABLE: u64 = 6;

    //
    // constants
    //
    const START_VALUE: u64 = 10000 * 100000000;
    const SECONDS_PER_DAY: u64 = 86400;

    struct Pouch has store {
        // whether or not first 10,000 WOOL has been claimed
        initial_claimed: bool,
        // stored in days, maxed at 2^16 days
        duration: u64,
        // stored in seconds, uint56 can store 2 billion years
        last_claim_timestamp: u64,
        // stored in seconds, uint56 can store 2 billion years
        start_timestamp: u64,
        // max value, 120 bits is far beyond 5 billion wool supply
        // FIXME u128?
        amount: u64
    }

    struct Data has key {
        controllers: Table<address, bool>,
        pouches: Table<u64, Pouch>,
        minted: u64,
        paused: bool,
    }

    struct WoolClaimedEvent has store, drop {
        recipient: address,
        token_id: u64,
        amount: u64,
    }

    struct Events has key {
        wool_claimed_events: event::EventHandle<WoolClaimedEvent>,
    }

    public(friend) fun initialize(framework: &signer) {
        move_to(framework, Data {
            controllers: table::new<address, bool>(),
            pouches: table::new(),
            minted: 0,
            paused: false,
        });
        move_to(framework, Events {
            wool_claimed_events: account::new_event_handle<WoolClaimedEvent>(framework),
        });
    }

    fun assert_not_paused() acquires Data {
        let data = borrow_global<Data>(@woolf_deployer);
        assert!(&data.paused == &false, error::permission_denied(EPAUSED));
    }

    public entry fun set_paused(paused: bool) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        data.paused = paused;
    }

    // claim WOOL tokens from a pouch
    public entry fun claim(owner: &signer, token_id: u64) acquires Data, Events {
        assert_not_paused();
        // FIXME add token assert owner

        let data = borrow_global_mut<Data>(@woolf_deployer);
        let available = amount_available_internal(data, token_id);
        assert!(available > 0, error::invalid_state(ENO_MORE_EARNINGS_AVAILABLE));
        assert!(table::contains(&data.pouches, token_id), error::not_found(EPOUCH_NOT_FOUND));
        let pouch = table::borrow_mut(&mut data.pouches, token_id);
        pouch.last_claim_timestamp = timestamp::now_seconds();
        if (!pouch.initial_claimed) { pouch.initial_claimed = true; };
        wool::mint_internal(signer::address_of(owner), available);
        event::emit_event<WoolClaimedEvent>(
            &mut borrow_global_mut<Events>(@woolf_deployer).wool_claimed_events,
            WoolClaimedEvent {
                recipient: signer::address_of(owner), token_id, amount: available
            },
        );
    }

    public entry fun claim_many(owner: &signer, token_ids: vector<u64>) acquires Data, Events {
        assert_not_paused();
        let available: u64;
        let total_available: u64 = 0;
        let i: u64 = 0;
        let data = borrow_global_mut<Data>(@woolf_deployer);
        while (i < vector::length(&token_ids)) {
            // FIXME add token assert owner
            let token_id = *vector::borrow(&token_ids, i);
            available = amount_available_internal(data, token_id);
            assert!(table::contains(&data.pouches, token_id), error::not_found(EPOUCH_NOT_FOUND));

            let pouch = table::borrow_mut(&mut data.pouches, token_id);
            pouch.last_claim_timestamp = timestamp::now_seconds();
            if (!pouch.initial_claimed) { pouch.initial_claimed = true; };
            event::emit_event<WoolClaimedEvent>(
                &mut borrow_global_mut<Events>(@woolf_deployer).wool_claimed_events,
                WoolClaimedEvent {
                    recipient: signer::address_of(owner), token_id, amount: available
                },
            );
            total_available = total_available + available;
            i = i + 1;
        };
        assert!(total_available > 0, error::invalid_state(ENO_MORE_EARNINGS_AVAILABLE));
        wool::mint_internal(signer::address_of(owner), total_available);
    }

    // the amount of WOOL currently available to claim in a WOOL pouch
    public fun amount_available(token_id: u64): u64 acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        amount_available_internal(data, token_id)
    }

    // the amount of WOOL currently available to claim in a WOOL pouch
    fun amount_available_internal(data: &mut Data, token_id: u64): u64 {
        // let data = borrow_global_mut<Data>(@woolf_deployer);
        assert!(table::contains(&data.pouches, token_id), error::not_found(EPOUCH_NOT_FOUND));
        let pouch = table::borrow_mut(&mut data.pouches, token_id);
        let current_timestamp = timestamp::now_seconds();
        if (current_timestamp > pouch.start_timestamp + pouch.duration * SECONDS_PER_DAY) {
            current_timestamp = pouch.start_timestamp + pouch.duration * SECONDS_PER_DAY;
        };
        if (pouch.last_claim_timestamp > current_timestamp) { return 0 };
        let elapsed = current_timestamp - pouch.last_claim_timestamp;
        elapsed * pouch.amount / (pouch.duration * SECONDS_PER_DAY) + if (pouch.initial_claimed) 0 else START_VALUE
    }

    /** CONTROLLER */

    // mints $WOOL to a recipient
    public entry fun mint(controller: &signer, to: address, amount: u64, duration: u64) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let controller_addr = signer::address_of(controller);
        assert!(
            table::contains(&data.controllers, controller_addr) &&
                table::borrow(&data.controllers, controller_addr) == &true,
            error::permission_denied(ENOT_CONTROLLERS)
        );
        assert!(amount >= START_VALUE, error::invalid_state(EINSUFFICIENT_POUCH));
        data.minted = data.minted + 1;
        table::add(&mut data.pouches, data.minted, Pouch {
            initial_claimed: false,
            duration,
            last_claim_timestamp: timestamp::now_seconds(),
            start_timestamp: timestamp::now_seconds(),
            amount: amount - START_VALUE
        });
        mint_internal(to, data.minted);
    }

    public entry fun mint_without_claimable(
        controller: &signer,
        to: address,
        amount: u64,
        duration: u64
    ) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let controller_addr = signer::address_of(controller);
        assert!(
            table::contains(&data.controllers, controller_addr) &&
                table::borrow(&data.controllers, controller_addr) == &true,
            error::permission_denied(ENOT_CONTROLLERS)
        );
        data.minted = data.minted + 1;
        table::add(&mut data.pouches, data.minted, Pouch {
            initial_claimed: true,
            duration,
            last_claim_timestamp: timestamp::now_seconds(),
            start_timestamp: timestamp::now_seconds(),
            amount,
        });
        mint_internal(to, data.minted);
    }

    fun mint_internal(_to: address, _token_name: u64) {}

    // enables an address to mint
    public entry fun add_controller(owner: &signer, controller: address) acquires Data {
        assert!(signer::address_of(owner) == @woolf_deployer, error::permission_denied(ENOT_OWNER));
        let data = borrow_global_mut<Data>(@woolf_deployer);
        table::upsert(&mut data.controllers, controller, true);
    }

    // disables an address from minting
    public entry fun remove_controller(owner: &signer, controller: address) acquires Data {
        assert!(signer::address_of(owner) == @woolf_deployer, error::permission_denied(ENOT_OWNER));
        let data = borrow_global_mut<Data>(@woolf_deployer);
        table::upsert(&mut data.controllers, controller, false);
    }
}
