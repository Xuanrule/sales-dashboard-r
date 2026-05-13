# ============================================================
#  Sales Analytics Dashboard
#  Stack: R + Shiny + RSQLite + ggplot2 + plotly
#  Run: Open in RStudio → click "Run App"
# ============================================================

# ── 0. Install packages (run once) ──────────────────────────
# Uncomment and run the line below if first time:
# install.packages(c("shiny", "DBI", "RSQLite", "dplyr", "ggplot2", "plotly", "scales", "bslib"))

library(shiny)
library(DBI)
library(RSQLite)
library(dplyr)
library(ggplot2)
library(plotly)
library(scales)
library(bslib)

# ── 1. Create in-memory SQLite database & populate ──────────
con <- dbConnect(RSQLite::SQLite(), ":memory:")

set.seed(42)
categories <- c("Electronics", "Clothing", "Home & Living", "Sports", "Beauty")
regions    <- c("North", "South", "East", "West", "Central")
months     <- seq.Date(as.Date("2024-01-01"), by = "month", length.out = 12)

base_rev <- c(Electronics = 85000, Clothing = 52000,
              `Home & Living` = 43000, Sports = 31000, Beauty = 28000)

records <- do.call(rbind, lapply(months, function(m) {
  do.call(rbind, lapply(categories, function(cat) {
    noise    <- runif(1, 0.85, 1.20)
    seasonal <- ifelse(as.integer(format(m, "%m")) %in% c(11, 12), 1.3,
                ifelse(as.integer(format(m, "%m")) %in% c(6,  7),  1.1, 1.0))
    rev  <- round(base_rev[cat] * noise * seasonal, 2)
    ord  <- as.integer(rev / runif(1, 120, 180))
    data.frame(month = format(m, "%Y-%m"), category = cat,
               revenue = rev, orders = ord, stringsAsFactors = FALSE)
  }))
}))

region_records <- data.frame(
  region  = regions,
  revenue = c(312000, 278000, 356000, 198000, 234000)
)

dbWriteTable(con, "sales",   records,        overwrite = TRUE)
dbWriteTable(con, "regions", region_records, overwrite = TRUE)

# ── 2. SQL queries ───────────────────────────────────────────
# Monthly totals
df_monthly <- dbGetQuery(con, "
  SELECT month,
         SUM(revenue) AS total_revenue,
         SUM(orders)  AS total_orders
  FROM sales
  GROUP BY month
  ORDER BY month
")

# Category totals
df_cat <- dbGetQuery(con, "
  SELECT category,
         SUM(revenue) AS total_revenue
  FROM sales
  GROUP BY category
  ORDER BY total_revenue DESC
")

# Regional totals
df_region <- dbGetQuery(con, "
  SELECT region, revenue
  FROM regions
  ORDER BY revenue ASC
")

# KPIs
kpis <- dbGetQuery(con, "
  SELECT SUM(revenue)           AS total_revenue,
         SUM(orders)            AS total_orders,
         SUM(revenue)/SUM(orders) AS avg_order
  FROM sales
")

dbDisconnect(con)

# ── 3. Chart theme ───────────────────────────────────────────
ACCENT  <- "#6366f1"
PALETTE <- c("#6366f1","#8b5cf6","#a78bfa","#c4b5fd","#ddd6fe")
BG      <- "#0f0f1a"
CARD_BG <- "#1a1a2e"
TEXT    <- "#e2e8f0"
MUTED   <- "#94a3b8"
GRID    <- "#2d2d4e"

dark_theme <- theme_minimal(base_family = "sans") +
  theme(
    plot.background  = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA),
    panel.grid.major = element_line(color = GRID, linewidth = 0.4),
    panel.grid.minor = element_blank(),
    text             = element_text(color = TEXT),
    axis.text        = element_text(color = MUTED, size = 10),
    axis.title       = element_blank(),
    plot.title       = element_text(color = TEXT, size = 13, face = "bold", margin = margin(b=10)),
    legend.background = element_rect(fill = "transparent", color = NA),
    legend.text      = element_text(color = MUTED, size = 9),
    legend.title     = element_blank(),
  )

# ── 4. Build charts ──────────────────────────────────────────
make_line <- function() {
  p <- ggplot(df_monthly, aes(x = month, y = total_revenue, group = 1)) +
    geom_area(fill = ACCENT, alpha = 0.15) +
    geom_line(color = ACCENT, linewidth = 2) +
    geom_point(color = ACCENT, size = 3) +
    scale_y_continuous(labels = label_comma(prefix = "¥", scale = 1e-3, suffix = "K")) +
    labs(title = "Monthly Revenue Trend") +
    dark_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  ggplotly(p, tooltip = c("x","y")) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
           font = list(color = TEXT), margin = list(l=50, r=20, t=40, b=60))
}

make_pie <- function() {
  plot_ly(df_cat, labels = ~category, values = ~total_revenue, type = "pie",
          hole = 0.45, marker = list(colors = PALETTE),
          textfont = list(color = TEXT)) %>%
    layout(title  = list(text = "Revenue by Category", font = list(color = TEXT, size = 13)),
           paper_bgcolor = "rgba(0,0,0,0)",
           font   = list(color = TEXT),
           legend = list(font = list(color = TEXT)),
           margin = list(l=20, r=20, t=50, b=20))
}

make_bar <- function() {
  p <- ggplot(df_region, aes(x = revenue, y = reorder(region, revenue), fill = revenue)) +
    geom_col(show.legend = FALSE) +
    scale_fill_gradient(low = "#4338ca", high = "#a78bfa") +
    scale_x_continuous(labels = label_comma(prefix = "¥", scale = 1e-3, suffix = "K")) +
    labs(title = "Revenue by Region") +
    dark_theme
  ggplotly(p, tooltip = c("x","y")) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
           font = list(color = TEXT), margin = list(l=80, r=20, t=40, b=40))
}

make_area <- function() {
  # Re-query full data for stacked area
  con2 <- dbConnect(RSQLite::SQLite(), ":memory:")
  dbWriteTable(con2, "sales", records, overwrite = TRUE)
  df_full <- dbGetQuery(con2, "
    SELECT month, category, SUM(revenue) AS revenue
    FROM sales GROUP BY month, category ORDER BY month
  ")
  dbDisconnect(con2)

  p <- ggplot(df_full, aes(x = month, y = revenue, fill = category, group = category)) +
    geom_area(alpha = 0.8, position = "stack") +
    scale_fill_manual(values = PALETTE) +
    scale_y_continuous(labels = label_comma(prefix = "¥", scale = 1e-3, suffix = "K")) +
    labs(title = "Category Performance Over Time") +
    dark_theme +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  ggplotly(p) %>%
    layout(paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
           font = list(color = TEXT),
           legend = list(font = list(color = TEXT)),
           margin = list(l=50, r=20, t=40, b=60))
}

# ── 5. KPI card UI helper ────────────────────────────────────
kpi_card <- function(label, value, delta) {
  div(style = paste0(
    "background:", CARD_BG, ";border-radius:12px;padding:20px 24px;",
    "border:1px solid #2d2d4e;flex:1;min-width:160px;"),
    p(label, style = paste0("color:", MUTED, ";font-size:12px;margin:0 0 6px 0;")),
    h3(value, style = paste0("color:", TEXT, ";margin:0;font-size:24px;font-weight:700;")),
    p(delta,  style = "color:#4ade80;font-size:12px;margin:4px 0 0 0;")
  )
}

# ── 6. Shiny UI ──────────────────────────────────────────────
ui <- fluidPage(
  tags$head(tags$style(HTML(paste0("
    body { background-color:", BG, "; font-family: 'Inter', Arial, sans-serif; }
    .main-title { color:", TEXT, "; font-size:22px; font-weight:700; margin:0; }
    .sub-title   { color:", MUTED,"; font-size:13px; margin:4px 0 28px 0; }
    .card { background:", CARD_BG, "; border-radius:12px; padding:12px;
            border:1px solid #2d2d4e; height:100%; }
    .kpi-row { display:flex; gap:16px; flex-wrap:wrap; margin-bottom:24px; }
    .chart-row { display:flex; gap:16px; margin-bottom:24px; }
  ")))),

  div(style = "padding:32px;",
    # Header
    p("📊 Sales Analytics Dashboard", class = "main-title"),
    p("FY 2024  ·  All Regions  ·  SQL + R Shiny", class = "sub-title"),

    # KPI row
    div(class = "kpi-row",
      kpi_card("Total Revenue",   paste0("¥", format(round(kpis$total_revenue), big.mark=",")), "↑ 18.4% vs last year"),
      kpi_card("Total Orders",    format(kpis$total_orders, big.mark=","),                      "↑ 12.1% vs last year"),
      kpi_card("Avg Order Value", paste0("¥", format(round(kpis$avg_order), big.mark=",")),     "↑ 5.6% vs last year"),
      kpi_card("Top Category",    "Electronics",                                                 "34.3% of revenue"),
    ),

    # Row 1
    fluidRow(
      column(8, div(class="card", plotlyOutput("line_chart", height="280px"))),
      column(4, div(class="card", plotlyOutput("pie_chart",  height="280px"))),
    ),
    br(),
    # Row 2
    fluidRow(
      column(4, div(class="card", plotlyOutput("bar_chart",  height="280px"))),
      column(8, div(class="card", plotlyOutput("area_chart", height="280px"))),
    ),
  )
)

# ── 7. Shiny Server ──────────────────────────────────────────
server <- function(input, output, session) {
  output$line_chart <- renderPlotly({ make_line() })
  output$pie_chart  <- renderPlotly({ make_pie()  })
  output$bar_chart  <- renderPlotly({ make_bar()  })
  output$area_chart <- renderPlotly({ make_area() })
}

shinyApp(ui, server)
