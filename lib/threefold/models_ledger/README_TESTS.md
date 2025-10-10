# Models Ledger Tests

This directory contains comprehensive tests for all models in the `models_ledger` module. The tests focus primarily on encoding/decoding functionality to ensure data integrity through the database layer.

## Test Structure

Each model has its own test file following the naming convention `{model}_test.v`:

- `account_test.v` - Tests for Account model with complex nested structures
- `asset_test.v` - Tests for Asset model with metadata maps
- `user_test.v` - Tests for User model with SecretBox arrays
- `transaction_test.v` - Tests for Transaction model with signature arrays
- `dnszone_test.v` - Tests for DNSZone model with DNS records and SOA records
- `group_test.v` - Tests for Group model with configuration structs
- `member_test.v` - Tests for Member model with enums
- `notary_test.v` - Tests for Notary model
- `signature_test.v` - Tests for Signature model
- `userkvs_test.v` - Tests for UserKVS model
- `userkvsitem_test.v` - Tests for UserKVSItem model
- `models_test.v` - Integration tests for all models together

## Test Categories

### 1. Model Creation (`test_{model}_new`)
Tests the creation of new model instances with all field types:
- Required fields
- Optional fields
- Default values
- Complex nested structures
- Arrays and maps

### 2. Encoding/Decoding (`test_{model}_encoding_decoding`)
**Primary focus** - Tests the serialization and deserialization:
- Encoding to binary format using `dump(mut encoder.Encoder)`
- Decoding from binary format using `load(mut decoder.Decoder)`
- Field-by-field verification after roundtrip
- Complex data structures (nested structs, arrays, maps)
- Edge cases (empty data, large data)

### 3. Database Operations (`test_{model}_set_and_get`)
Tests CRUD operations through the database layer:
- Create and save (`set`)
- Retrieve (`get`)
- ID assignment
- Data persistence through database roundtrip

### 4. Update Operations (`test_{model}_update`)
Tests updating existing records:
- Modify fields
- Save changes
- Verify updates persist
- ID and created_at preservation

### 5. Existence and Deletion (`test_{model}_exist_and_delete`)
Tests existence checking and deletion:
- Check non-existent records
- Create and verify existence
- Delete records
- Verify deletion

### 6. List Operations (`test_{model}_list`)
Tests listing all records:
- Initial empty state
- Create multiple records
- List and count verification
- Find specific records in lists

### 7. Edge Cases (`test_{model}_edge_cases`)
Tests boundary conditions:
- Empty/minimal data
- Very large data
- Special characters
- Unicode handling
- Maximum array sizes

## Key Features Tested

### Encoding/Decoding Integrity
- **Primitive types**: strings, integers, floats, booleans
- **Arrays**: `[]u32`, `[]string`, `[]SecretBox`, etc.
- **Maps**: `map[string]string` for metadata
- **Enums**: All enum types with proper conversion
- **Nested structs**: Complex hierarchical data
- **Binary data**: Encrypted data in SecretBox

### Complex Data Structures
- **Account**: Nested AccountPolicy and AccountAsset arrays
- **DNSZone**: DNS records with different types and SOA records
- **User**: Encrypted data arrays (userprofile, kyc)
- **Transaction**: Signature arrays with timestamps
- **Group**: Configuration structs with multiple fields

### Performance Considerations
- Large array handling (1000+ elements)
- Large binary data (10KB+ encrypted data)
- Complex nested structures
- Memory efficiency during encoding/decoding

## Running Tests

Run all model tests:
```bash
vtest ~/code/github/incubaid/herolib/lib/threefold/models_ledger/
```

Run specific model tests:
```bash
vtest ~/code/github/incubaid/herolib/lib/threefold/models_ledger/account_test.v
vtest ~/code/github/incubaid/herolib/lib/threefold/models_ledger/user_test.v
```

Run integration tests:
```bash
vtest ~/code/github/incubaid/herolib/lib/threefold/models_ledger/models_test.v
```

## Common Test Patterns

### Setup
Each test file uses a common setup function:
```v
fn setup_test_db() !db.DB {
    return db.new(path: ':memory:')!
}
```

### Encoding/Decoding Pattern
```v
// Test encoding
mut encoder_obj := encoder.encoder_new()
original_object.dump(mut encoder_obj)!
encoded_data := encoder_obj.data

// Test decoding
mut decoder_obj := encoder.decoder_new(encoded_data)
mut decoded_object := ObjectType{}
object_db.load(mut decoded_object, mut decoder_obj)!

// Verify all fields match
assert decoded_object.field == original_object.field
```

### CRUD Pattern
```v
// Create
mut object := object_db.new(args)!

// Save
object = object_db.set(object)!
assert object.id > 0

// Get
retrieved := object_db.get(object.id)!
assert retrieved.field == object.field

// Update
object.field = new_value
object = object_db.set(object)!

// Delete
object_db.delete(object.id)!
assert object_db.exist(object.id)! == false
```

## Error Conditions

Tests verify proper error handling for:
- Non-existent record retrieval
- Invalid data encoding/decoding
- Database constraint violations
- Memory allocation failures

## Performance Metrics

Integration tests include performance verification:
- Large data encoding/decoding speed
- Memory usage with complex structures
- Database roundtrip efficiency
- Array and map handling performance

The tests ensure that all models can handle real-world usage scenarios with proper data integrity and performance characteristics.