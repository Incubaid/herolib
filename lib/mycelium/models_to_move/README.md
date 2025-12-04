# ThreeFold Models

This module provides a comprehensive set of data models for various business and technical domains. All models are implemented in V and follow consistent patterns for ease of use and maintainability.

## Overview

The models are organized into logical domains:

| Domain | Description | Models |
|--------|-------------|---------|
| **Core** | Fundamental, reusable components | Comment |
| **Finance** | Financial accounts, assets, and marketplace | Account, Asset, Marketplace (Listing, Bid) |
| **Flow** | Multi-step workflows and digital signatures | Flow, FlowStep, SignatureRequirement |
| **Business** | Business entities and operations | Company, Product, Sale, Payment |
| **Identity** | Identity verification and KYC | KYC (iDenfy integration) |
| **Payment** | Payment processing integrations | Stripe webhooks |
| **Location** | Geographic and address information | Address |

## Design Patterns

All models follow consistent design patterns:

### 1. Heap Allocation
Root objects are marked with `@[heap]` for efficient memory management:
```v
@[heap]
pub struct Company {
    // fields...
}
```

### 2. Builder Pattern
All models support fluent builder pattern for easy construction:
```v
company := Company.new()
    .name('Acme Corp')
    .email('contact@acme.com')
    .status(.active)
```

### 3. Timestamps
Models include standard timestamp fields:
- `created_at u64` - Creation timestamp
- `updated_at u64` - Last modification timestamp

### 4. Status Enums
Models use enums for status tracking:
```v
pub enum CompanyStatus {
    pending_payment
    active
    suspended
    inactive
}
```

### 5. Optional Fields
Optional fields use V's option types:
```v
pub struct Address {
    state       ?string // Optional state/province
    company     ?string // Optional company name
}
```

## Usage Examples

### Core Models
```v
import threefold.models.core

// Create a comment
comment := core.Comment.new()
    .user_id(123)
    .content('This is a great post!')
    .parent_comment_id(456) // Reply to another comment
```

### Finance Models
```v
import threefold.models.finance

// Create an account
account := finance.Account.new()
    .name('Trading Account')
    .user_id(123)
    .ledger('Ethereum')
    .address('0x123...')

// Create an asset
asset := finance.Asset.new()
    .name('Hero Token')
    .amount(1000.0)
    .asset_type(.erc20)

// Create a marketplace listing
listing := finance.Listing.new()
    .title('1000 Hero Tokens for Sale')
    .asset_id('asset_123')
    .price(0.5)
    .currency('USD')
    .listing_type(.fixed_price)
```

### Business Models
```v
import threefold.models.business

// Create a company
company := business.Company.new()
    .name('Acme Corporation')
    .business_type(.single)
    .email('contact@acme.com')
    .status(.active)

// Create a product
product := business.Product.new()
    .name('Premium Service')
    .price(99.99)
    .type_(.service)
    .status(.available)

// Create a sale
sale := business.Sale.new()
    .company_id(company.id)
    .buyer_id(456)
    .total_amount(199.98)
    .status(.completed)
```

### Flow Models
```v
import threefold.models.flow

// Create a signing flow
flow := flow.Flow.new('flow-uuid-123')
    .name('Contract Approval Flow')
    .status('InProgress')

// Add steps to the flow
step1 := flow.FlowStep.new(1)
    .description('Initial review')
    .status('Completed')

step2 := flow.FlowStep.new(2)
    .description('Legal approval')
    .status('Pending')

flow = flow.add_step(step1).add_step(step2)
```

## Error Handling

Models include validation methods and use V's error handling:

```v
// Validate an address
address := location.Address.new()
    .street('123 Main St')
    .city('Anytown')
    .postal_code('12345')
    .country('USA')

address.validate() or {
    println('Address validation failed: ${err}')
    return
}
```

## Integration

These models are designed to work with:
- Database storage systems
- JSON serialization/deserialization
- API endpoints
- Business logic layers
- Validation frameworks

## Contributing

When adding new models:

1. Follow the established patterns (builder pattern, enums, etc.)
2. Include comprehensive documentation
3. Add validation methods where appropriate
4. Use consistent naming conventions
5. Include usage examples in documentation

## Module Structure

```
lib/threefold/models/
├── models.v              # Main module file
├── README.md            # This file
├── core/
│   └── comment.v        # Core models
├── finance/
│   ├── account.v        # Financial account model
│   ├── asset.v          # Digital asset model
│   └── marketplace.v    # Marketplace models
├── flow/
│   ├── flow.v           # Workflow model
│   ├── flow_step.v      # Workflow step model
│   └── signature_requirement.v # Signature requirement model
├── business/
│   ├── company.v        # Company model
│   ├── product.v        # Product model
│   ├── sale.v           # Sale model
│   └── payment.v        # Payment model
├── identity/
│   └── kyc.v            # KYC verification models
├── payment/
│   └── stripe.v         # Stripe webhook models
└── location/
    └── address.v        # Address model