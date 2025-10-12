# Charting Capabilities

The spreadsheet module integrates with ECharts to provide powerful data visualization capabilities, allowing you to generate various types of charts directly from your sheet data.

## Common Charting Parameters (`RowGetArgs`)

Most charting functions utilize a common set of arguments defined in `RowGetArgs` to specify which data to chart and how to present it.

**Key `RowGetArgs` Parameters:**

- `rowname` (string, optional): The exact name of a single row to chart.
- `namefilter` ([]string, optional): A list of exact row names to include.
- `includefilter` ([]string, optional): A list of tags to include. Rows must match at least one of these tags.
- `excludefilter` ([]string, optional): A list of tags to exclude.
- `period_type` (`PeriodType`, optional): Specifies the period type for the chart's X-axis (e.g., `.month`, `.quarter`, `.year`).
- `aggregate` (bool, optional, default: `true`): If `true` and multiple rows match the filters, their values will be aggregated.
- `aggregatetype` (`RowAggregateType`, optional, default: `.sum`): The type of aggregation to perform if `aggregate` is `true`.
- `unit` (`UnitType`, optional): The unit of the data (e.g., currency, percentage).
- `title` (string, optional): The main title of the chart.
- `title_sub` (string, optional): A subtitle for the chart.
- `size` (string, optional): For pie charts, this can define the radius (e.g., "50%").
- `rowname_show` (bool, optional, default: `true`): Whether to show the row name in the chart legend/labels.
- `descr_show` (bool, optional, default: `false`): Whether to show the row description. If `true`, `rowname_show` will be set to `false`.
- `description` (string, optional): A general description for the chart.

## Chart Types

### Line Chart (`line_chart`)

Generates a line chart, ideal for visualizing trends over time. Multiple rows can be plotted on the same chart.

```v
import incubaid.herolib.biz.spreadsheet
import incubaid.herolib.web.echarts

// Assuming 'my_sheet' is an existing Sheet object
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!
// ... populate my_sheet with data

// Generate a line chart for 'revenue_row' and 'expenses_row' over months
line_chart_option := my_sheet.line_chart(
    rowname: 'revenue_row,expenses_row', // Comma-separated row names
    period_type: .month,
    title: 'Revenue vs. Expenses Over Time',
    title_sub: 'Monthly Data'
)!

// The 'line_chart_option' can then be used to render the chart using ECharts.
```

### Bar Chart (`bar_chart`)

Generates a bar chart, suitable for comparing discrete categories or values. Typically used for a single row's data.

```v
import incubaid.herolib.biz.spreadsheet
import incubaid.herolib.web.echarts

// Assuming 'my_sheet' is an existing Sheet object
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!
// ... populate my_sheet with data

// Generate a bar chart for 'profit_row' aggregated by quarter
bar_chart_option := my_sheet.bar_chart(
    rowname: 'profit_row',
    period_type: .quarter,
    title: 'Quarterly Profit',
    title_sub: 'Aggregated Data'
)!
```

### Pie Chart (`pie_chart`)

Generates a pie chart, useful for showing the proportion of different categories within a single data set. Typically used for a single row's data.

```v
import incubaid.herolib.biz.spreadsheet
import incubaid.herolib.web.echarts

// Assuming 'my_sheet' is an existing Sheet object
mut my_sheet := spreadsheet.sheet_new(name: 'my_sheet', nrcol: 60)!
// ... populate my_sheet with data

// Generate a pie chart for 'budget_allocation_row' showing yearly distribution
pie_chart_option := my_sheet.pie_chart(
    rowname: 'budget_allocation_row',
    period_type: .year,
    title: 'Annual Budget Allocation',
    size: '70%' // Set the radius of the pie chart
)!
```

## Integration with ECharts

The charting functions return an `echarts.EChartsOption` object, which is a JSON-serializable structure compatible with the ECharts JavaScript library. This allows for flexible rendering of these charts in web interfaces or other environments that support ECharts.
