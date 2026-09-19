# Zomato Bangalore Restaurant Analytics

An end-to-end data analytics capstone project built on the [Zomato Bangalore Restaurants dataset](https://www.kaggle.com/datasets/absin7/zomato-bangalore-restaurants), covering data cleaning, SQL analysis, and a Power BI dashboard.

**Status:** Phase 1 ✅ | Phase 2 ✅ | Phase 3 (Power BI) in progress

---

## Project Structure

zomato-bangalore-analytics/
├── data/
│ ├── zomato_clean.csv # cleaned, deduplicated restaurant data (12,382 rows)
│ └── orders.csv # synthetic orders table (20,000 rows)
├── sql/
│ └── phase2_queries.sql # all 20 Phase 2 SQL queries
├── zomato_bangalore.db # SQLite DB: restaurants, orders, merged_orders view
└── README.md


---

## Phase 1: Data Acquisition & Cleaning

**Source data:** Kaggle's Zomato Bangalore dataset — 51,717 raw rows, 17 columns.

### Key cleaning steps
- Dropped unusable columns (`url`, `phone`, `reviews_list`, `menu_item`, `dish_liked` — 54%+ missing)
- Parsed `rate` (`"4.1/5"` → `4.1`) via regex, explicitly treating `'NEW'` and `'-'` as **no rating** rather than imputing a fake average — avoids biasing rating analysis toward the mean
- Cleaned `approx_cost(for two people)` (stripped comma formatting, cast to float)
- **Diagnosed and fixed row-duplication**: the raw dataset repeats each physical restaurant once per `listed_in(type)` category (Delivery, Dine-out, Buffet, etc.), inflating row count from 12,382 unique restaurants to 51,717 rows. Fixed via `groupby(["name","address"])` aggregation rather than a naive `drop_duplicates()`, preserving all listing-type info as a joined string.
- Assigned a clean sequential `restaurant_id` primary key

**Result:** `zomato_clean.csv` — 12,382 unique, cleaned restaurant records.

### Synthetic orders table

Since the source dataset has no transaction-level data, a synthetic `orders` table (20,000 rows) was generated and linked to real `restaurant_id`s, designed specifically to support Phase 2's analysis themes:

| Column | Purpose |
|---|---|
| order_id, restaurant_id, customer_id | keys |
| order_date, order_time | peak-hour / time-series analysis |
| order_value | scaled to each restaurant's real cost tier |
| delivery_time_mins | delivery performance by area (includes ~5% intentional outliers) |
| order_rating, delivery_status, payment_method | satisfaction & churn signals |

A fixed customer pool (6,000 customers) ensures repeat-customer behavior exists in the data — required for any churn analysis to be meaningful.

### Data quality checks (all passing)
- Zero orphaned foreign keys between `orders` and `restaurants`
- Zero nulls in required merge fields
- Zero invalid order values, delivery times, or rating ranges
- Zero duplicate order IDs

All data lives in `zomato_bangalore.db` (SQLite), with a `merged_orders` view joining both tables for direct querying in Phase 2.

---

## 📊 Phase 2: SQL Analysis (20 queries, 4 themes)

All queries run against the `merged_orders` SQLite view. Full query text in `sql/phase2_queries.sql`.

### 🍽️ Rating-to-Cost (Q1-3)
- Raw `rating/cost` ratio is a **misleading** value metric — it rewards ultra-cheap restaurants regardless of quality
- Fixed with tier-based ranking (Budget <₹300 / Mid ₹300-700 / Premium >₹700) using `RANK() OVER (PARTITION BY ...)`
- 💡 **Premium restaurants rate meaningfully higher** — 3.91 avg vs ~3.56 for Budget/Mid

### 📍 Underserved Localities (Q4-6)
- Restaurant supply ranges from **1 to 872** restaurants per locality (93 localities total)
- ⚠️ Synthetic order volume ≠ real demand signal (orders were randomly assigned) — excluded as misleading
- Fixed using real rating + minimum sample size (`HAVING COUNT(*) >= 5`)
- 💡 **Sankey Road (4.04★, 12 restaurants)** and **Koramangala 3rd Block (3.93★, 19 restaurants)** are the strongest underserved candidates

### 🚴 Delivery Time by Area (Q7-10)
- No real geographic delivery-time pattern once sample size is controlled — **honest null result**
- No relationship between order size and delivery time — **honest null result**
- 💡 Order value strongly tracks cost tier: ₹207 → ₹459 → ₹1,250 (Budget → Mid → Premium)

### 🔁 Churn & Peak Hours (Q11-15)
- 13% one-time customers = random-sampling baseline, **not a real churn signal**
- ✅ Peak-hour pattern (lunch 12-1pm, dinner 7-9pm) verified precisely — matches the ~35/45/20 designed split
- No weekday/weekend or loyalty-based timing differences

### 🌟 Cross-Cutting Insights (Q16-20) — real Kaggle signal
- Dessert/bakery cuisines rate **higher** (3.75-3.86) than mainstream North Indian combos (3.40-3.55)
- `online_order = Yes` → cheaper restaurants, slightly higher rated
- 🏆 **`book_table = Yes` is the single strongest predictor**: +0.55 rating, 7x more votes, much higher cost — bigger effect than online ordering
- That book_table effect flows through into synthetic order values too (₹445 → ₹1,366), via the shared cost variable

### Key analytical skill demonstrated
Throughout Phase 2, findings were validated against **how the underlying data was generated** before being reported — several apparent "patterns" (locality delivery times, order-size vs delivery time, weekday/weekend spend) were correctly identified as sampling noise rather than real effects, and reported as honest null results instead of manufactured insights.

---

## Tech Stack

- **Python / pandas** — cleaning & transformation
- **SQLite** — relational storage & querying, window functions, CTEs
- **Power BI** — dashboard (Phase 3)
- **Google Colab** — development environment

---

## Coming Next

- **Phase 3:** 4-page Power BI dashboard (city overview, cuisine trends, delivery performance, restaurant leaderboard)
