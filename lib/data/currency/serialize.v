module currency

// see encoder for binary

// import incubaid.herolib.data.encoder

// // CurrencyBytes represents serialized Currency data
// pub struct CurrencyBytes {
// pub:
// 	data []u8
// }

// // to_bytes converts a Currency to serialized bytes
// pub fn (c Currency) to_bytes() !CurrencyBytes {
// 	mut enc := encoder.new()

// 	// Add unique encoding ID to identify this type of data
// 	enc.add_u16(500) // Unique ID for Currency type

// 	// Encode Currency fields
// 	enc.add_string(c.name)
// 	enc.add_f64(c.usdval)

// 	return CurrencyBytes{
// 		data: enc.data
// 	}
// }

// // from_bytes deserializes bytes to a Currency
// pub fn from_bytes(bytes CurrencyBytes) !Currency {
// 	mut d := encoder.decoder_new(bytes.data)
// 	mut currency := Currency{}

// 	// Check encoding ID to verify this is the correct type of data
// 	encoding_id := d.get_u16()!
// 	if encoding_id != 500 {
// 		return error('Wrong file type: expected encoding ID 500, got ${encoding_id}, for currency')
// 	}

// 	// Decode Currency fields
// 	currency.name = d.get_string()!
// 	currency.usdval = d.get_f64()!

// 	return currency
// }
