# NorthStar Retail Co. — Multichannel Commercial Analytics

End-to-end analytics project: a synthetic multichannel retail database, SQL for
business questions, Python for data prep/enrichment, and a Power BI-ready data model.

GitHub: https://github.com/DatawithRS/multichannel-ecommerce-analytics
Findings dashboard (interactive): saved locally at `reports/dashboard.html` — open it in any browser.

## Scenario

NorthStar Retail Co. sells through 5 channels — **Online**, **Mobile App**,
**Marketplace** (3rd-party), **Retail Store** (10 physical locations), and
**Wholesale** (B2B) — across 10 product categories. Data covers Jan 2023 – Aug 2026.

## Folder structure

```
db/         schema.sql (DDL, 14 tables) + multichannel.db (SQLite, generated)
python/     generate_data.py (builds the DB), data_prep.py (SQL pull -> pandas -> Power BI export),
            build_dashboard_data.py (findings JSON), build_pbip.py (generates the .pbip project)
sql/        business_questions.sql — 14 labeled queries answering commercial questions
powerbi/    NorthStar.pbip + NorthStar.SemanticModel/ + NorthStar.Report/ (open directly in Power BI Desktop)
            NorthStar_PowerBI_Data.xlsx + csv/ (source data) + PowerBI_Guide.md (model + DAX + manual build option)
reports/    dashboard.html — standalone interactive findings dashboard (open in any browser)
```

## Database (`db/schema.sql`)

14 tables, dimensional (star-schema) model:

- **Dimensions:** `dim_channels`, `dim_customers`, `dim_stores`, `dim_employees`,
  `dim_suppliers`, `dim_categories`, `dim_products`, `dim_campaigns`
- **Facts:** `fact_orders`, `fact_order_items`, `fact_payments`, `fact_returns`,
  `fact_inventory`, `fact_campaign_performance`

Rebuild it any time with:
```
cd python && python generate_data.py
```

## SQL business questions (`sql/business_questions.sql`)

Revenue/AOV by channel, monthly trend, YoY growth, top products by margin, category
performance by channel, RFM inputs, new vs. returning revenue, return rate & refund
cost, campaign ROI, store performance, wholesale vs. retail margin, inventory reorder
risk, CLV by acquisition channel, cohort retention.

Run all of it: `sqlite3 db/multichannel.db < sql/business_questions.sql`

## Python data prep (`python/data_prep.py`)

Pulls from SQLite, applies a data-quality pass (clips bad discounts, drops orphaned
lines), then builds 6 analysis-ready marts:

- **RFM + segmentation** — quintile-scored, labeled into Champions / Loyal / At Risk /
  Hibernating / New / Needs Attention
- **Cohort retention matrix** — % of each signup-month cohort still buying N months later
- **Channel monthly performance**, **campaign ROI**, **returns summary**, **store performance**

Outputs `powerbi/NorthStar_PowerBI_Data.xlsx` and matching CSVs.

## Power BI

Two paths — see `powerbi/PowerBI_Guide.md` for full detail on both:

- **`powerbi/NorthStar.pbip`** — a generated Power BI Project (TMDL semantic model:
  14 tables, 13 relationships, ~13 DAX measures). I tested this by actually launching
  Power BI Desktop against it: found and fixed one real bug (a PBIR-format conflict),
  but it still doesn't bind cleanly to the semantic model on open, and I couldn't
  pin down the remaining cause with the tools available in this environment. Treat it
  as reviewable TMDL source, not a working file yet.
- **Manual build (proven)** — load `powerbi/NorthStar_PowerBI_Data.xlsx` via Get Data,
  wire up the relationships and DAX measures documented in the guide, ~20–30 minutes.
  This is the reliable path.

I can't drive the Power BI Desktop GUI directly — there's no CLI/API for arranging
report visuals — so the report canvas (dragging in charts, arranging pages) is a
manual step either way.

## Headline findings (from this data)

- **Wholesale dominates revenue** (~$26M, ~63% of the ~$41M multi-year total) on far
  fewer orders — high AOV, thinner unit margin. Digital channels (Online + Mobile App
  + Marketplace) are the volume drivers with more, smaller baskets.
- **Revenue is growing year over year** across the whole period, consistent with the
  built-in channel trends (Mobile App and Marketplace share is rising; Retail Store
  share is declining).
- **Customer base is barely a quarter "Champions"** (~13% of customers, ~21% of
  revenue) — a meaningful "Needs Attention" and "Hibernating" block exists worth a
  win-back campaign.
- **Campaign ROI varies widely by channel and offer type** — a few campaigns return
  8–15x spend, several run at a loss; ROI, not spend, should drive next quarter's budget
  reallocation.
- **Wholesale carries a disproportionate share of refund cost** relative to its order
  count, worth investigating (bulk-order defect or wrong-quantity risk).
