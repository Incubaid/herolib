# Exporting Data

The spreadsheet module provides functionality to export sheet data into various formats, making it easy to integrate with other tools or for reporting purposes.

## Exporting to CSV

The `export_csv` method allows you to export the sheet's data to a CSV (Comma Separated Values) file or directly as a string. It offers flexibility in terms of separators and handling of empty cells.

```v
import incubaid.herolib.biz.spreadsheet
import os

// Assuming 'my_sheet' is an existing Sheet object
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!
// ... populate my_sheet with data

// Export to a CSV file with the default pipe '|' separator
// The file will be created at '~/output.csv'
my_sheet.export_csv(path: '~/output.csv')!

// Export to a CSV file with a custom comma ',' separator and include empty cells
csv_content_with_empty := my_sheet.export_csv(
    path: '~/output_with_empty.csv',
    separator: ',',
    include_empty: true
)!

// Export to a string only (no file will be created)
csv_string := my_sheet.export_csv(path: '')!
println(csv_string)
```

**`ExportCSVArgs` Parameters:**

- `path` (string, optional): The file path where the CSV should be saved. If an empty string is provided, the CSV content will be returned as a string instead of being written to a file. The `~` character is expanded to the user's home directory.
- `include_empty` (bool, optional, default: `false`): If `true`, empty cells will be included in the CSV output (represented as '0' for numeric values, or empty string for others). If `false`, empty cells will be represented as an empty string.
- `separator` (string, optional, default: `'|'`): The character used to separate values in the CSV. Common separators include ',' (comma), ';' (semicolon), or '|' (pipe).

**CSV Export Features:**

- **Configurable Separator:** Easily change the delimiter to suit different CSV parsing requirements.
- **Special Character Handling:** Values containing the separator, double quotes, or newlines are automatically enclosed in double quotes, and internal double quotes are escaped (e.g., `"` becomes `""`).
- **Empty Cell Inclusion:** Control whether empty cells are explicitly represented in the output.
- **Numeric Formatting:** Numeric values are formatted appropriately, with small numbers showing up to 3 decimal places and larger numbers as integers. Trailing zeros and decimal points are removed if unnecessary.

The CSV output includes a header row with "Name", "Description", "AggregateType", "Tags", "Subgroup", followed by the sheet's column headers (e.g., "M1", "M2", "Y1", etc.). Each subsequent row represents a sheet row, with its metadata followed by its cell values.
