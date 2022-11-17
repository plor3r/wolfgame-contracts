/*
Provides a singleton wrapper around PropertyMap to allow for easy and dynamic configurability of contract options.
This includes things like the maximum number of years that a name can be registered for, etc.

Anyone can read, but only admins can write, as all write methods are gated via permissions checks
*/

module woolf_deployer::config {
    friend woolf_deployer::woolf;

    use aptos_std::ed25519::{Self, UnvalidatedPublicKey};
    use aptos_token::property_map::{Self, PropertyMap};
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;

    const CONFIG_KEY_ENABLED: vector<u8> = b"enabled";
    const CONFIG_KEY_ADMIN_ADDRESS: vector<u8> = b"admin_address";
    const CONFIG_KEY_FUND_DESTINATION_ADDRESS: vector<u8> = b"fund_destination_address";
    const CONFIG_KEY_TOKENDATA_DESCRIPTION: vector<u8> = b"tokendata_description";
    const CONFIG_KEY_TOKENDATA_URL_PREFIX: vector<u8> = b"tokendata_url_prefix";

    const COLLECTION_NAME_V1: vector<u8> = b"Woolf Game NFT";

    //
    // Errors
    //

    /// Raised if the signer is not authorized to perform an action
    const ENOT_AUTHORIZED: u64 = 1;
    /// Raised if there is an invalid value for a configuration
    const EINVALID_VALUE: u64 = 2;

    struct ConfigurationV1 has key, store {
        config: PropertyMap,
    }

    public(friend) fun initialize_v1(framework: &signer, admin_address: address) acquires ConfigurationV1 {
        move_to(framework, ConfigurationV1 {
            config: property_map::empty(),
        });
        // Temporarily set this to framework to allow other methods below to be set with framework signer
        set_v1(@woolf_deployer, config_key_admin_address(), &signer::address_of(framework));

        set_is_enabled(framework, true);

        // TODO: SET THIS TO SOMETHING REAL
        set_tokendata_description(framework, string::utf8(b"This is an Woolf Game NFT"));
        set_tokendata_url_prefix(framework, string::utf8(b"https://www.aptosnames.com/api/mainnet/v1/metadata/"));

        // We set it directly here to allow boostrapping the other values
        set_v1(@woolf_deployer, config_key_fund_destination_address(), &@woolf_deployer_fund);
        set_v1(@woolf_deployer, config_key_admin_address(), &admin_address);
    }


    //
    // Configuration Shortcuts
    //

    public fun octas(): u64 {
        100000000
    }

    public fun is_enabled(): bool acquires ConfigurationV1 {
        read_bool_v1(@woolf_deployer, &config_key_enabled())
    }

    public fun fund_destination_address(): address acquires ConfigurationV1 {
        read_address_v1(@woolf_deployer, &config_key_fund_destination_address())
    }

    public fun tokendata_description(): String acquires ConfigurationV1 {
        read_string_v1(@woolf_deployer, &config_key_tokendata_description())
    }

    public fun tokendata_url_prefix(): String acquires ConfigurationV1 {
        read_string_v1(@woolf_deployer, &config_key_tokendata_url_prefix())
    }

    /// Admins will be able to intervene when necessary.
    /// The account will be used to manage names that are being used in a way that is harmful to others.
    /// Alternatively, the deployer can be used to perform admin actions.
    public fun signer_is_admin(sign: &signer): bool acquires ConfigurationV1 {
        signer::address_of(sign) == admin_address() || signer::address_of(sign) == @woolf_deployer
    }

    public fun assert_signer_is_admin(sign: &signer) acquires ConfigurationV1 {
        assert!(signer_is_admin(sign), error::permission_denied(ENOT_AUTHORIZED));
    }

    public fun collection_name_v1(): String {
        return string::utf8(COLLECTION_NAME_V1)
    }

    //
    // Setters
    //

    public entry fun set_is_enabled(sign: &signer, enabled: bool) acquires ConfigurationV1 {
        assert_signer_is_admin(sign);
        set_v1(@woolf_deployer, config_key_enabled(), &enabled)
    }

    public entry fun set_tokendata_description(sign: &signer, description: String) acquires ConfigurationV1 {
        assert_signer_is_admin(sign);
        set_v1(@woolf_deployer, config_key_tokendata_description(), &description)
    }

    public entry fun set_tokendata_url_prefix(sign: &signer, description: String) acquires ConfigurationV1 {
        assert_signer_is_admin(sign);
        set_v1(@woolf_deployer, config_key_tokendata_url_prefix(), &description)
    }

    //
    // Configuration Methods
    //

    public fun config_key_enabled(): String {
        string::utf8(CONFIG_KEY_ENABLED)
    }

    public fun config_key_admin_address(): String {
        string::utf8(CONFIG_KEY_ADMIN_ADDRESS)
    }

    public fun config_key_fund_destination_address(): String {
        string::utf8(CONFIG_KEY_FUND_DESTINATION_ADDRESS)
    }

    public fun admin_address(): address acquires ConfigurationV1 {
        read_address_v1(@woolf_deployer, &config_key_admin_address())
    }

    public fun config_key_tokendata_description(): String {
        string::utf8(CONFIG_KEY_TOKENDATA_DESCRIPTION)
    }

    public fun config_key_tokendata_url_prefix(): String {
        string::utf8(CONFIG_KEY_TOKENDATA_URL_PREFIX)
    }


    //
    // basic methods
    //

    fun set_v1<T: copy>(addr: address, config_name: String, value: &T) acquires ConfigurationV1 {
        let map = &mut borrow_global_mut<ConfigurationV1>(addr).config;
        let value = property_map::create_property_value(value);
        if (property_map::contains_key(map, &config_name)) {
            property_map::update_property_value(map, &config_name, value);
        } else {
            property_map::add(map, config_name, value);
        };
    }

    public fun read_string_v1(addr: address, key: &String): String acquires ConfigurationV1 {
        property_map::read_string(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_u8_v1(addr: address, key: &String): u8 acquires ConfigurationV1 {
        property_map::read_u8(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_u64_v1(addr: address, key: &String): u64 acquires ConfigurationV1 {
        property_map::read_u64(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_address_v1(addr: address, key: &String): address acquires ConfigurationV1 {
        property_map::read_address(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_u128_v1(addr: address, key: &String): u128 acquires ConfigurationV1 {
        property_map::read_u128(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_bool_v1(addr: address, key: &String): bool acquires ConfigurationV1 {
        property_map::read_bool(&borrow_global<ConfigurationV1>(addr).config, key)
    }

    public fun read_unvalidated_public_key(addr: address, key: &String): UnvalidatedPublicKey acquires ConfigurationV1 {
        let value = property_map::borrow_value(property_map::borrow(&borrow_global<ConfigurationV1>(addr).config, key));
        // remove the length of this vector recorded at index 0
        vector::remove(&mut value, 0);
        ed25519::new_unvalidated_public_key_from_bytes(value)
    }
}
