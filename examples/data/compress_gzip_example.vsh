#!/usr/bin/env -S v -cg -gc none -cc tcc -d use_openssl -enable-globals run

import compress.gzip

// Define some sample data to compress
data := 'Hello, VLang Gzip Compression Example! This is some sample text to be compressed and then decompressed.'

println('Original Data: "${data}"')
println('Original Data Length: ${data.len}')

// Compress the data using gzip
// Using a compression_level of 4095 for best compression
compressed_data := gzip.compress(data.bytes(), compression_level: 4095)!

println('Compressed Data Length: ${compressed_data.len}')

// Decompress the data
decompressed_data := gzip.decompress(compressed_data)!

println('Decompressed Data: "${decompressed_data.bytestr()}"')
println('Decompressed Data Length: ${decompressed_data.len}')

// Verify if the decompressed data matches the original data
if data.bytes() == decompressed_data {
	println('Compression and decompression successful! Data matches.')
} else {
	println('Error: Decompressed data does not match original data.')
}
