in lib/hero/models
for governance and legal

make sure we use core.base as follows

import freeflowuniverse.herolib.hero.models.core

// Account represents a financial account for tracking balances and transactions
// Supports multiple account types (checking, savings, investment, etc.)
pub struct Account {
    core.Base

remove Local BaseModel

make sure module ... is always at first line of file

- remove id from the model we update because it is in the Base
- created_at u64 // Creation timestamp
- updated_at u64 // Last modification timestamp
- basically each property in the Base should be removed from the model
