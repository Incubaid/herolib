# Row and Cell Operations

Rows and Cells are fundamental building blocks of the spreadsheet, allowing for granular data management and manipulation.

## Row Operations

### Creating a New Row

Rows are created within the context of a `Sheet` object.

```v
import incubaid.herolib.biz.spreadsheet

// Assuming 'my_sheet' is an existing Sheet object
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!

// Create a new row named 'salaries' with specific tags and description
mut salaries_row := my_sheet.row_new(
    name: 'salaries',
    tags: 'department:hr location:belgium',
    descr: 'Monthly salaries for HR department in Belgium',
    aggregatetype: .sum // Optional: define default aggregation for this row
)!
```

### Setting Cell Values in a Row

Once a row is created, you can set values for its individual cells. The `set` method of a `Cell` handles currency conversion automatically if a currency string is provided.

```v
// Set the value of the first cell (column 0) in 'salaries_row'
// The value "1000 USD" will be converted to the sheet's currency if different.
salaries_row.cells[0].set('1000 USD')!

// Set a plain numeric value for the second cell (column 1)
salaries_row.cells[1].set('1200.50')!
```

### Adding Values to Cells

You can add a numeric value to an existing cell's value.

```v
// Add 500 to the value of the first cell
salaries_row.cells[0].add(500.0)
```

### Retrieving Row Values

You can get all the values of a row as a list of `f64`.

```v
// Get all values from 'salaries_row'
values := salaries_row.values_get()
// values will be a []f64
```

### String Representation of a Cell

The `repr()` and `str()` methods of a `Cell` provide a formatted string representation of its value.

```v
// Assuming 'my_cell' is a Cell object
cell_string := my_cell.repr()
// If the cell is empty, cell_string will be "-"
// Otherwise, it will be the formatted numeric value.
