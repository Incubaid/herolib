# module orm


## Contents
- [Constants](#Constants)
- [new_query](#new_query)
- [orm_select_gen](#orm_select_gen)
- [orm_stmt_gen](#orm_stmt_gen)
- [orm_table_gen](#orm_table_gen)
- [Connection](#Connection)
- [Primitive](#Primitive)
- [QueryBuilder[T]](#QueryBuilder[T])
  - [reset](#reset)
  - [where](#where)
  - [or_where](#or_where)
  - [order](#order)
  - [limit](#limit)
  - [offset](#offset)
  - [select](#select)
  - [set](#set)
  - [query](#query)
  - [count](#count)
  - [insert](#insert)
  - [insert_many](#insert_many)
  - [update](#update)
  - [delete](#delete)
  - [create](#create)
  - [drop](#drop)
  - [last_id](#last_id)
- [MathOperationKind](#MathOperationKind)
- [OperationKind](#OperationKind)
- [OrderType](#OrderType)
- [SQLDialect](#SQLDialect)
- [StmtKind](#StmtKind)
- [InfixType](#InfixType)
- [Null](#Null)
- [QueryBuilder](#QueryBuilder)
- [QueryData](#QueryData)
- [SelectConfig](#SelectConfig)
- [Table](#Table)
- [TableField](#TableField)

## Constants
```v
const num64 = [typeof[i64]().idx, typeof[u64]().idx]
```

[[Return to contents]](#Contents)

```v
const nums = [
	typeof[i8]().idx,
	typeof[i16]().idx,
	typeof[int]().idx,
	typeof[u8]().idx,
	typeof[u16]().idx,
	typeof[u32]().idx,
	typeof[bool]().idx,
]
```

[[Return to contents]](#Contents)

```v
const float = [
	typeof[f32]().idx,
	typeof[f64]().idx,
]
```

[[Return to contents]](#Contents)

```v
const type_string = typeof[string]().idx
```

[[Return to contents]](#Contents)

```v
const serial = -1
```

[[Return to contents]](#Contents)

```v
const time_ = -2
```

[[Return to contents]](#Contents)

```v
const enum_ = -3
```

[[Return to contents]](#Contents)

```v
const type_idx = {
	'i8':     typeof[i8]().idx
	'i16':    typeof[i16]().idx
	'int':    typeof[int]().idx
	'i64':    typeof[i64]().idx
	'u8':     typeof[u8]().idx
	'u16':    typeof[u16]().idx
	'u32':    typeof[u32]().idx
	'u64':    typeof[u64]().idx
	'f32':    typeof[f32]().idx
	'f64':    typeof[f64]().idx
	'bool':   typeof[bool]().idx
	'string': typeof[string]().idx
}
```

[[Return to contents]](#Contents)

```v
const string_max_len = 2048
```

[[Return to contents]](#Contents)

```v
const null_primitive = Primitive(Null{})
```

[[Return to contents]](#Contents)

## new_query
```v
fn new_query[T](conn Connection) &QueryBuilder[T]
```

new_query create a new query object for struct `T`

[[Return to contents]](#Contents)

## orm_select_gen
```v
fn orm_select_gen(cfg SelectConfig, q string, num bool, qm string, start_pos int, where QueryData) string
```

Generates an sql select stmt, from universal parameter orm - See SelectConfig q, num, qm, start_pos - see orm_stmt_gen where - See QueryData

[[Return to contents]](#Contents)

## orm_stmt_gen
```v
fn orm_stmt_gen(sql_dialect SQLDialect, table Table, q string, kind StmtKind, num bool, qm string,
	start_pos int, data QueryData, where QueryData) (string, QueryData)
```

Generates an sql stmt, from universal parameter q - The quotes character, which can be different in every type, so it's variable num - Stmt uses nums at prepared statements (? or ?1) qm - Character for prepared statement (qm for question mark, as in sqlite) start_pos - When num is true, it's the start position of the counter

[[Return to contents]](#Contents)

## orm_table_gen
```v
fn orm_table_gen(sql_dialect SQLDialect, table Table, q string, defaults bool, def_unique_len int, fields []TableField, sql_from_v fn (int) !string,
	alternative bool) !string
```

Generates an sql table stmt, from universal parameter table - Table struct q - see orm_stmt_gen defaults - enables default values in stmt def_unique_len - sets default unique length for texts fields - See TableField sql_from_v - Function which maps type indices to sql type names alternative - Needed for msdb

[[Return to contents]](#Contents)

## Connection
```v
interface Connection {
mut:
	select(config SelectConfig, data QueryData, where QueryData) ![][]Primitive
	insert(table Table, data QueryData) !
	update(table Table, data QueryData, where QueryData) !
	delete(table Table, where QueryData) !
	create(table Table, fields []TableField) !
	drop(table Table) !
	last_id() int
}
```

Interfaces gets called from the backend and can be implemented Since the orm supports arrays aswell, they have to be returned too. A row is represented as []Primitive, where the data is connected to the fields of the struct by their index. The indices are mapped with the SelectConfig.field array. This is the mapping for a struct. To have an array, there has to be an array of structs, basically [][]Primitive

Every function without last_id() returns an optional, which returns an error if present last_id returns the last inserted id of the db

[[Return to contents]](#Contents)

## Primitive
```v
type Primitive = InfixType
	| Null
	| bool
	| f32
	| f64
	| i16
	| i64
	| i8
	| int
	| string
	| time.Time
	| u16
	| u32
	| u64
	| u8
	| []Primitive
```

[[Return to contents]](#Contents)

## QueryBuilder[T]
## reset
```v
fn (qb_ &QueryBuilder[T]) reset() &QueryBuilder[T]
```

reset reset a query object, but keep the connection and table name

[[Return to contents]](#Contents)

## where
```v
fn (qb_ &QueryBuilder[T]) where(condition string, params ...Primitive) !&QueryBuilder[T]
```

where create a `where` clause, it will `AND` with previous `where` clause. valid token in the `condition` include: `field's names`, `operator`, `(`, `)`, `?`, `AND`, `OR`, `||`, `&&`, valid `operator` incldue: `=`, `!=`, `<>`, `>=`, `<=`, `>`, `<`, `LIKE`, `ILIKE`, `IS NULL`, `IS NOT NULL`, `IN`, `NOT IN` example: `where('(a > ? AND b <= ?) OR (c <> ? AND (x = ? OR y = ?))', a, b, c, x, y)`

[[Return to contents]](#Contents)

## or_where
```v
fn (qb_ &QueryBuilder[T]) or_where(condition string, params ...Primitive) !&QueryBuilder[T]
```

or_where create a `where` clause, it will `OR` with previous `where` clause.

[[Return to contents]](#Contents)

## order
```v
fn (qb_ &QueryBuilder[T]) order(order_type OrderType, field string) !&QueryBuilder[T]
```

order create a `order` clause

[[Return to contents]](#Contents)

## limit
```v
fn (qb_ &QueryBuilder[T]) limit(limit int) !&QueryBuilder[T]
```

limit create a `limit` clause

[[Return to contents]](#Contents)

## offset
```v
fn (qb_ &QueryBuilder[T]) offset(offset int) !&QueryBuilder[T]
```

offset create a `offset` clause

[[Return to contents]](#Contents)

## select
```v
fn (qb_ &QueryBuilder[T]) select(fields ...string) !&QueryBuilder[T]
```

select create a `select` clause

[[Return to contents]](#Contents)

## set
```v
fn (qb_ &QueryBuilder[T]) set(assign string, values ...Primitive) !&QueryBuilder[T]
```

set create a `set` clause for `update`

[[Return to contents]](#Contents)

## query
```v
fn (qb_ &QueryBuilder[T]) query() ![]T
```

query start a query and return result in struct `T`

[[Return to contents]](#Contents)

## count
```v
fn (qb_ &QueryBuilder[T]) count() !int
```

count start a count query and return result

[[Return to contents]](#Contents)

## insert
```v
fn (qb_ &QueryBuilder[T]) insert[T](value T) !&QueryBuilder[T]
```

insert insert a record into the database

[[Return to contents]](#Contents)

## insert_many
```v
fn (qb_ &QueryBuilder[T]) insert_many[T](values []T) !&QueryBuilder[T]
```

insert_many insert records into the database

[[Return to contents]](#Contents)

## update
```v
fn (qb_ &QueryBuilder[T]) update() !&QueryBuilder[T]
```

update update record(s) in the database

[[Return to contents]](#Contents)

## delete
```v
fn (qb_ &QueryBuilder[T]) delete() !&QueryBuilder[T]
```

delete delete record(s) in the database

[[Return to contents]](#Contents)

## create
```v
fn (qb_ &QueryBuilder[T]) create() !&QueryBuilder[T]
```

create create a table

[[Return to contents]](#Contents)

## drop
```v
fn (qb_ &QueryBuilder[T]) drop() !&QueryBuilder[T]
```

drop drop a table

[[Return to contents]](#Contents)

## last_id
```v
fn (qb_ &QueryBuilder[T]) last_id() int
```

last_id returns the last inserted id of the db

[[Return to contents]](#Contents)

## MathOperationKind
```v
enum MathOperationKind {
	add // +
	sub // -
	mul // *
	div // /
}
```

[[Return to contents]](#Contents)

## OperationKind
```v
enum OperationKind {
	neq         // !=
	eq          // ==
	gt          // >
	lt          // <
	ge          // >=
	le          // <=
	orm_like    // LIKE
	orm_ilike   // ILIKE
	is_null     // IS NULL
	is_not_null // IS NOT NULL
	in          // IN
	not_in      // NOT IN
}
```

[[Return to contents]](#Contents)

## OrderType
```v
enum OrderType {
	asc
	desc
}
```

[[Return to contents]](#Contents)

## SQLDialect
```v
enum SQLDialect {
	default
	mysql
	pg
	sqlite
}
```

[[Return to contents]](#Contents)

## StmtKind
```v
enum StmtKind {
	insert
	update
	delete
}
```

[[Return to contents]](#Contents)

## InfixType
```v
struct InfixType {
pub:
	name     string
	operator MathOperationKind
	right    Primitive
}
```

[[Return to contents]](#Contents)

## Null
```v
struct Null {}
```

[[Return to contents]](#Contents)

## QueryBuilder
```v
struct QueryBuilder[T] {
pub mut:
	meta                  []TableField
	valid_sql_field_names []string
	conn                  Connection
	config                SelectConfig
	data                  QueryData
	where                 QueryData
}
```

[[Return to contents]](#Contents)

## QueryData
```v
struct QueryData {
pub mut:
	fields      []string
	data        []Primitive
	types       []int
	parentheses [][]int
	kinds       []OperationKind
	auto_fields []int
	is_and      []bool
}
```

Examples for QueryData in SQL: abc == 3 && b == 'test' => fields[abc, b]; data[3, 'test']; types[index of int, index of string]; kinds[.eq, .eq]; is_and[true]; Every field, data, type & kind of operation in the expr share the same index in the arrays is_and defines how they're addicted to each other either and or or parentheses defines which fields will be inside () auto_fields are indexes of fields where db should generate a value when absent in an insert

[[Return to contents]](#Contents)

## SelectConfig
```v
struct SelectConfig {
pub mut:
	table      Table
	is_count   bool
	has_where  bool
	has_order  bool
	order      string
	order_type OrderType
	has_limit  bool
	primary    string = 'id' // should be set if primary is different than 'id' and 'has_limit' is false
	has_offset bool
	fields     []string
	types      []int
}
```

table - Table struct is_count - Either the data will be returned or an integer with the count has_where - Select all or use a where expr has_order - Order the results order - Name of the column which will be ordered order_type - Type of order (asc, desc) has_limit - Limits the output data primary - Name of the primary field has_offset - Add an offset to the result fields - Fields to select types - Types to select

[[Return to contents]](#Contents)

## Table
```v
struct Table {
pub mut:
	name  string
	attrs []VAttribute
}
```

[[Return to contents]](#Contents)

## TableField
```v
struct TableField {
pub mut:
	name        string
	typ         int
	nullable    bool
	default_val string
	attrs       []VAttribute
	is_arr      bool
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:37
