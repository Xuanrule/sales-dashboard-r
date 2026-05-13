👉 [ENGLISH](./README.md)
# 📊 销售分析仪表板
基于 **R + Shiny + SQLite** 构建的交互式销售数据仪表板，支持深色模式界面，采用 SQL 驱动的数据查询。

<div align="center">
  <img src="https://github.com/user-attachments/assets/bede00d5-5eae-4657-8ce0-5c3cddc20bbf" width="700">
</div>

## ✨ 功能特性
- **核心指标卡片** — 总营收、订单数量、平均订单金额、热门品类
- **月度营收趋势** — 12 个月面积图 + 折线图
- **品类营收占比** — 交互式环形图（5 大品类）
- **区域业绩排行** — 水平条形图（5 大区域）
- **品类趋势变化** — 堆叠面积图，展示增长趋势

## 🛠 技术栈
| 层级 | 工具 |
|------|------|
| 开发框架 | R · Shiny |
| 数据库 | SQLite（基于 RSQLite + DBI） |
| 数据查询 | SQL — 聚合、分组、排序 |
| 数据可视化 | ggplot2 · plotly |
| 数据处理 | dplyr |

## 🚀 快速开始
**1. 打开 RStudio → 打开 `app.R` 文件**

**2. 安装包（仅第一次运行需要）**

取消 `app.R` 顶部该行代码的注释并运行：
```r
install.packages(c("shiny", "DBI", "RSQLite", "dplyr", "ggplot2", "plotly", "scales", "bslib"))
```

**3.点击"Run App"**

那么，仪表板会自动在浏览器中打开!

## 📁项目结构

```
sales-dashboard-r/
├── app.R        # Full application (UI + Server + SQL)
└── README.md
```

## 🗄 使用的 SQL 查询

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

## 📌 说明

- 该数据为模拟数据，在代码内通过 RSQLite 内存数据库自动生成了12个月、5个品类、5个地区的销售数据，加入了季节性波动，然后写入 SQLite 数据库，目的是演示从数据库查询到可视化的完整技术架构。
- 内置季节性规律（第四季度峰值、夏季小幅增长）
- 所有图表均支持交互（悬停查看详情、缩放、筛选）
