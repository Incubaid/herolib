
# V ORM — Developer Cheat Sheet

*Fast reference for Struct Mapping, CRUD, Attributes, Query Builder, and Usage Patterns*

---

## 1. What V ORM Is

* Built-in ORM for **SQLite**, **MySQL**, **PostgreSQL**
* Unified V-syntax; no SQL string building
* Automatic query sanitization
* Compile-time type & field checks
* Structs map directly to tables

---

## 2. Define Models (Struct ↔ Table)

### Basic Example

```v
struct User {
    id    int    @[primary; sql: serial]
    name  string
    email string @[unique]
}
```

### Nullable Fields

```v
age ?int     // allows NULL
```

---

## 3. Struct Attributes

### Table-level

| Attribute                    | Meaning                   |
| ---------------------------- | ------------------------- |
| `@[table: 'custom_name']`    | Override table name       |
| `@[comment: '...']`          | Table comment             |
| `@[index: 'field1, field2']` | Creates multi-field index |

---

## 4. Field Attributes

| Attribute                                        | Description                  |
| ------------------------------------------------ | ---------------------------- |
| `@[primary]`                                     | Primary key                  |
| `@[unique]`                                      | UNIQUE constraint            |
| `@[unique: 'group']`                             | Composite unique group       |
| `@[skip]` / `@[sql: '-']`                        | Ignore field                 |
| `@[sql: serial]`                                 | Auto-increment key           |
| `@[sql: 'col_name']`                             | Rename column                |
| `@[sql_type: 'BIGINT']`                          | Force SQL type               |
| `@[default: 'CURRENT_TIMESTAMP']`                | Raw SQL default              |
| `@[fkey: 'field']`                               | Foreign key on a child array |
| `@[references]`, `@[references: 'table(field)']` | FK relationship              |
| `@[index]`                                       | Index on field               |
| `@[comment: '...']`                              | Column comment               |

### Example

```v
struct Post {
    id        int       @[primary; sql: serial]
    title     string
    body      string
    author_id int       @[references: 'users(id)']
}
```

---

## 5. ORM SQL Block (Primary API)

### Create Table

```v
sql db {
    create table User
}!
```

### Drop Table

```v
sql db {
    drop table User
}!
```

### Insert

```v
id := sql db {
    insert new_user into User
}!
```

### Select

```v
users := sql db {
    select from User where age > 18 && name != 'Tom'
    order by id desc
    limit 10
}!
```

### Update

```v
sql db {
    update User set name = 'Alice' where id == 1
}!
```

### Delete

```v
sql db {
    delete from User where id > 100
}!
```

---

## 6. Relationships

### One-to-Many

```v
struct Parent {
    id       int       @[primary; sql: serial]
    children []Child   @[fkey: 'parent_id']
}

struct Child {
    id        int       @[primary; sql: serial]
    parent_id int
}
```

---

## 7. Notes on `time.Time`

* Stored as integer timestamps
* SQL defaults like `NOW()` / `CURRENT_TIMESTAMP` **don’t work** for `time.Time` with V ORM defaults
* Use `@[default: 'CURRENT_TIMESTAMP']` only with custom SQL types

---

## 8. Query Builder API (Dynamic Queries)

### Create Builder

```v
mut qb := orm.new_query[User](db)
```

### Create Table

```v
qb.create()!
```

### Insert Many

```v
qb.insert_many(users)!
```

### Select

```v
results := qb
    .select('id, name')!
    .where('age > ?', 18)!
    .order('id DESC')!
    .limit(20)!
    .query()!
```

### Update

```v
qb
    .set('name = ?', 'NewName')!
    .where('id = ?', 1)!
    .update()!
```

### Delete

```v
qb.where('created_at IS NULL')!.delete()!
```

### Complex WHERE

```v
qb.where(
    '(salary > ? AND age < ?) OR (role LIKE ?)',
    3000, 40, '%engineer%'
)!
```

---

## 9. Connecting to Databases

### SQLite

```v
import db.sqlite
db := sqlite.connect('db.sqlite')!
```

### MySQL

```v
import db.mysql
db := mysql.connect(host: 'localhost', user: 'root', password: '', dbname: 'test')!
```

### PostgreSQL

```v
import db.pg
db := pg.connect(conn_str)!
```

---

## 10. Full Example (Complete CRUD)

```v
import db.sqlite

struct Customer {
    id    int    @[primary; sql: serial]
    name  string
    email string @[unique]
}

fn main() {
    db := sqlite.connect('customers.db')!

    sql db { create table Customer }!

    new_c := Customer{name: 'Alice', email: 'alice@x.com'}

    id := sql db { insert new_c into Customer }!
    println(id)

    list := sql db { select from Customer where name == 'Alice' }!
    println(list)

    sql db { update Customer set name = 'Alicia' where id == id }!

    sql db { delete from Customer where id == id }!
}
```

---

## 11. Best Practices

* Always use `sql db { ... }` for static queries
* Use QueryBuilder for dynamic conditions
* Prefer `sql: serial` for primary keys
* Explicitly define foreign keys
* Use `?T` for nullable fields
* Keep struct names identical to table names unless overridden

