-- 4-crm_dwh.sql — DWH Layer: Dimensional Model
-- Star schema built from staging tables
-- Creates:
--   crm_dwh.dim_customers
--   crm_dwh.dim_plans
--   crm_dwh.fact_subscriptions
--   crm_dwh.fact_transactions

-- dim_customers
CREATE OR REPLACE TABLE crm_dwh.dim_customers AS
SELECT
    customer_id,
    company_name,
    country,
    signup_date
FROM crm_dwh.stg_customers;

-- dim_plans, static lookup table
CREATE OR REPLACE TABLE crm_dwh.dim_plans (
    plan_type         STRING,
    billing_cycle     STRING,
    monthly_value     NUMERIC   -- normalized monthly revenue value
);

INSERT INTO crm_dwh.dim_plans VALUES
    ('Monthly', 'Every month',  100.00),
    ('Annual',  'Every year',   100.00);  -- $1200/12 = $100 per month

-- fact_subscriptions
CREATE OR REPLACE TABLE crm_dwh.fact_subscriptions AS
SELECT
    sub_id,
    customer_id,
    plan_type,
    start_date,
    end_date,
    amount,
    DATE_DIFF(
        COALESCE(end_date, CURRENT_DATE()),
        start_date,
        DAY
    ) AS subscription_duration_days,
    CASE
        WHEN end_date IS NULL THEN 'Active'
        ELSE 'Expired'
    END AS subscription_status,
    CASE
        WHEN plan_type = 'Annual'  THEN ROUND(amount / 12, 2)
        ELSE amount
    END AS monthly_revenue
FROM crm_dwh.stg_subscriptions;

-- fact_transactions
CREATE OR REPLACE TABLE crm_dwh.fact_transactions AS
SELECT
    t.tx_id,
    t.sub_id,
    t.tx_date,
    t.status,
    s.customer_id,
    s.start_date AS sub_start_date,
    s.plan_type
FROM crm_dwh.stg_transactions t
JOIN crm_dwh.stg_subscriptions s ON t.sub_id = s.sub_id;
