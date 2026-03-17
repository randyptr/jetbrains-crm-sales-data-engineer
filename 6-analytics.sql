-- 6-analytics.sql — Part B: Analytical Queries
-- Creates two views for direct querying.

-- METRIC 1: MRR (Monthly Recurring Revenue)
-- Annual plans ($1200) are divided by 12 ($100/mo) and spread across every month they are active.
-- Monthly plans contribute $100 in their active month.
-- Only subscriptions with at least one successful payment are counted.
CREATE OR REPLACE VIEW dwh.mrr_by_month AS
WITH active_months AS (
    SELECT
        sub_id,
        customer_id,
        plan_type,
        monthly_revenue,
        active_month
    FROM dwh.fact_subscriptions,
    UNNEST(
        GENERATE_DATE_ARRAY(
            DATE_TRUNC(start_date, MONTH),
            DATE_TRUNC(COALESCE(end_date, CURRENT_DATE()), MONTH),
            INTERVAL 1 MONTH
        )
    ) AS active_month
    WHERE sub_id IN (
        SELECT DISTINCT sub_id
        FROM dwh.fact_transactions
        WHERE status = 'Success'
    )
),
mrr AS (
    SELECT
        active_month                        AS report_month,
        SUM(monthly_revenue)                AS mrr
    FROM active_months
    GROUP BY active_month
)
SELECT
    report_month,
    FORMAT_DATE('%Y-%m', report_month)      AS month_label,
    mrr
FROM mrr
ORDER BY report_month;

-- METRIC 2: Cumulative LTV (Lifetime Value) by Customer
-- Shows how each customer's spend grows month by month from their signup_date
CREATE OR REPLACE VIEW crm_dwh.cumulative_ltv_by_customer AS
WITH monthly_spend AS (
    SELECT
        ft.customer_id,
        dc.company_name,
        DATE_TRUNC(ft.tx_date, MONTH) AS spend_month,
        SUM(fs.monthly_revenue) AS revenue_this_month
    FROM crm_dwh.fact_transactions ft
    JOIN crm_dwh.fact_subscriptions fs
        ON ft.sub_id = fs.sub_id
    JOIN crm_dwh.dim_customers dc
        ON ft.customer_id = dc.customer_id
    WHERE ft.status = 'Success'
    GROUP BY
        ft.customer_id,
        dc.company_name,
        spend_month
)
SELECT
    customer_id,
    company_name,
    spend_month,
    FORMAT_DATE('%Y-%m', spend_month) AS month_label,
    revenue_this_month,
    SUM(revenue_this_month) OVER (
        PARTITION BY customer_id
        ORDER BY spend_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_ltv
FROM monthly_spend
ORDER BY customer_id, spend_month;
