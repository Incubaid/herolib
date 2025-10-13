# Sheet Operations

The `Sheet` object is the central component of the spreadsheet module, providing methods to manage and manipulate the overall spreadsheet data.

## Creating a New Sheet

A new sheet can be initialized using the `sheet_new` function.

```v
import incubaid.herolib.biz.spreadsheet

// Create a new sheet named 'my_financial_sheet' with 60 columns
mut my_sheet := spreadsheet.sheet_new(
    name: 'my_financial_sheet',
    nrcol: 60,
    visualize_cur: true, // Optional: display currency symbols in cells
    curr: 'USD' // Optional: set the default currency for the sheet
)!
```

## Retrieving Rows and Cells

You can access specific rows and cells within a sheet using their names and column numbers.

### Get a Row by Name

```v
// Assuming 'my_sheet' is an existing Sheet object
// and 'revenue_row' is the name of a row within it.
mut revenue_row := my_sheet.row_get('revenue_row')!
// Now you can work with the 'revenue_row' object
```

### Get a Cell by Row Name and Column Number

```v
// Get the cell at column 5 of 'revenue_row'
mut cell_data := my_sheet.cell_get('revenue_row', 5)!
// Access the value: cell_data.val
```

## Deleting Rows

Rows can be removed from a sheet using their name.

```v
// Delete the row named 'expense_row'
my_sheet.row_delete('expense_row')
// Alternatively, using the 'delete' alias
my_sheet.delete('expense_row')
```

## Calculating Widths for Display

The sheet provides utility functions to determine the maximum string length of cell values, row names, and row descriptions, which can be useful for formatting output.

### Maximum Cell Width for a Column

```v
// Get the maximum width of cells in the first column (column index 0)
max_width_col0 := my_sheet.cells_width(0)!
```

### Maximum Row Name/Alias Width

```v
// Get the maximum width among all row names and aliases in the sheet
max_row_name_width := my_sheet.rows_names_width_max()
```

### Maximum Row Description Width

```v
// Get the maximum width among all row descriptions in the sheet
max_row_descr_width := my_sheet.rows_description_width_max()
```

## Generating Headers

The `header()` function generates a list of strings representing the column headers based on the number of columns (`nrcol`). It automatically determines if the sheet represents months, quarters, or years.

```v
// For a sheet with 60 columns (months)
// header_labels will be ["M1", "M2", ..., "M60"]
header_labels := my_sheet.header()!

// For a sheet with 5 columns (years)
// header_labels will be ["Y1", "Y2", ..., "Y5"]
