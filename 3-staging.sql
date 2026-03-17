-- 3-staging.sql — Staging Layer
-- Cleans and deduplicates raw CRM data.
-- Creates:
--   crm_dwh.stg_customers, removing NULL id/name rows
--   crm_dwh.stg_subscriptions, removing invalid plan types and NULL ids
--   crm_dwh.stg_transactions, removes invalid statuses and deduplicates
--   crm_dwh.dq_alerts, for logical errors logging that is found in raw data

-- stg_customers
CREATE OR REPLACE TABLE crm_dwh.stg_customers AS
SELECT
    customer_id,
    TRIM(company_name) AS company_name,
    TRIM(country) AS country,
    signup_date
FROM crm_dwh.raw_customers
WHERE customer_id IS NOT NULL
  AND company_name IS NOT NULL;

-- stg_subscriptions
CREATE OR REPLACE TABLE crm_dwh.stg_subscriptions AS
SELECT
    sub_id,
    customer_id,
    plan_type,
    start_date,
    end_date,
    amount
FROM crm_dwh.raw_subscriptions
WHERE sub_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND plan_type IN ('Monthly', 'Annual');

-- stg_transactions
CREATE OR REPLACE TABLE crm_dwh.stg_transactions AS
SELECT
    tx_id,
    sub_id,
    tx_date,
    status
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY sub_id, tx_date, status
            ORDER BY tx_id
        ) AS rn
    FROM crm_dwh.raw_transactions
    WHERE status IN ('Success', 'Failed', 'Refunded')
)
WHERE rn = 1;

-- dq_alerts — data quality issue log
CREATE OR REPLACE TABLE crm_dwh.dq_alerts (
    alert_id      INT64,
    check_name    STRING,
    source_table  STRING,
    record_id     INT64,
    description   STRING
);

-- DQ Check 1: tx_date before subscription start_date
INSERT INTO crm_dwh.dq_alerts
SELECT
    ROW_NUMBER() OVER () AS alert_id,
    'transaction_before_subscription_start' AS check_name,
    'raw_transactions' AS source_table,
    t.tx_id AS record_id,
    CONCAT(
        'tx_date (', CAST(t.tx_date AS STRING),
        ') is before start_date (', CAST(s.start_date AS STRING), ')'
    ) AS description
FROM crm_dwh.raw_transactions t
JOIN crm_dwh.raw_subscriptions s ON t.sub_id = s.sub_id
WHERE t.tx_date < s.start_date;

-- DQ Check 2: end_date before start_date
INSERT INTO crm_dwh.dq_alerts
SELECT
    (SELECT IFNULL(MAX(alert_id), 0) FROM crm_dwh.dq_alerts) + ROW_NUMBER() OVER () AS alert_id,
    'end_before_start' AS check_name,
    'raw_subscriptions' AS source_table,
    sub_id AS record_id,
    CONCAT(
        'end_date (', CAST(end_date AS STRING),
        ') is before start_date (', CAST(start_date AS STRING), ')'
    )                             AS description
FROM crm_dwh.raw_subscriptions
WHERE end_date IS NOT NULL
  AND end_date < start_date;

-- DQ Check 3: duplicate transactions detected
INSERT INTO crm_dwh.dq_alerts
SELECT
    (SELECT IFNULL(MAX(alert_id), 0) FROM crm_dwh.dq_alerts) + ROW_NUMBER() OVER () AS alert_id,
    'duplicate_transaction' AS check_name,
    'raw_transactions' AS source_table,
    tx_id AS record_id,
    CONCAT(
        'Duplicate slot (sub_id=', CAST(sub_id AS STRING),
        ', date=', CAST(tx_date AS STRING),
        ', status=', status, ')'
    ) AS description
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY sub_id, tx_date, status
            ORDER BY tx_id
        ) AS rn
    FROM crm_dwh.raw_transactions
    WHERE status IN ('Success', 'Failed', 'Refunded')
)
WHERE rn > 1;
