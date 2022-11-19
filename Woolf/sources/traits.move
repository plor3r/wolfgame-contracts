module woolf_deployer::traits {

    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};
    use aptos_std::table::Table;
    use aptos_std::table;
    use aptos_token::token::TokenId;

    use woolf_deployer::base64;

    const EMISMATCHED_INPUT: u64 = 0;

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
        // trait_type => id => trait
        alphas: vector<vector<u8>>,
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
        ];
        let trait_data: Table<u8, Table<u8, Trait>> = table::new();
        let alphas = vector[b"8", b"7", b"6", b"5"];

        move_to(account, Data { trait_types, trait_data, alphas });
    }

    public entry fun upload_traits(
        trait_type: u8,
        trait_ids: vector<u8>,
        traits: vector<Trait>
    ) acquires Data {
        assert!(vector::length(&trait_ids) == vector::length(&traits), EMISMATCHED_INPUT);
        let data = borrow_global_mut<Data>(@woolf_deployer);
        let i = 0;
        let trait_data_table;
        while (i < vector::length(&traits)) {
            if (!table::contains(&data.trait_data, trait_type)) {
                table::add(&mut data.trait_data, trait_type, table::new());
            };
            trait_data_table = table::borrow_mut(&mut data.trait_data, trait_type);
            let trait = Trait {
                name: vector::borrow(&traits, i).name,
                png: vector::borrow(&traits, i).png,
            };
            table::upsert(trait_data_table, *vector::borrow(&trait_ids, i), trait);

            i = i + 1;
        }
    }

    fun get_token_traits(_token_id: TokenId): (bool, u8, u8, u8, u8, u8, u8, u8, u8, u8) {
        return (false, 1, 1, 1, 1, 1, 1, 1, 1, 1)
    }

    public fun draw_trait(trait: Trait): String {
        let s: String = string::utf8(b"");
        // string::append_utf8(&mut s, b"<image x=\"4\" y=\"4\" width=\"32\" height=\"32\" image-rendering=\"pixelated\" preserveAspectRatio=\"xMidYMid\" xlink:href=\"data:image/png;base64,");
        string::append(&mut s, trait.png);
        // string::append_utf8(&mut s, b"\"/>");
        s
    }

    public fun draw_trait_or_none(trait: Option<Trait>): String {
        if (option::is_some(&trait)) {
            draw_trait(option::extract(&mut trait))
        } else {
            string::utf8(b"")
        }
    }

    public fun draw_svg(token_id: TokenId): String acquires Data {
        let (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index): (bool, u8, u8, u8, u8, u8, u8, u8, u8, u8) = get_token_traits(
            token_id
        );
        let shift: u8 = if (is_sheep) 0 else 9;
        let data = borrow_global_mut<Data>(@woolf_deployer);

        let s0 = option::some(*table::borrow(table::borrow(&data.trait_data, 0 + shift), fur));
        let s1 = if (is_sheep) {
            option::some(*table::borrow(table::borrow(&data.trait_data, 1 + shift), head))
        } else {
            option::some(*table::borrow(table::borrow(&data.trait_data, 1 + shift), alpha_index))
        };
        let s2 = if (is_sheep) option::some(
            *table::borrow(table::borrow(&data.trait_data, 2 + shift), ears)
        ) else option::none<Trait>();
        let s3 = option::some(*table::borrow(table::borrow(&data.trait_data, 3 + shift), eyes));
        let s4 = if (is_sheep) option::some(
            *table::borrow(table::borrow(&data.trait_data, 4 + shift), nose)
        ) else option::none<Trait>();
        let s5 = option::some(*table::borrow(table::borrow(&data.trait_data, 5 + shift), mouth));
        let s6 = if (is_sheep) option::none<Trait>() else option::some(
            *table::borrow(table::borrow(&data.trait_data, 6 + shift), neck)
        );
        let s7 = if (is_sheep) option::some(
            *table::borrow(table::borrow(&data.trait_data, 7 + shift), feet)
        ) else option::none<Trait>();

        let svg_string: String = string::utf8(b"");
        // string::append_utf8(&mut svg_string, b"<svg id=\"woolf\" width=\"100%\" height=\"100%\" version=\"1.1\" viewBox=\"0 0 40 40\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">");
        string::append(&mut svg_string, draw_trait_or_none(s0));
        string::append(&mut svg_string, draw_trait_or_none(s1));
        string::append(&mut svg_string, draw_trait_or_none(s2));
        string::append(&mut svg_string, draw_trait_or_none(s3));
        string::append(&mut svg_string, draw_trait_or_none(s4));
        string::append(&mut svg_string, draw_trait_or_none(s5));
        string::append(&mut svg_string, draw_trait_or_none(s6));
        string::append(&mut svg_string, draw_trait_or_none(s7));
        // string::append_utf8(&mut svg_string, b"</svg>");
        svg_string
    }

    fun attribute_for_type_and_value(trait_type: String, value: String): String {
        let s = string::utf8(b"");
        // string::append_utf8(&mut s, b"{\"trait_type\":\"");
        string::append(&mut s, trait_type);
        // string::append_utf8(&mut s, b"\",\"value\":\"");
        string::append(&mut s, value);
        // string::append_utf8(&mut s, b"\"}");
        s
    }

    fun compile_attributes(token_id: TokenId): String acquires Data {
        // (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index)
        let (is_sheep, fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index) = get_token_traits(
            token_id
        );
        let s = vector[fur, head, ears, eyes, nose, mouth, neck, feet, alpha_index];
        let traits: String = string::utf8(b"");
        let data = borrow_global_mut<Data>(@woolf_deployer);
        if (is_sheep) {
            let types = vector[0, 1, 2, 3, 4, 5, 7];
            let i = 0;
            while (i < vector::length(&types)) {
                let index = *vector::borrow(&types, i);
                string::append(&mut traits, attribute_for_type_and_value(
                    *vector::borrow(&data.trait_types, index),
                    table::borrow(
                        table::borrow(&data.trait_data, (index as u8)),
                        *vector::borrow(&s, index)
                    ).name
                ));
                string::append_utf8(&mut traits, b",");
                i = i + 1;
            };
        } else {
            let types = vector[0, 1, 3, 5, 6];
            let sindice = vector[0, 8, 3, 5, 6];
            let i = 0;
            while (i < vector::length(&types)) {
                let index = *vector::borrow(&types, i);
                string::append(&mut traits, attribute_for_type_and_value(
                    *vector::borrow(&data.trait_types, index),
                    table::borrow(
                        table::borrow(&data.trait_data, (index as u8) + 9),
                        *vector::borrow(&s, *vector::borrow(&sindice, i))
                    ).name
                ));
                string::append_utf8(&mut traits, b",");
                i = i + 1;
            };
            string::append(&mut traits, attribute_for_type_and_value(
                string::utf8(b"Alpha Score"),
                string::utf8(*vector::borrow(&data.alphas, (*vector::borrow(&s, 8) as u64))) // alpha_index
            ));
            string::append_utf8(&mut traits, b",");
        };

        let attributes: String = string::utf8(b"");
        string::append_utf8(&mut attributes, b"[");
        string::append(&mut attributes, traits);
        // string::append_utf8(&mut attributes, b"{\"trait_type\":\"Generation\",\"value\":");
        // string::append_utf8(&mut attributes, if (is_sheep) b"\"Gen 0\"" else b"\"Gen 1\"");
        // string::append_utf8(&mut attributes, b"},{\"trait_type\":\"Type\",\"value\":");
        // string::append_utf8(&mut attributes, if (is_sheep) b"\"Sheep\"" else b"\"Wolf\"");
        // string::append_utf8(&mut attributes, b"}]");

        attributes
    }

    public fun token_uri(token_id: TokenId): String acquires Data {
        let (is_sheep, _, _, _, _, _, _, _, _, _, ) = get_token_traits(
            token_id
        );
        let metadata = string::utf8(b"");
        // string::append_utf8(&mut metadata, b"{\"name\": \"");
        string::append_utf8(&mut metadata, if (is_sheep) b"Sheep #" else b"Wolf #");
        // string::append_utf8(&mut metadata, b"tokenId");
        // string::append_utf8(&mut metadata, b"\", \"description\": \"Thousands of Sheep and Wolves compete on a farm in the metaverse. A tempting prize of $WOOL awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.\", \"image\": \"data:image/svg+xml;base64,");
        // string::append_utf8(&mut metadata, b"\", \"attributes\":");
        string::append_utf8(&mut metadata, base64::encode(string::bytes(&draw_svg(token_id))));
        // string::append(&mut metadata, compile_attributes(token_id));
        string::append_utf8(&mut metadata, b"}");

        string::insert(&mut metadata, 0, string::utf8(b"data:application/json;base64,"));
        metadata
    }

    #[test]
    fun test_upload_traits() acquires Data {
        let trait_type: u8 = 8;
        let trait_ids: vector<u8> = vector[2, 3];
        let traits: vector<Trait> = vector[
            Trait { name: string::utf8(b"1"), png: string::utf8(b"1") },
            Trait { name: string::utf8(b"2"), png: string::utf8(b"2") }
        ];
        upload_traits(trait_type, trait_ids, traits);
    }
}
