# Data Aggregation and Transformation

The spreadsheet module provides powerful functionalities to aggregate and transform data within sheets, allowing for different views and summarized insights.

## Grouping Rows into a New Row

The `group2row` method allows you to select rows based on their tags and aggregate their values into a new, single row. This is particularly useful for creating summary rows (e.g., total salaries for a specific department).

```v
import incubaid.herolib.biz.spreadsheet

// Assuming 'my_sheet' is an existing Sheet object with various rows
// and some rows have tags like 'department:dev' or 'department:engineering'.
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!
// ... add rows to my_sheet with relevant tags and data

// Aggregate all rows tagged with 'department:dev' or 'department:engineering'
// into a new row named 'total_dev_engineering_salaries'.
// The aggregation type defaults to 'sum'.
mut total_salaries_row := my_sheet.group2row(
    name: 'total_dev_engineering_salaries',
    include: ['department:dev', 'department:engineering'],
    tags: 'summary:dev_eng', // Optional: tags for the new aggregated row
    descr: 'Total salaries for Development and Engineering departments'
)!

// You can also specify an aggregation type other than sum, e.g., .avg, .max, .min
// mut avg_salaries_row := my_sheet.group2row(
//     name: 'average_salaries',
//     include: ['department:dev'],
//     aggregatetype: .avg
// )!
```

**`Group2RowArgs` Parameters:**

- `name` (string, required): The name of the new aggregated row.
- `include` ([]string, optional): A list of tags to include. Rows must match at least one of these tags to be included in the aggregation. Supports wildcard matching (e.g., `location:belgium_*`).
- `exclude` ([]string, optional): A list of tags to exclude. Rows matching any of these tags will be excluded from the aggregation.
- `tags` (string, optional): Tags to assign to the newly created aggregated row.
- `descr` (string, optional): Description for the new aggregated row.
- `subgroup` (string, optional): Subgroup for the new aggregated row.
- `aggregatetype` (`RowAggregateType`, optional, default: `.sum`): The type of aggregation to perform.
  - `.sum`: Sums the values of matching cells.
  - `.avg`: Calculates the average of matching cells.
  - `.max`: Finds the maximum value among matching cells.
  - `.min`: Finds the minimum value among matching cells.

## Transforming Sheet Periodicity (Yearly/Quarterly Aggregation)

The module allows you to create new sheets where the data is aggregated into larger time periods, such as years or quarters, from a monthly-based sheet.

### Aggregating to Yearly Data

The `toyear` method creates a new sheet where monthly data is aggregated into yearly columns.

```v
import incubaid.herolib.biz.spreadsheet

// Assuming 'monthly_sheet' is a sheet with 60 columns (5 years of monthly data)
mut monthly_sheet := spreadsheet.sheet_new(name: 'monthly_data', nrcol: 60)!
// ... populate monthly_sheet with data

// Create a new sheet 'yearly_data' with data aggregated by year
mut yearly_sheet := monthly_sheet.toyear(
    name: 'yearly_data',
    namefilter: ['revenue_row', 'expenses_row'], // Optional: only include specific rows
    includefilter: ['category:income'], // Optional: filter rows by tags
    excludefilter: ['status:draft'] // Optional: exclude rows by tags
)!
```

### Aggregating to Quarterly Data

Similarly, the `toquarter` method creates a new sheet with data aggregated into quarterly columns.

```v
import incubaid.herolib.biz.spreadsheet

// Assuming 'monthly_sheet' is a sheet with 60 columns
mut monthly_sheet := spreadsheet.sheet_new(name: 'monthly_data', nrcol: 60)!
// ... populate monthly_sheet with data

// Create a new sheet 'quarterly_data' with data aggregated by quarter
mut quarterly_sheet := monthly_sheet.toquarter(
    name: 'quarterly_data'
)!
```

**`ToYearQuarterArgs` Parameters:**

- `name` (string, optional): The name of the new aggregated sheet. If empty, a default name based on the original sheet and period (e.g., `original_sheet_name_year`) is used.
- `namefilter` ([]string, optional): A list of exact row names to include in the new sheet. If provided, only these rows will be processed.
- `includefilter` ([]string, optional): A list of tags to include. Rows must match at least one of these tags to be included.
- `excludefilter` ([]string, optional): A list of tags to exclude. Rows matching any of these tags will be excluded.
