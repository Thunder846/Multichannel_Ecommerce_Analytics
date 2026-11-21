-- NorthStar Retail Co. — Multichannel Commercial Database
-- Star-schema style: dim_* tables describe entities, fact_* tables record events.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS fact_returns;
DROP TABLE IF EXISTS fact_payments;
DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS fact_orders;
DROP TABLE IF EXISTS fact_inventory;
DROP TABLE IF EXISTS fact_campaign_performance;
DROP TABLE IF EXISTS dim_campaigns;
DROP TABLE IF EXISTS dim_employees;
DROP TABLE IF EXISTS dim_products;
DROP TABLE IF EXISTS dim_categories;
DROP TABLE IF EXISTS dim_suppliers;
DROP TABLE IF EXISTS dim_stores;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_channels;

-- 1. Sales / acquisition channels
CREATE TABLE dim_channels (
    channel_id      INTEGER PRIMARY KEY,
    channel_name    TEXT NOT NULL,      -- Online, Mobile App, Marketplace, Retail Store, Wholesale
    channel_type    TEXT NOT NULL,      -- Digital / Physical / B2B
    launch_date     TEXT NOT NULL
);

-- 2. Customers
CREATE TABLE dim_customers (
    customer_id             INTEGER PRIMARY KEY,
    first_name              TEXT NOT NULL,
    last_name               TEXT NOT NULL,
    email                   TEXT NOT NULL,
    gender                  TEXT,
    birth_date              TEXT,
    city                    TEXT,
    state                   TEXT,
    country                 TEXT,
    signup_date             TEXT NOT NULL,
    acquisition_channel_id  INTEGER NOT NULL REFERENCES dim_channels(channel_id),
    customer_type           TEXT NOT NULL   -- Consumer / Business
);

-- 3. Store locations (physical footprint)
CREATE TABLE dim_stores (
    store_id     INTEGER PRIMARY KEY,
    store_name   TEXT NOT NULL,
    store_type   TEXT NOT NULL,   -- Flagship / Standard / Outlet / Warehouse
    city         TEXT,
    state        TEXT,
    region       TEXT,
    open_date    TEXT NOT NULL
);

-- 4. Employees / sales reps
CREATE TABLE dim_employees (
    employee_id   INTEGER PRIMARY KEY,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    role          TEXT NOT NULL,     -- Sales Associate / Store Manager / Account Manager (wholesale)
    store_id      INTEGER REFERENCES dim_stores(store_id),
    hire_date     TEXT NOT NULL
);

-- 5. Suppliers
CREATE TABLE dim_suppliers (
    supplier_id        INTEGER PRIMARY KEY,
    supplier_name      TEXT NOT NULL,
    country            TEXT,
    reliability_score  REAL   -- 0-100, on-time delivery score
);

-- 6. Product categories
CREATE TABLE dim_categories (
    category_id     INTEGER PRIMARY KEY,
    category_name   TEXT NOT NULL,
    department      TEXT NOT NULL
);

-- 7. Products
CREATE TABLE dim_products (
    product_id     INTEGER PRIMARY KEY,
    product_name   TEXT NOT NULL,
    category_id    INTEGER NOT NULL REFERENCES dim_categories(category_id),
    brand          TEXT,
    unit_cost      REAL NOT NULL,
    unit_price     REAL NOT NULL,
    supplier_id    INTEGER NOT NULL REFERENCES dim_suppliers(supplier_id),
    launch_date    TEXT NOT NULL,
    is_active      INTEGER NOT NULL DEFAULT 1
);

-- 8. Marketing campaigns
CREATE TABLE dim_campaigns (
    campaign_id     INTEGER PRIMARY KEY,
    campaign_name   TEXT NOT NULL,
    channel_id      INTEGER NOT NULL REFERENCES dim_channels(channel_id),
    campaign_type   TEXT NOT NULL,  -- Promotion / Awareness / Retention / Seasonal
    start_date      TEXT NOT NULL,
    end_date        TEXT NOT NULL,
    budget          REAL NOT NULL
);

-- 9. Daily campaign performance (spend/clicks/impressions)
CREATE TABLE fact_campaign_performance (
    perf_id        INTEGER PRIMARY KEY,
    campaign_id    INTEGER NOT NULL REFERENCES dim_campaigns(campaign_id),
    perf_date      TEXT NOT NULL,
    impressions    INTEGER NOT NULL,
    clicks         INTEGER NOT NULL,
    spend          REAL NOT NULL
);

-- 10. Orders (header)
CREATE TABLE fact_orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES dim_customers(customer_id),
    channel_id      INTEGER NOT NULL REFERENCES dim_channels(channel_id),
    store_id        INTEGER REFERENCES dim_stores(store_id),        -- NULL for pure digital orders
    employee_id     INTEGER REFERENCES dim_employees(employee_id),  -- NULL for self-service digital orders
    campaign_id     INTEGER REFERENCES dim_campaigns(campaign_id),  -- attribution, nullable
    order_date      TEXT NOT NULL,
    ship_date       TEXT,
    order_status    TEXT NOT NULL,   -- Completed / Cancelled / Pending
    payment_method  TEXT NOT NULL
);

-- 11. Order line items
CREATE TABLE fact_order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES fact_orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES dim_products(product_id),
    quantity        INTEGER NOT NULL,
    unit_price      REAL NOT NULL,
    discount_pct    REAL NOT NULL DEFAULT 0,
    line_total      REAL NOT NULL
);

-- 12. Payments
CREATE TABLE fact_payments (
    payment_id      INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES fact_orders(order_id),
    payment_date    TEXT NOT NULL,
    amount          REAL NOT NULL,
    payment_status  TEXT NOT NULL   -- Paid / Refunded / Failed
);

-- 13. Returns
CREATE TABLE fact_returns (
    return_id       INTEGER PRIMARY KEY,
    order_item_id   INTEGER NOT NULL REFERENCES fact_order_items(order_item_id),
    return_date     TEXT NOT NULL,
    return_reason   TEXT NOT NULL,
    refund_amount   REAL NOT NULL
);

-- 14. Inventory snapshots (by product, by location, over time)
CREATE TABLE fact_inventory (
    inventory_id    INTEGER PRIMARY KEY,
    product_id      INTEGER NOT NULL REFERENCES dim_products(product_id),
    store_id        INTEGER NOT NULL REFERENCES dim_stores(store_id),
    snapshot_date   TEXT NOT NULL,
    stock_qty       INTEGER NOT NULL,
    reorder_level   INTEGER NOT NULL
);

CREATE INDEX idx_orders_customer ON fact_orders(customer_id);
CREATE INDEX idx_orders_channel ON fact_orders(channel_id);
CREATE INDEX idx_orders_date ON fact_orders(order_date);
CREATE INDEX idx_items_order ON fact_order_items(order_id);
CREATE INDEX idx_items_product ON fact_order_items(product_id);
CREATE INDEX idx_returns_item ON fact_returns(order_item_id);
CREATE INDEX idx_inventory_product_store ON fact_inventory(product_id, store_id);
CREATE INDEX idx_perf_campaign ON fact_campaign_performance(campaign_id);
