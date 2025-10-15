# HeroModels Implementation Guide

This guide provides comprehensive instructions for creating new models in the HeroModels system, including best practices for model structure, serialization/deserialization, testing, and integration with the HeroModels factory.

## Table of Contents
1. [Model Structure Overview](#model-structure-overview)
2. [Creating a New Model](#creating-a-new-model)
3. [Serialization and Deserialization](#serialization-and-deserialization)
4. [Database Operations](#database-operations)
5. [API Handler Implementation](#api-handler-implementation)
6. [Testing Models](#testing-models)
7. [Integration with Factory](#integration-with-factory)
8. [Advanced Features](#advanced-features)
9. [Best Practices](#best-practices)
10. [Example Implementation](#example-implementation)

## Model Structure Overview

Each model in the HeroModels system consists of several components:

1. **Model Struct**: The core data structure inheriting from `db.Base`
2. **DB Wrapper Struct**: Provides database operations for the model
3. **Argument Struct**: Used for creating and updating model instances
4. **API Handler Function**: Handles RPC calls for the model
5. **List Arguments Struct**: Used for filtering when listing instances

### Directory Structure

```
lib/hero/heromodels/
  ├── model_name.v         # Main model file
  ├── model_name_test.v    # Tests for the model
  └── factory.v            # Factory integration
```

## Creating a New Model

### 1. Define the Model Struct

Create a new file `model_name.v` in the `lib/hero/heromodels` directory.

```v
module heromodels

import incubaid.herolib.core.db
import incubaid.herolib.core.encoder
import incubaid.herolib.core.ourtime
import incubaid.herolib.core.jsonrpc { Response }
import json

// Model struct - inherits from db.Base
pub struct ModelName {
pub mut:
    db.Base       // Inherit from db.Base
    name         string
    description  string
    created_at   u64
    updated_at   u64
    // Add additional fields as needed
}

// TypeName returns the type name used for serialization
pub fn (self ModelName) type_name() string {
    return 'heromodels.ModelName'
}
```

### 2. Define the Argument Struct for Model Creation/Updates

```v
// Argument struct for creating/updating models with params attribute
@[params]
pub struct ModelNameArg {
pub mut:
    id           u32     // Optional for updates, ignored for creation
    name         string  @[required] // Required field
    description  string
    // Add additional fields as needed
}
```

### 3. Define the List Arguments Struct for Filtering

```v
// Arguments for filtering when listing models
@[params]
pub struct ModelNameListArg {
pub mut:
    // Add filter fields (e.g., status, type, etc.)
    limit        int = 100 // Default limit
}
```

### 4. Create the DB Wrapper Struct

```v
// DB Wrapper struct for database operations
pub struct DBModelName {
pub mut:
    db &db.DB
}
```

## Serialization and Deserialization

Implement the `dump` and `load` methods for serialization/deserialization.

### Dump Method (Serialization)

```v
// Dump serializes the model to the encoder
pub fn (self ModelName) dump(mut e encoder.Encoder) ! {
    // Always dump the Base first
    self.Base.dump(mut e)!
    
    // Dump model-specific fields in the same order they will be loaded
    e.add_string(self.name)!
    e.add_string(self.description)!
    e.add_u64(self.created_at)!
    e.add_u64(self.updated_at)!
    // Add more fields in the exact order they should be loaded
}
```

### Load Method (Deserialization)

```v
// Load deserializes the model from the decoder
pub fn (mut self DBModelName) load(mut obj ModelName, mut d encoder.Decoder) ! {
    // Always load the Base first
    obj.Base.load(mut d)!
    
    // Load model-specific fields in the same order they were dumped
    obj.name = d.get_string()!
    obj.description = d.get_string()!
    obj.created_at = d.get_u64()!
    obj.updated_at = d.get_u64()!
    // Add more fields in the exact order they were dumped
}
```

## Database Operations

Implement the standard CRUD operations and additional methods.

### New Instance Creation

```v
// Create a new model instance from arguments
pub fn (mut self DBModelName) new(args ModelNameArg) !ModelName {
    mut o := ModelName{
        name: args.name
        description: args.description
        // Initialize other fields
        created_at: ourtime.now().unix()
        updated_at: ourtime.now().unix()
    }
    
    // Additional initialization logic
    
    return o
}
```

### Set (Create or Update)

```v
// Save or update a model instance
pub fn (mut self DBModelName) set(o ModelName) !ModelName {
    return self.db.set[ModelName](o)!
}
```

### Get

```v
// Retrieve a model instance by ID
pub fn (mut self DBModelName) get(id u32) !ModelName {
    mut o, data := self.db.get_data[ModelName](id)!
    mut e_decoder := encoder.decoder_new(data)
    self.load(mut o, mut e_decoder)!
    return o
}
```

### Delete

```v
// Delete a model instance by ID
pub fn (mut self DBModelName) delete(id u32) !bool {
    // Check if the item exists before trying to delete
    if !self.db.exists[ModelName](id)! {
        return false
    }
    self.db.delete[ModelName](id)!
    return true
}
```

### Exist

```v
// Check if a model instance exists by ID
pub fn (mut self DBModelName) exist(id u32) !bool {
    return self.db.exists[ModelName](id)!
}
```

### List with Filtering

```v
// List model instances with optional filtering
pub fn (mut self DBModelName) list(args ModelNameListArg) ![]ModelName {
    // Get all instances
    all_items := self.db.list[ModelName]()!.map(self.get(it)!)
    
    // Apply filters
    mut filtered_items := []ModelName{}
    for item in all_items {
        // Apply your filter conditions here
        // Example:
        // if args.some_filter && item.some_property != args.filter_value {
        //     continue
        // }
        
        filtered_items << item
    }
    
    // Apply limit
    mut limit := args.limit
    if limit > 100 {
        limit = 100
    }
    if filtered_items.len > limit {
        return filtered_items[..limit]
    }
    
    return filtered_items
}
```

## API Handler Implementation

Create the handler function for RPC requests.

```v
// Handler for RPC calls to this model
pub fn model_name_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
    match method {
        'get' {
            id := db.decode_u32(params)!
            res := f.model_name.get(id)!
            return new_response(rpcid, json.encode_pretty(res))
        }
        'set' {
            mut args := db.decode_generic[ModelNameArg](params)!
            mut o := f.model_name.new(args)!
            if args.id != 0 {
                o.id = args.id
            }
            o = f.model_name.set(o)!
            return new_response_int(rpcid, int(o.id))
        }
        'delete' {
            id := db.decode_u32(params)!
            deleted := f.model_name.delete(id)!
            if deleted {
                return new_response_true(rpcid)
            } else {
                return new_error(rpcid,
                    code:    404
                    message: 'ModelName with ID ${id} not found'
                )
            }
        }
        'exist' {
            id := db.decode_u32(params)!
            if f.model_name.exist(id)! {
                return new_response_true(rpcid)
            } else {
                return new_response_false(rpcid)
            }
        }
        'list' {
            args := db.decode_generic[ModelNameListArg](params)!
            res := f.model_name.list(args)!
            return new_response(rpcid, json.encode_pretty(res))
        }
        else {
            return new_error(rpcid,
                code:    32601
                message: 'Method ${method} not found on model_name'
            )
        }
    }
}
```

## Testing Models

Create a `model_name_test.v` file to test your model.

```v
module heromodels

fn test_model_name_crud() ! {
    // Initialize DB for testing
    mut mydb := db.new_test()!
    mut db_model := DBModelName{
        db: &mydb
    }
    
    // Create
    mut args := ModelNameArg{
        name: 'Test Model'
        description: 'A test model'
    }
    
    mut model := db_model.new(args)!
    model = db_model.set(model)!
    model_id := model.id
    
    // Verify ID assignment
    assert model_id > 0
    
    // Read
    retrieved_model := db_model.get(model_id)!
    assert retrieved_model.name == 'Test Model'
    assert retrieved_model.description == 'A test model'
    
    // Update
    retrieved_model.description = 'Updated description'
    updated_model := db_model.set(retrieved_model)!
    assert updated_model.description == 'Updated description'
    
    // Delete
    deleted := db_model.delete(model_id)!
    assert deleted == true
    
    // Verify deletion
    exists := db_model.exist(model_id)!
    assert exists == false
}

fn test_model_name_type_name() ! {
    // Initialize DB for testing
    mut mydb := db.new_test()!
    mut db_model := DBModelName{
        db: &mydb
    }
    
    // Create a model
    mut model := db_model.new(
        name: 'Type Test'
        description: 'Testing type_name'
    )!
    
    // Test type_name method
    assert model.type_name() == 'heromodels.ModelName'
}

fn test_model_name_description() ! {
    // Initialize DB for testing
    mut mydb := db.new_test()!
    mut db_model := DBModelName{
        db: &mydb
    }
    
    // Create a model
    mut model := db_model.new(
        name: 'Description Test'
        description: 'Testing description method'
    )!
    
    // Test description method for each methodname
    assert model.description('set') == 'Create or update a model. Returns the ID of the model.'
    assert model.description('get') == 'Retrieve a model by ID. Returns the model object.'
    assert model.description('delete') == 'Delete a model by ID. Returns true if successful.'
    assert model.description('exist') == 'Check if a model exists by ID. Returns true or false.'
    assert model.description('list') == 'List all models. Returns an array of model objects.'
}

fn test_model_name_example() ! {
    // Initialize DB for testing
    mut mydb := db.new_test()!
    mut db_model := DBModelName{
        db: &mydb
    }
    
    // Create a model
    mut model := db_model.new(
        name: 'Example Test'
        description: 'Testing example method'
    )!
    
    // Test example method for each methodname
    set_call, set_result := model.example('set')
    // Assert expected call and result format
    
    get_call, get_result := model.example('get')
    // Assert expected call and result format
    
    delete_call, delete_result := model.example('delete')
    // Assert expected call and result format
    
    exist_call, exist_result := model.example('exist')
    // Assert expected call and result format
    
    list_call, list_result := model.example('list')
    // Assert expected call and result format
}

fn test_model_name_encoding_decoding() ! {
    // Initialize DB for testing
    mut mydb := db.new_test()!
    mut db_model := DBModelName{
        db: &mydb
    }
    
    // Create a model with all fields populated
    mut args := ModelNameArg{
        name: 'Encoding Test'
        description: 'Testing encoding/decoding'
        // Set other fields
    }
    
    mut model := db_model.new(args)!
    
    // Save the model
    model = db_model.set(model)!
    model_id := model.id
    
    // Retrieve and verify all fields were properly encoded/decoded
    retrieved_model := db_model.get(model_id)!
    
    // Verify all fields match the original
    assert retrieved_model.name == 'Encoding Test'
    assert retrieved_model.description == 'Testing encoding/decoding'
    // Check other fields
}
```

## Integration with Factory

Update the `factory.v` file to include your new model.

### 1. Add the Model to the Factory Struct

```v
// In factory.v
pub struct ModelsFactory {
pub mut:
    db                &db.DB
    user              DBUser
    group             DBGroup
    // Add your new model
    model_name        DBModelName
    // Other models...
    rpc_handler       &jsonrpc.Handler
}
```

### 2. Initialize the Model in the Factory New Method

```v
// In factory.v, in the new() function
pub fn new(args ModelsFactoryArgs) !&ModelsFactory {
    // Existing code...
    
    mut f := ModelsFactory{
        db: &mydb
        user: DBUser{
            db: &mydb
        }
        // Add your new model
        model_name: DBModelName{
            db: &mydb
        }
        // Other models...
        rpc_handler: &h
    }
    
    // Existing code...
}
```

### 3. Add Handler Registration to the Factory API Handler

```v
// In factory.v, in the group_api_handler function
pub fn group_api_handler(rpcid int, servercontext map[string]string, actorname string, methodname string, params string) !jsonrpc.Response {
    // Existing code...
    
    match actorname {
        // Existing cases...
        
        'model_name' {
            return model_name_handle(mut f, rpcid, servercontext, userref, methodname, params)!
        }
        
        // Existing cases...
        
        else {
            // Error handling
        }
    }
}
```

## Advanced Features

### Custom Methods

You can add custom methods to your model for specific business logic:

```v
// Add a custom method to the model
pub fn (mut self ModelName) custom_operation(param string) !string {
    // Custom business logic
    self.updated_at = ourtime.now().unix()
    return 'Performed ${param} operation'
}
```

### Enhanced RPC Handling

Extend the RPC handler to support your custom methods:

```v
// In the model_name_handle function
match method {
    // Standard CRUD methods...
    
    'custom_operation' {
        id := db.decode_u32(params)!
        mut model := f.model_name.get(id)!
        
        // Extract parameter from JSON
        param_struct := json.decode(struct { param string }, params) or {
            return new_error(rpcid,
                code:    32602
                message: 'Invalid parameters for custom_operation'
            )
        }
        
        result := model.custom_operation(param_struct.param)!
        model = f.model_name.set(model)! // Save changes
        return new_response(rpcid, json.encode(result))
    }
    
    else {
        // Error handling
    }
}
```

## Best Practices

1. **Field Order**: Keep field ordering consistent between `dump` and `load` methods
2. **Error Handling**: Use the `!` operator consistently for error propagation
3. **Timestamp Management**: Initialize timestamps using `ourtime.now().unix()`
4. **Required Fields**: Mark mandatory fields with `@[required]` attribute
5. **Limits**: Enforce list limits (default 100)
6. **ID Handling**: Always check existence before operations like delete
7. **Validation**: Add validation in the `new` and `set` methods
8. **API Methods**: Implement the standard CRUD operations (get, set, delete, exist, list)
9. **Comments**: Document all fields and methods
10. **Testing**: Create comprehensive tests covering all methods

## Example Implementation

Here is a complete example of a simple "Project" model:

```v
module heromodels

import incubaid.herolib.core.db
import incubaid.herolib.core.encoder
import incubaid.herolib.core.ourtime
import incubaid.herolib.core.jsonrpc { Response }
import json

// Project model
pub struct Project {
pub mut:
    db.Base       // Inherit from db.Base
    name         string
    description  string
    status       ProjectStatus
    owner_id     u32
    members      []u32
    created_at   u64
    updated_at   u64
}

// Project status enum
pub enum ProjectStatus {
    active
    completed
    archived
}

// TypeName for serialization
pub fn (self Project) type_name() string {
    return 'heromodels.Project'
}

// Dump serializes the model
pub fn (self Project) dump(mut e encoder.Encoder) ! {
    self.Base.dump(mut e)!
    e.add_string(self.name)!
    e.add_string(self.description)!
    e.add_u8(u8(self.status))!
    e.add_u32(self.owner_id)!
    e.add_array_u32(self.members)!
    e.add_u64(self.created_at)!
    e.add_u64(self.updated_at)!
}

// Project argument struct
@[params]
pub struct ProjectArg {
pub mut:
    id           u32
    name         string  @[required]
    description  string
    status       ProjectStatus = .active
    owner_id     u32     @[required]
    members      []u32
}

// Project list argument struct
@[params]
pub struct ProjectListArg {
pub mut:
    status      ProjectStatus
    owner_id    u32
    limit       int = 100
}

// DB wrapper struct
pub struct DBProject {
pub mut:
    db &db.DB
}

// Load deserializes the model
pub fn (mut self DBProject) load(mut obj Project, mut d encoder.Decoder) ! {
    obj.Base.load(mut d)!
    obj.name = d.get_string()!
    obj.description = d.get_string()!
    obj.status = unsafe { ProjectStatus(d.get_u8()!) }
    obj.owner_id = d.get_u32()!
    obj.members = d.get_array_u32()!
    obj.created_at = d.get_u64()!
    obj.updated_at = d.get_u64()!
}

// Create a new Project
pub fn (mut self DBProject) new(args ProjectArg) !Project {
    mut o := Project{
        name: args.name
        description: args.description
        status: args.status
        owner_id: args.owner_id
        members: args.members
        created_at: ourtime.now().unix()
        updated_at: ourtime.now().unix()
    }
    
    return o
}

// Save or update a Project
pub fn (mut self DBProject) set(o Project) !Project {
    return self.db.set[Project](o)!
}

// Get a Project by ID
pub fn (mut self DBProject) get(id u32) !Project {
    mut o, data := self.db.get_data[Project](id)!
    mut e_decoder := encoder.decoder_new(data)
    self.load(mut o, mut e_decoder)!
    return o
}

// Delete a Project by ID
pub fn (mut self DBProject) delete(id u32) !bool {
    if !self.db.exists[Project](id)! {
        return false
    }
    self.db.delete[Project](id)!
    return true
}

// Check if a Project exists
pub fn (mut self DBProject) exist(id u32) !bool {
    return self.db.exists[Project](id)!
}

// List Projects with filtering
pub fn (mut self DBProject) list(args ProjectListArg) ![]Project {
    all_projects := self.db.list[Project]()!.map(self.get(it)!)
    
    mut filtered_projects := []Project{}
    for project in all_projects {
        // Filter by status if provided
        if args.status != .active && project.status != args.status {
            continue
        }
        
        // Filter by owner_id if provided
        if args.owner_id != 0 && project.owner_id != args.owner_id {
            continue
        }
        
        filtered_projects << project
    }
    
    mut limit := args.limit
    if limit > 100 {
        limit = 100
    }
    if filtered_projects.len > limit {
        return filtered_projects[..limit]
    }
    
    return filtered_projects
}

// API description method
pub fn (self Project) description(methodname string) string {
    match methodname {
        'set' { return 'Create or update a project. Returns the ID of the project.' }
        'get' { return 'Retrieve a project by ID. Returns the project object.' }
        'delete' { return 'Delete a project by ID. Returns true if successful.' }
        'exist' { return 'Check if a project exists by ID. Returns true or false.' }
        'list' { return 'List all projects. Returns an array of project objects.' }
        else { return 'This is generic method for the root object, TODO fill in, ...' }
    }
}

// API example method
pub fn (self Project) example(methodname string) (string, string) {
    match methodname {
        'set' {
            return '{"project": {"name": "Website Redesign", "description": "Redesign company website", "status": "active", "owner_id": 1, "members": [2, 3]}}', '1'
        }
        'get' {
            return '{"id": 1}', '{"name": "Website Redesign", "description": "Redesign company website", "status": "active", "owner_id": 1, "members": [2, 3]}'
        }
        'delete' {
            return '{"id": 1}', 'true'
        }
        'exist' {
            return '{"id": 1}', 'true'
        }
        'list' {
            return '{}', '[{"name": "Website Redesign", "description": "Redesign company website", "status": "active", "owner_id": 1, "members": [2, 3]}]'
        }
        else {
            return '{}', '{}'
        }
    }
}

// API handler function
pub fn project_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
    match method {
        'get' {
            id := db.decode_u32(params)!
            res := f.project.get(id)!
            return new_response(rpcid, json.encode_pretty(res))
        }
        'set' {
            mut args := db.decode_generic[ProjectArg](params)!
            mut o := f.project.new(args)!
            if args.id != 0 {
                o.id = args.id
            }
            o = f.project.set(o)!
            return new_response_int(rpcid, int(o.id))
        }
        'delete' {
            id := db.decode_u32(params)!
            deleted := f.project.delete(id)!
            if deleted {
                return new_response_true(rpcid)
            } else {
                return new_error(rpcid,
                    code:    404
                    message: 'Project with ID ${id} not found'
                )
            }
        }
        'exist' {
            id := db.decode_u32(params)!
            if f.project.exist(id)! {
                return new_response_true(rpcid)
            } else {
                return new_response_false(rpcid)
            }
        }
        'list' {
            args := db.decode_generic[ProjectListArg](params)!
            res := f.project.list(args)!
            return new_response(rpcid, json.encode_pretty(res))
        }
        else {
            return new_error(rpcid,
                code:    32601
                message: 'Method ${method} not found on project'
            )
        }
    }
}
```

This complete guide should provide all the necessary information to create and maintain models in the HeroModels system following the established patterns and best practices.
