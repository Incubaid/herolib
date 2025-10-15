# Herolib Spreadsheet Module for AI Prompt Engineering

This document provides an overview and usage instructions for the `incubaid.herolib.biz.spreadsheet` module, which offers a powerful software representation of a spreadsheet. This module is designed for business modeling, data analysis, and can be leveraged in AI prompt engineering scenarios where structured data manipulation and visualization are required.

## 1. Core Concepts

The spreadsheet module revolves around three main entities: `Sheet`, `Row`, and `Cell`.

### 1.1. Sheet

The `Sheet` is the primary container, representing the entire spreadsheet.

* **Properties:**
  * `name` (string): A unique identifier for the sheet.
  * `rows` (map[string]&Row): A collection of `Row` objects, indexed by their names.
  * `nrcol` (int): The number of columns in the sheet (e.g., 60 for 5 years of monthly data).
  * `params` (SheetParams): Configuration parameters, e.g., `visualize_cur` (boolean to display currency symbols).
  * `currency` (currency.Currency): The default currency for the sheet (e.g., USD), used for automatic conversions.

* **Creation:**

    ```v
    import incubaid.herolib.biz.spreadsheet

    // Create a new sheet named 'my_financial_sheet' with 60 columns (e.g., 60 months)
    mut my_sheet := spreadsheet.sheet_new(
        name: 'my_financial_sheet',
        nrcol: 60,
        visualize_cur: true, // Optional: display currency symbols
        curr: 'USD' // Optional: set default currency
    )!

    // Get an existing sheet from the global store
    mut existing_sheet := spreadsheet.sheet_get('my_financial_sheet')!
    ```

* **Key Operations:**
  * `sheet.row_get(name string) !&Row`: Retrieves a row by its name.
  * `sheet.cell_get(row string, col int) !&Cell`: Retrieves a cell by row name and column index.
  * `sheet.row_delete(name string)` / `sheet.delete(name string)`: Deletes a row.
  * `sheet.cells_width(colnr int) !int`: Finds the maximum string length of cells in a given column.
  * `sheet.rows_names_width_max() int`: Returns the maximum width of row names/aliases.
  * `sheet.rows_description_width_max() int`: Returns the maximum width of row descriptions.
  * `sheet.header() ![]string`: Generates column headers (e.g., "M1", "Q1", "Y1") based on `nrcol`.

### 1.2. Row

A `Row` represents a single horizontal line of data within a `Sheet`.

* **Properties:**
  * `name` (string): Unique identifier for the row.
  * `alias` (string, optional): Alternative name.
  * `description` (string): Textual description.
  * `tags` (string): Space-separated tags for categorization (e.g., "department:hr location:belgium").
  * `cells` ([]Cell): List of `Cell` objects.
  * `aggregatetype` (RowAggregateType): Defines default aggregation for this row (`.sum`, `.avg`, `.max`, `.min`).

* **Creation (within a Sheet):**

    ```v
    // Assuming 'my_sheet' is an existing Sheet object
    mut salaries_row := my_sheet.row_new(
        name: 'salaries',
        tags: 'department:hr location:belgium',
        descr: 'Monthly salaries for HR department in Belgium',
        aggregatetype: .sum
    )!
    ```

* **Key Operations:**
  * `row.values_get() []f64`: Returns all cell values in the row as a list of floats.

### 1.3. Cell

A `Cell` is the fundamental unit of data, storing a numeric value.

* **Properties:**
  * `val` (f64): The numeric value.
  * `empty` (bool): `true` if the cell is empty.

* **Key Operations:**
  * `cell.set(v string) !`: Sets the cell's value. Handles currency strings (e.g., "100 USD") by converting to the sheet's currency.
  * `cell.add(v f64)`: Adds a numeric value to the existing cell value.
  * `cell.repr() string`: Returns a formatted string representation of the value (e.g., "100.00", or "-" if empty).

## 2. Data Aggregation and Transformation

The module provides powerful tools for summarizing and transforming data.

### 2.1. Grouping Rows (`group2row`)

Aggregates selected rows into a new single row based on tags.

```v
// Aggregate rows tagged 'department:dev' or 'department:engineering' into a new row
mut total_salaries_row := my_sheet.group2row(
    name: 'total_dev_engineering_salaries',
    include: ['department:dev', 'department:engineering'],
    tags: 'summary:dev_eng',
    descr: 'Total salaries for Development and Engineering departments',
    aggregatetype: .sum // Can be .sum, .avg, .max, .min
)!
```

### 2.2. Transforming Periodicity (`toyear`, `toquarter`)

Creates new sheets with data aggregated into larger time periods.

```v
// Assuming 'monthly_sheet' has 60 columns (monthly data)
mut monthly_sheet := spreadsheet.sheet_new(name: 'monthly_data', nrcol: 60)!
// ... populate monthly_sheet

// Create a new sheet 'yearly_data' with data aggregated by year
mut yearly_sheet := monthly_sheet.toyear(
    name: 'yearly_data',
    namefilter: ['revenue_row', 'expenses_row'], // Optional: filter specific rows
    includefilter: ['category:income'] // Optional: filter by tags
)!

// Create a new sheet 'quarterly_data' with data aggregated by quarter
mut quarterly_sheet := monthly_sheet.toquarter(name: 'quarterly_data')!
```

## 3. Exporting Data

Export sheet data to CSV format.

### 3.1. Export to CSV (`export_csv`)

```v
import os

// Export to a CSV file with default pipe '|' separator
my_sheet.export_csv(path: '~/output.csv')!

// Export with custom comma ',' separator and include empty cells
csv_content_with_empty := my_sheet.export_csv(
    path: '~/output_with_empty.csv',
    separator: ',',
    include_empty: true
)!

// Export to a string only (no file)
csv_string := my_sheet.export_csv(path: '')!
println(csv_string)
```

* **`ExportCSVArgs` Parameters:**
  * `path` (string, optional): File path. Empty string returns content as string. `~` is expanded to home directory.
  * `include_empty` (bool, optional, default: `false`): If `true`, empty cells are included.
  * `separator` (string, optional, default: `'|'`): Delimiter character.

## 4. Charting Capabilities

Integrates with ECharts for data visualization. Charting functions return an `echarts.EChartsOption` object.

### 4.1. Common Charting Parameters (`RowGetArgs`)

Used across line, bar, and pie charts to specify data and presentation.

* `rowname` (string, optional): Single row name or comma-separated list.
* `namefilter` ([]string, optional): List of exact row names to include.
* `includefilter` ([]string, optional): List of tags to include.
* `excludefilter` ([]string, optional): List of tags to exclude.
* `period_type` (PeriodType, optional): X-axis period (`.month`, `.quarter`, `.year`).
* `aggregate` (bool, optional, default: `true`): Aggregate multiple matching rows.
* `aggregatetype` (RowAggregateType, optional, default: `.sum`): Aggregation type.
* `unit` (UnitType, optional): Data unit.
* `title`, `title_sub` (string, optional): Chart titles.
* `size` (string, optional): For pie charts, defines radius (e.g., "70%").
* `rowname_show` (bool, optional, default: `true`): Show row name in legend.
* `descr_show` (bool, optional, default: `false`): Show row description (overrides `rowname_show`).
* `description` (string, optional): General chart description.

### 4.2. Chart Types

* **Line Chart (`line_chart`)**: Visualizes trends over time.

    ```v
    import incubaid.herolib.web.echarts // Required for EChartsOption type

    line_chart_option := my_sheet.line_chart(
        rowname: 'revenue_row,expenses_row',
        period_type: .month,
        title: 'Revenue vs. Expenses Over Time'
    )!
    ```

* **Bar Chart (`bar_chart`)**: Compares discrete categories or values.

    ```v
    bar_chart_option := my_sheet.bar_chart(
        rowname: 'profit_row',
        period_type: .quarter,
        title: 'Quarterly Profit'
    )!
    ```

* **Pie Chart (`pie_chart`)**: Shows proportions of categories.

    ```v
    pie_chart_option := my_sheet.pie_chart(
        rowname: 'budget_allocation_row',
        period_type: .year,
        title: 'Annual Budget Allocation',
        size: '70%'
    )!
    ```

This documentation should provide sufficient information for an AI to understand and utilize the `lib/biz/spreadsheet` module effectively for various data manipulation and visualization tasks.
