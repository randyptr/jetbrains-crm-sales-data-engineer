-- 1-schema.sql — Source Layer: Raw CRM Tables

CREATE SCHEMA IF NOT EXISTS crm_dwh;

-- Raw customers table
CREATE TABLE IF NOT EXISTS crm_dwh.raw_customers (
    customer_id   INT64,
    company_name  STRING,
    country       STRING,
    signup_date   DATE
);

-- Raw subscriptions table
CREATE TABLE IF NOT EXISTS crm_dwh.raw_subscriptions (
    sub_id       INT64,
    customer_id  INT64,
    plan_type    STRING,    -- 'Monthly' or 'Annual'
    start_date   DATE,
    end_date     DATE,      -- NULL if subscription is still active
    amount       NUMERIC    -- total price paid for the period
);

-- Raw transactions table
CREATE TABLE IF NOT EXISTS crm_dwh.raw_transactions (
    tx_id    INT64,
    sub_id   INT64,
    tx_date  DATE,
    status   STRING        -- 'Success', 'Failed', 'Refunded'
);
