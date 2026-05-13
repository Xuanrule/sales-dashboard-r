👉 [简体中文](./README_CN.md)
# 📊 Sales Analytics Dashboard

Interactive sales data dashboard built with **R + Shiny + SQLite**, featuring dark-mode UI and SQL-driven data queries.

<div align="center">
  <img src="https://github.com/user-attachments/assets/bede00d5-5eae-4657-8ce0-5c3cddc20bbf" width="700">
</div>


## ✨ Features

- **KPI Cards** — Total revenue, order count, avg order value, top category
- **Monthly Revenue Trend** — Area + line chart across 12 months
- **Revenue by Category** — Interactive donut chart (5 categories)
- **Regional Performance** — Horizontal bar chart (5 regions)
- **Category Over Time** — Stacked area chart showing growth trends

## 🛠 Tech Stack

| Layer | Tools |
|-------|-------|
| Framework | R · Shiny |
| Database | SQLite (via RSQLite + DBI) |
| Data Query | SQL — aggregation, grouping, ordering |
| Visualization | ggplot2 · plotly |
| Data Wrangling | dplyr |

## 🚀 Quick Start

**1. Open RStudio → open `app.R`**

**2. Install packages (first time only)**

Uncomment and run this line at the top of `app.R`:
```r
install.packages(c("shiny", "DBI", "RSQLite", "dplyr", "ggplot2", "plotly", "scales", "bslib"))
```

**3. Click "Run App" in RStudio**

The dashboard opens automatically in your browser.

## 📁 Project Structure

```
sales-dashboard-r/
├── app.R        # Full application (UI + Server + SQL)
└── README.md
```

## 🗄 SQL Queries Used

```sql
-- Monthly revenue & orders
SELECT month, SUM(revenue) AS total_revenue, SUM(orders) AS total_orders
FROM sales GROUP BY month ORDER BY month

-- Category breakdown
SELECT category, SUM(revenue) AS total_revenue
FROM sales GROUP BY category ORDER BY total_revenue DESC

-- KPI aggregation
SELECT SUM(revenue) AS total_revenue,
       SUM(orders)  AS total_orders,
       SUM(revenue)/SUM(orders) AS avg_order
FROM sales
```

## 📌 Notes

- Data is generated in-code via RSQLite in-memory database — no external files needed
- Seasonal patterns built in (Q4 peak, summer uptick)
- All charts are interactive (hover, zoom, filter)
