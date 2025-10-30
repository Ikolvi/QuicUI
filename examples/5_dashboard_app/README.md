# Dashboard App Example

## Overview
An analytics dashboard demonstrating:
- **Data Visualization**: Charts and graphs (line, bar, pie)
- **Metric Cards**: Display KPIs in card format
- **Real-time Updates**: Refresh data from API
- **Responsive Layout**: Grid and scrollable design
- **Data Aggregation**: Summary statistics
- **Responsive Grid**: Multi-column card layout

## Features
✅ Metric cards in 2x2 grid  
✅ Line charts for trend visualization  
✅ Summary statistics  
✅ Real-time data refresh  
✅ Responsive responsive layout  
✅ Date range filtering  
✅ Color-coded positive/negative changes  

## JSON Structure

### Metric Cards Grid
```json
{
  "id": "grid_view_cards",
  "type": "GridView",
  "properties": {
    "crossAxisCount": 2,
    "padding": 16,
    "mainAxisSpacing": 16,
    "crossAxisSpacing": 16
  },
  "stateBinding": {
    "variable": "metrics",
    "defaultValue": []
  },
  "itemBuilder": {...}
}
```

### Line Chart
```json
{
  "id": "chart_line",
  "type": "LineChart",
  "properties": {
    "height": 300,
    "xLabel": "Date",
    "yLabel": "Revenue ($)"
  },
  "stateBinding": {
    "variable": "revenueData",
    "defaultValue": []
  }
}
```

### Metric Card Item
```json
{
  "id": "metric_card",
  "type": "Card",
  "children": [
    {
      "id": "text_metric_label",
      "type": "Text",
      "properties": {
        "data": "{metric.label}"
      }
    },
    {
      "id": "text_metric_value",
      "type": "Text",
      "properties": {
        "data": "{metric.value}"
      }
    },
    {
      "id": "text_metric_change",
      "type": "Text",
      "properties": {
        "data": "{metric.change}",
        "color": "{metric.changePositive ? '#4CAF50' : '#F44336'}"
      }
    }
  ]
}
```

## Key Concepts

### GridView for Cards
- **crossAxisCount**: Number of columns (2 for dashboard)
- **spacing**: Gap between cards
- **itemBuilder**: Template for each card
- **Dynamic data**: Bind to state array

### Chart Types
- **LineChart**: Trend visualization
- **BarChart**: Comparison of values
- **PieChart**: Proportion visualization
- **AreaChart**: Cumulative trends

### Metric Cards
- **Label**: Metric name
- **Value**: Current metric value
- **Change**: Percentage change
- **Positive**: Green color if increase
- **Negative**: Red color if decrease

### Data Structure

#### Metric Card Data
```json
{
  "metrics": [
    {
      "label": "Total Users",
      "value": "1,234",
      "change": "+12.5%",
      "changePositive": true
    },
    {
      "label": "Active Sessions",
      "value": "456",
      "change": "+3.2%",
      "changePositive": true
    }
  ]
}
```

#### Chart Data
```json
{
  "revenueData": [
    {"date": "2024-01-01", "value": 1000},
    {"date": "2024-01-02", "value": 1200},
    {"date": "2024-01-03", "value": 1100}
  ]
}
```

#### Summary Data
```json
{
  "totalRevenue": "$12,345.67",
  "averageOrder": "$234.56"
}
```

## API Integration

### Analytics Endpoint
**GET /api/analytics**

Query Parameters:
- `dateRange`: "7d", "30d", "90d", "1y"
- `metrics`: Comma-separated metric names

Response:
```json
{
  "period": "2024-01-01 to 2024-01-07",
  "metrics": [
    {
      "label": "Total Revenue",
      "value": 12345.67,
      "change": 12.5,
      "positive": true
    }
  ],
  "chartData": [
    {"date": "2024-01-01", "revenue": 1000}
  ],
  "summary": {
    "totalRevenue": 12345.67,
    "averageOrder": 234.56
  }
}
```

## Testing
This app is tested with:
- GridView rendering tests
- Chart rendering tests
- Data binding tests
- Real-time update tests
- API integration tests
- Layout responsiveness tests

See `test/examples/dashboard_app_test.dart` for implementation.

## Running the Example
```bash
flutter run --dart-define=QUICUI_CONFIG=dashboard_app.json
```

## Advanced Features
- Date range picker
- Metric customization
- Export data as PDF/CSV
- Custom date ranges
- Multiple chart types
- Drill-down analytics
- Comparison views
- Forecasting

## Performance Considerations
- Lazy load charts
- Cache chart data
- Paginate large datasets
- Optimize grid rendering
- Use virtual scrolling for large lists

## Next Steps
- Add date range picker
- Implement custom metrics
- Add export functionality
- Create drill-down views
- Add comparison charts
- Implement data caching
- Add offline support
