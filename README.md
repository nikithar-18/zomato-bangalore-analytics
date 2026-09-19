# Zomato Bangalore Analytics

An end-to-end data analytics capstone project on the Zomato Bangalore restaurant dataset — from raw data cleaning through SQL analysis to a Power BI dashboard.

**Status:** Phase 1 complete ✅ | Phase 2 in progress | Phase 3 not started

---

## Project Overview

This project simulates a real-world food delivery analytics pipeline:
1. **Phase 1:** Clean and structure raw restaurant data, generate a synthetic orders dataset, merge them, and validate data quality.
2. **Phase 2:** Exploratory data analysis and 20 SQL queries across four themes — rating-to-cost ratio, underserved localities, delivery time by area, and restaurant churn/peak hours.
3. **Phase 3:** A 4-page Power BI dashboard (city overview, cuisine trends, delivery performance, restaurant leaderboard) with written insights.

## Dataset

- **Source:** [Zomato Bangalore Restaurants](https://www.kaggle.com/datasets) (Kaggle), 51,717 raw rows, 17 columns
- **Orders data:** Synthetically generated (not real transactions) using weighted randomization tied to each restaurant's actual cost tier, to simulate realistic order patterns for analysis practice

## Repository Structure

```
zomato-bangalore-analytics/
├── data/
│   ├── zomato_clean.csv       # Cleaned, deduplicated restaurant data (12,382 rows)
│   └── orders.csv              # Synthetic orders data (20,000 rows)
├── notebooks/                  # Colab notebooks (cleaning, EDA, SQL queries)
├── zomato_bangalore.db         # SQLite database (restaurants, orders, merged_orders view)
└── README.md
```

## Phase 1: Data Cleaning & Preparation

**Key steps:**
- Loaded and profiled the raw 51,717-row dataset; quantified nulls as percentages
- Dropped unusable columns (`url`, `phone`, `reviews_list`, `menu_item`, `dish_liked`)
- Parsed the `rate` column with regex, correctly treating `'NEW'`/`'-'` restaurants as *not yet rated* rather than imputing a biased average
- Cleaned the `approx_cost(for two people)` column (comma-stripping, type casting)
- **Identified and resolved a row-duplication issue**: the raw data lists each restaurant once per Zomato listing category (`listed_in(type)`), inflating 51,717 rows down to 12,382 true unique restaurants. Resolved via aggregation (not naive dropping) to preserve listing-type information.
- Generated a synthetic `orders` table (20,000 rows) with customer repeat-behavior (for churn analysis), peak-hour weighted timestamps, and cost-correlated order values
- Loaded both tables into SQLite with a `merged_orders` view joining orders to restaurant details
- Ran a 7-point data quality check (orphaned foreign keys, null critical fields, invalid ranges, duplicate IDs) — all checks passed

**Result:** A clean, joinable dataset ready for SQL analysis.

## Phase 2: EDA & SQL Analysis *(in progress)*

20 SQL queries across:
1. Rating-to-cost ratio by cuisine
2. Underserved localities (low restaurant density / high demand)
3. Average delivery time by area
4. Restaurant churn and peak ordering hours

*(Findings to be added here as completed)*

## Phase 3: Power BI Dashboard *(not started)*

Planned pages: City Overview · Cuisine Trends · Delivery Performance · Restaurant Leaderboard

*(Screenshots and insights to be added here)*

## Tools Used

Python (pandas), SQLite, Google Colab, Power BI, GitHub

---

*This is a learning/portfolio project. Order data is synthetically generated and does not represent real transactions.*
