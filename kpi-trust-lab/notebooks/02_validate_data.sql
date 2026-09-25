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

-- COMMAND --

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

-- COMMAND --

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

-- COMMAND --

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

-- COMMAND --

DESCRIBE TABLE databrick_by_databrick.kpi_trust_lab.invoices;

-- COMMAND --

DESCRIBE TABLE databrick_by_databrick.kpi_trust_lab.subscriptions;

SELECT
    COUNT(*) AS total_rows,
    COUNT(invoice_date) AS valid_invoice_dates,
    COUNT(service_period_end) AS valid_service_period_dates,
    COUNT(payment_date) AS valid_payment_dates
FROM databrick_by_databrick.kpi_trust_lab.invoices;

-- COMMAND --
DESCRIBE TABLE
databrick_by_databrick.kpi_trust_lab.kpi_reconciliation_reference;

SELECT *
FROM databrick_by_databrick.kpi_trust_lab.kpi_reconciliation_reference;

-- COMPARISON --
WITH calculated AS (
    SELECT
        definition_owner,
        definition_name,
        reporting_month,
        CAST(revenue AS DECIMAL(18,2)) AS calculated_value
    FROM databrick_by_databrick.kpi_trust_lab
        .revenue_definition_comparison
),

reference AS (
    SELECT
        department AS definition_owner,
        CAST(value AS DECIMAL(18,2)) AS expected_value
    FROM databrick_by_databrick.kpi_trust_lab
        .kpi_reconciliation_reference
    WHERE LOWER(kpi_name) = 'revenue'
)

SELECT
    c.definition_owner,
    c.definition_name,
    DATE_FORMAT(c.reporting_month, 'MMMM yyyy')
        AS reporting_month,
    c.calculated_value,
    r.expected_value,
    CAST(
        c.calculated_value - r.expected_value
        AS DECIMAL(18,2)
    ) AS difference,
    CASE
        WHEN r.expected_value IS NULL THEN 'MISSING REFERENCE'
        WHEN c.calculated_value = r.expected_value THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM calculated c
LEFT JOIN reference r
    ON LOWER(c.definition_owner) = LOWER(r.definition_owner)
ORDER BY
    CASE c.definition_owner
        WHEN 'Finance' THEN 1
        WHEN 'Sales' THEN 2
        WHEN 'Product' THEN 3
        WHEN 'Governed' THEN 4
    END;

    -- REVIEW GOVERNED METRIC --
    WITH active_mrr AS (
    SELECT
        SUM(monthly_recurring_revenue) AS gross_recurring_revenue
    FROM databrick_by_databrick.kpi_trust_lab.subscriptions
    WHERE subscription_start_date <= DATE '2026-07-31'
      AND (
            churn_date IS NULL
            OR churn_date > DATE '2026-07-31'
          )
      AND subscription_status <> 'Trial'
),

allocated_refunds AS (
    SELECT
        SUM(
            CASE
                WHEN s.billing_frequency = 'Annual'
                    THEN COALESCE(i.refund_amount, 0) / 12
                ELSE COALESCE(i.refund_amount, 0)
            END
        ) AS allocated_refunds
    FROM databrick_by_databrick.kpi_trust_lab.invoices i
    INNER JOIN databrick_by_databrick.kpi_trust_lab.subscriptions s
        ON i.subscription_id = s.subscription_id
    WHERE i.service_period_end >= DATE '2026-07-01'
      AND i.service_period_end < DATE '2026-08-01'
)

SELECT
    CAST(a.gross_recurring_revenue AS DECIMAL(18,2))
        AS gross_recurring_revenue,
    CAST(r.allocated_refunds AS DECIMAL(18,2))
        AS allocated_refunds,
    CAST(
        a.gross_recurring_revenue - r.allocated_refunds
        AS DECIMAL(18,2)
    ) AS recognized_revenue
FROM active_mrr a
CROSS JOIN allocated_refunds r;

-- CORRECTION OF GOVERNED METRIC --
CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.governed_revenue_monthly
COMMENT 'Governed monthly subscription revenue based on active contracted MRR, net of refunds allocated to the reporting month.'
AS

WITH reporting_months AS (
    SELECT EXPLODE(
        SEQUENCE(
            DATE '2025-01-01',
            DATE '2026-07-01',
            INTERVAL 1 MONTH
        )
    ) AS reporting_month
),

active_mrr AS (
    SELECT
        m.reporting_month,
        SUM(s.monthly_recurring_revenue) AS gross_recurring_revenue
    FROM reporting_months m
    INNER JOIN databrick_by_databrick.kpi_trust_lab.subscriptions s
        ON s.subscription_start_date
            < ADD_MONTHS(m.reporting_month, 1)
       AND (
            s.churn_date IS NULL
            OR s.churn_date >= ADD_MONTHS(m.reporting_month, 1)
       )
       AND s.subscription_status <> 'Trial'
    GROUP BY m.reporting_month
),

allocated_refunds AS (
    SELECT
        CAST(DATE_TRUNC('MONTH', i.service_period_end) AS DATE)
            AS reporting_month,
        SUM(
            CASE
                WHEN s.billing_frequency = 'Annual'
                    THEN COALESCE(i.refund_amount, 0) / 12
                ELSE COALESCE(i.refund_amount, 0)
            END
        ) AS allocated_refunds
    FROM databrick_by_databrick.kpi_trust_lab.invoices i
    INNER JOIN databrick_by_databrick.kpi_trust_lab.subscriptions s
        ON i.subscription_id = s.subscription_id
    GROUP BY CAST(DATE_TRUNC('MONTH', i.service_period_end) AS DATE)
)

SELECT
    a.reporting_month,
    CAST(
        a.gross_recurring_revenue
        - COALESCE(r.allocated_refunds, 0)
        AS DECIMAL(18,2)
    ) AS revenue
FROM active_mrr a
LEFT JOIN allocated_refunds r
    ON a.reporting_month = r.reporting_month;

    -- CHECK COMPARISON AGAIN --
    SELECT
    definition_owner,
    definition_name,
    DATE_FORMAT(reporting_month, 'MMMM yyyy') AS reporting_month,
    CAST(revenue AS DECIMAL(18,2)) AS revenue
FROM databrick_by_databrick.kpi_trust_lab
    .revenue_definition_comparison
ORDER BY
    CASE definition_owner
        WHEN 'Finance' THEN 1
        WHEN 'Sales' THEN 2
        WHEN 'Product' THEN 3
        WHEN 'Governed' THEN 4
    END;