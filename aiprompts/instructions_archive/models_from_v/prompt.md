$NAME = calendar

walk over all models from biz: db/heromodels/src/models/$NAME in the rust repo
create nice structured public models in Vlang (V) see instructions in herlolib

put the results in /Users/despiegk/code/github/freeflowuniverse/herolib/lib/hero/models/$NAME

put decorator on fields which need to be indexed: use @[index] for that at end of line of the property of the struct

copy the documentation as well and put on the vstruct and on its fields

make instructions so a coding agent can execute it, put the models in files, ...

keep it all simple

don't do anything additional for modules, don't do import

at top of each file we have ```module $NAME```


make sure all time related fields are in u64 format, use unix timestamp for that

don't create management classes, only output the structs, don't create a mod.v, don't make .v scripts executatble, don't create a main.v


## now also make sure we use core.base as follows

```
import freeflowuniverse.herolib.hero.models.core

// Account represents a financial account for tracking balances and transactions
// Supports multiple account types (checking, savings, investment, etc.)
pub struct Account {
    core.Base

```

remove Local BaseModel

make sure module ... is always at first line of file

- remove id from the model we update because it is in the Base
- created_at u64 // Creation timestamp
- updated_at u64 // Last modification timestamp
- basically each property in the Base should be removed from the model
