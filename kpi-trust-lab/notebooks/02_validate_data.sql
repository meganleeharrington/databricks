-- 02_validate_data.sql
-- Validate data quality and integrity across all tables

-- TODO: Add data validation queries

-- Databricks notebook source

WITH validation AS (

    SELECT
        'customers' AS table_name,
        COUNT(*) AS actual_rows,
        300 AS expected_rows
    FROM databrick_by_databrick.kpi_trust_lab.customers

    UNION ALL

    SELECT 'subscriptions', COUNT(*), 300
    FROM databrick_by_databrick.kpi_trust_lab.subscriptions

    UNION ALL

    SELECT 'invoices', COUNT(*), 2505
    FROM databrick_by_databrick.kpi_trust_lab.invoices

    UNION ALL

    SELECT 'product_usage', COUNT(*), 3093
    FROM databrick_by_databrick.kpi_trust_lab.product_usage

    UNION ALL

    SELECT 'leads', COUNT(*), 1200
    FROM databrick_by_databrick.kpi_trust_lab.leads

    UNION ALL

    SELECT 'opportunities', COUNT(*), 336
    FROM databrick_by_databrick.kpi_trust_lab.opportunities
)

SELECT
    table_name,
    actual_rows,
    expected_rows,
    CASE
        WHEN actual_rows = expected_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM validation
ORDER BY table_name;

-- COMMAND ----------

SELECT
    'customers.customer_id' AS key_test,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_keys,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_keys
FROM databrick_by_databrick.kpi_trust_lab.customers

UNION ALL

SELECT
    'subscriptions.subscription_id',
    COUNT(*),
    COUNT(DISTINCT subscription_id),
    SUM(CASE WHEN subscription_id IS NULL THEN 1 ELSE 0 END)
FROM databrick_by_databrick.kpi_trust_lab.subscriptions

UNION ALL

SELECT
    'invoices.invoice_id',
    COUNT(*),
    COUNT(DISTINCT invoice_id),
    SUM(CASE WHEN invoice_id IS NULL THEN 1 ELSE 0 END)
FROM databrick_by_databrick.kpi_trust_lab.invoices

UNION ALL

SELECT
    'leads.lead_id',
    COUNT(*),
    COUNT(DISTINCT lead_id),
    SUM(CASE WHEN lead_id IS NULL THEN 1 ELSE 0 END)
FROM databrick_by_databrick.kpi_trust_lab.leads

UNION ALL

SELECT
    'opportunities.opportunity_id',
    COUNT(*),
    COUNT(DISTINCT opportunity_id),
    SUM(CASE WHEN opportunity_id IS NULL THEN 1 ELSE 0 END)
FROM databrick_by_databrick.kpi_trust_lab.opportunities;

-- COMMAND ----------

SELECT
    COUNT(*) AS invoice_rows,
    COUNT(s.subscription_id) AS matched_subscriptions,
    COUNT(c.customer_id) AS matched_customers,
    CASE
        WHEN COUNT(*) = COUNT(s.subscription_id)
         AND COUNT(*) = COUNT(c.customer_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM databrick_by_databrick.kpi_trust_lab.invoices i
LEFT JOIN databrick_by_databrick.kpi_trust_lab.subscriptions s
    ON i.subscription_id = s.subscription_id
LEFT JOIN databrick_by_databrick.kpi_trust_lab.customers c
    ON i.customer_id = c.customer_id;

-- COMMAND ----------

SELECT
    COUNT(*) AS opportunity_rows,
    COUNT(l.lead_id) AS matched_leads,
    CASE
        WHEN COUNT(*) = COUNT(l.lead_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM databrick_by_databrick.kpi_trust_lab.opportunities o
LEFT JOIN databrick_by_databrick.kpi_trust_lab.leads l
    ON o.lead_id = l.lead_id;

-- COMMAND ----------

DESCRIBE TABLE databrick_by_databrick.kpi_trust_lab.invoices;

-- COMMAND ----------

DESCRIBE TABLE databrick_by_databrick.kpi_trust_lab.subscriptions;

SELECT
    COUNT(*) AS total_rows,
    COUNT(invoice_date) AS valid_invoice_dates,
    COUNT(service_period_end) AS valid_service_period_dates,
    COUNT(payment_date) AS valid_payment_dates
FROM databrick_by_databrick.kpi_trust_lab.invoices;