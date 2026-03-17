-- 5-mart.sql — Data Mart Layer for reporting
-- Creates: crm_dwh.dm_sales_performance

-- dm_sales_performance
-- one row per subscription
-- includes: customer name, country, subscription duration, total successful payments
CREATE OR REPLACE TABLE crm_dwh.dm_sales_performance AS
SELECT
    fs.sub_id,
    fs.customer_id,
    dc.company_name AS customer_name,
    dc.country AS customer_country,
    fs.plan_type,
    fs.start_date,
    fs.end_date,
    fs.subscription_status,
    fs.subscription_duration_days,
    fs.amount AS total_amount,
    fs.monthly_revenue,
    COUNTIF(ft.status = 'Success') AS successful_payments,
    COUNTIF(ft.status = 'Failed') AS failed_payments,
    COUNTIF(ft.status = 'Refunded') AS refunded_payments
FROM crm_dwh.fact_subscriptions fs
JOIN crm_dwh.dim_customers dc
    ON fs.customer_id = dc.customer_id
LEFT JOIN crm_dwh.fact_transactions ft
    ON fs.sub_id = ft.sub_id
GROUP BY
    fs.sub_id,
    fs.customer_id,
    dc.company_name,
    dc.country,
    fs.plan_type,
    fs.start_date,
    fs.end_date,
    fs.subscription_status,
    fs.subscription_duration_days,
    fs.amount,
    fs.monthly_revenue;
