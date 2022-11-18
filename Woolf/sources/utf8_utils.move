module woolf_deployer::utf8_utils {

    use std::string::{Self, String};
    use std::vector;

    /// @dev Converts a `u64` to its `ascii::String` decimal representation.
    public fun to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }
}
