module woolf_deployer::traits {
    use std::error;
    use std::string::{Self, String};
    use std::vector;
    // use std::debug;
    use aptos_std::table::Table;
    use aptos_std::table;
    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    friend woolf_deployer::woolf;
    friend woolf_deployer::barn;

    const EMISMATCHED_INPUT: u64 = 1;
    const ETOKEN_NOT_FOUND: u64 = 2;

    // struct to store each trait's data for metadata and rendering
    struct Trait has store, drop, copy {
        name: String,
        png: String,
    }

    struct TraitData {
        items: Table<u8, Trait>
    }

    struct Data has key {
        trait_types: vector<String>,
        trait_data: Table<u8, Table<u8, Trait>>,
        // {trait_type => {id => trait}}
        alphas: vector<vector<u8>>,
        token_traits: Table<TokenId, SheepWolf>,
        index_traits: Table<u64, SheepWolf>
    }

    struct SheepWolf has drop, store, copy, key {
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

    public(friend) fun initialize(account: &signer) {
        let trait_types: vector<String> = vector[
            string::utf8(b"Fur"),
            string::utf8(b"Head"),
            string::utf8(b"Ears"),
            string::utf8(b"Eyes"),
            string::utf8(b"Nose"),
            string::utf8(b"Mouth"),
            string::utf8(b"Neck"),
            string::utf8(b"Feet"),
            string::utf8(b"Alpha"),
            string::utf8(b"IsSheep"),
        ];
        let trait_data: Table<u8, Table<u8, Trait>> = table::new();
        let alphas = vector[b"8", b"7", b"6", b"5"];

        move_to(
            account,
            Data { trait_types, trait_data, alphas, token_traits: table::new(), index_traits: table::new() }
        );
    }

    public(friend) fun update_token_traits(
        token_id: TokenId,
        is_sheep: bool,
        fur: u8,
        head: u8,
        ears: u8,
        eyes: u8,
        nose: u8,
        mouth: u8,
        neck: u8,
        feet: u8,
        alpha_index: u8
    ) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        table::upsert(&mut data.token_traits, token_id, SheepWolf {
            is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index,
        });
        let (_,_,name,_) = token::get_token_id_fields(&token_id);
        let token_index: u64 = 0;
        let name_bytes = *string::bytes(&name);
        let i = 0;
        let k: u64 = 1;
        while ( i < vector::length(&name_bytes) ) {
            let n = vector::pop_back(&mut name_bytes);
            if (vector::singleton(n) == b"#") {
                break
            };
            token_index = token_index + ((n as u64) - 48) * k;
            k = k * 10;
            i = i + 1;
        };
        table::upsert(&mut data.index_traits, token_index, SheepWolf {
            is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index,
        });
    }

    public fun get_index_traits(
        // _token_owner: address,
        token_index: u64
    ): (bool, u8, u8, u8, u8, u8, u8, u8, u8, u8) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let traits = table::borrow(&data.index_traits, token_index);

        let SheepWolf { is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index } = *traits;

        (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index)
    }

    public fun get_token_traits(
        _token_owner: address,
        token_id: TokenId
    ): (bool, u8, u8, u8, u8, u8, u8, u8, u8, u8) acquires Data {
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let traits = table::borrow(&data.token_traits, token_id);

        let SheepWolf { is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index } = *traits;

        (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index)

        // // FIXME
        // debug::print(&5);
        // debug::print(&token_owner);
        // debug::print(&token_id);
        // let properties = token::get_property_map(token_owner, token_id);
        // debug::print(&properties);
        // debug::print(&6);
        // let data = borrow_global_mut<Data>(@woolf_deployer);
        // debug::print(&1001);
        // debug::print(vector::borrow(&data.trait_types, 0));
        // let fur = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 0));
        // debug::print(&1002);
        // let head = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 1));
        // debug::print(&1003);
        // let ears = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 2));
        // debug::print(&1004);
        // let eyes = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 3));
        // debug::print(&1005);
        // let nose = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 4));
        // debug::print(&1006);
        // let mouth = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 5));
        // debug::print(&1007);
        // let neck = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 6));
        // debug::print(&1008);
        // let feet = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 7));
        // debug::print(&1009);
        // let alpha_index = property_map::read_u8(&properties, vector::borrow(&data.trait_types, 8));
        // debug::print(&1010);
        // let is_sheep = property_map::read_bool(&properties, vector::borrow(&data.trait_types, 9));
        // debug::print(&1011);
        // // debug::print(&SheepWolf { is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index });
        // (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index)
    }

    public fun is_sheep(token_id: TokenId): bool acquires Data {
        let data = borrow_global<Data>(@woolf_deployer);
        assert!(table::contains(&data.token_traits, token_id), error::not_found(ETOKEN_NOT_FOUND));
        let sw = table::borrow(&data.token_traits, token_id);
        return sw.is_sheep
    }

    public fun get_name_property_map(
        is_sheep: bool, fur: u8, head: u8, ears: u8, eyes: u8, nose: u8, mouth: u8, neck: u8, feet: u8, alpha_index: u8
    ): (vector<String>, vector<vector<u8>>, vector<String>) acquires Data {
        let is_sheep_value = property_map::create_property_value(&is_sheep);
        let fur_value = property_map::create_property_value(&fur);
        let head_value = property_map::create_property_value(&head);
        let ears_value = property_map::create_property_value(&ears);
        let eyes_value = property_map::create_property_value(&eyes);
        let nose_value = property_map::create_property_value(&nose);
        let mouth_value = property_map::create_property_value(&mouth);
        let neck_value = property_map::create_property_value(&neck);
        let feet_value = property_map::create_property_value(&feet);
        let alpha_value = property_map::create_property_value(&alpha_index);

        let data = borrow_global<Data>(@woolf_deployer);
        let property_keys = data.trait_types;
        let property_values: vector<vector<u8>> = vector[
            property_map::borrow_value(&fur_value),
            property_map::borrow_value(&head_value),
            property_map::borrow_value(&ears_value),
            property_map::borrow_value(&eyes_value),
            property_map::borrow_value(&nose_value),
            property_map::borrow_value(&mouth_value),
            property_map::borrow_value(&neck_value),
            property_map::borrow_value(&feet_value),
            property_map::borrow_value(&alpha_value),
            property_map::borrow_value(&is_sheep_value),
        ];
        let property_types: vector<String> = vector[
            property_map::borrow_type(&fur_value),
            property_map::borrow_type(&head_value),
            property_map::borrow_type(&ears_value),
            property_map::borrow_type(&eyes_value),
            property_map::borrow_type(&nose_value),
            property_map::borrow_type(&mouth_value),
            property_map::borrow_type(&neck_value),
            property_map::borrow_type(&feet_value),
            property_map::borrow_type(&alpha_value),
            property_map::borrow_type(&is_sheep_value),
        ];
        (property_keys, property_values, property_types)
    }
}
