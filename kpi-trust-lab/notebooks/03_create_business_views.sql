-- 03_create_business_views.sql
-- Create business-layer views for different departments

-- TODO: Add view creation queries for department-specific definitions
-- Databricks notebook source

-- Finance definition:
-- Revenue means invoice value billed during the reporting month,
-- net of refunds recorded on those invoices.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.finance_revenue_monthly
COMMENT 'Finance view of revenue based on net invoice value billed during each month.'
AS

SELECT
    DATE_TRUNC('MONTH', invoice_date) AS reporting_month,
    SUM(invoice_amount - COALESCE(refund_amount, 0)) AS revenue
FROM databrick_by_databrick.kpi_trust_lab.invoices
GROUP BY DATE_TRUNC('MONTH', invoice_date);

-- COMMAND ----------

-- Sales definition:
-- Revenue means annual contract value for opportunities closed won.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.sales_revenue_monthly
COMMENT 'Sales view of revenue based on closed-won annual contract value. This is a bookings measure.'
AS

SELECT
    DATE_TRUNC('MONTH', close_date) AS reporting_month,
    SUM(annual_contract_value) AS revenue
FROM databrick_by_databrick.kpi_trust_lab.opportunities
WHERE stage = 'Closed Won'
  AND close_date IS NOT NULL
GROUP BY DATE_TRUNC('MONTH', close_date);

-- COMMAND ----------

-- Governed definition:
-- Revenue is attributed to the service period.
-- Annual invoices are allocated across twelve months.

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
        SUM(s.monthly_recurring_revenue)
            AS gross_recurring_revenue
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
        CAST(
            DATE_TRUNC('MONTH', i.service_period_end)
            AS DATE
        ) AS reporting_month,
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
    GROUP BY CAST(
        DATE_TRUNC('MONTH', i.service_period_end)
        AS DATE
    )
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

   -- Test --
   SELECT *
FROM databrick_by_databrick.kpi_trust_lab
    .governed_revenue_monthly
WHERE reporting_month = DATE '2026-07-01'; 

-- Test Comparison --
SELECT *
FROM databrick_by_databrick.kpi_trust_lab
    .revenue_definition_comparison
WHERE definition_owner = 'Governed';

-- COMMAND ----------

-- Product definition for the July 2026 demonstration:
-- Revenue means annualized recurring revenue from active,
-- non-trial subscriptions at the end of the month.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.product_revenue_july_2026
COMMENT 'Product view of July 2026 revenue based on annualized recurring revenue. This is a run-rate measure.'
AS

SELECT
    DATE '2026-07-01' AS reporting_month,
    SUM(monthly_recurring_revenue) * 12 AS revenue
FROM databrick_by_databrick.kpi_trust_lab.subscriptions
WHERE subscription_start_date <= DATE '2026-07-31'
  AND (
        churn_date IS NULL
        OR churn_date > DATE '2026-07-31'
      )
  AND subscription_status <> 'Trial';

-- COMMAND ----------

-- Bring the four definitions together for the conflict dashboard.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.revenue_definition_comparison
COMMENT 'Comparison of departmental and governed revenue definitions for July 2026.'
AS

SELECT
    'Finance' AS definition_owner,
    'Net billed revenue' AS definition_name,
    reporting_month,
    revenue
FROM databrick_by_databrick.kpi_trust_lab.finance_revenue_monthly
WHERE reporting_month = DATE '2026-07-01'

UNION ALL

SELECT
    'Sales',
    'Closed-won ACV',
    reporting_month,
    revenue
FROM databrick_by_databrick.kpi_trust_lab.sales_revenue_monthly
WHERE reporting_month = DATE '2026-07-01'

UNION ALL

SELECT
    'Product',
    'Run-rate ARR',
    reporting_month,
    revenue
FROM databrick_by_databrick.kpi_trust_lab.product_revenue_july_2026

UNION ALL

SELECT
    'Governed',
    'Recognized subscription revenue',
    reporting_month,
    revenue
FROM databrick_by_databrick.kpi_trust_lab.governed_revenue_monthly
WHERE reporting_month = DATE '2026-07-01';

-- COMMAND ----------

SELECT
    definition_owner,
    definition_name,
    DATE_FORMAT(reporting_month, 'MMMM yyyy') AS reporting_month,
    CAST(ROUND(revenue, 2) AS DECIMAL(18, 2)) AS revenue
FROM databrick_by_databrick.kpi_trust_lab.revenue_definition_comparison
ORDER BY
    CASE definition_owner
        WHEN 'Finance' THEN 1
        WHEN 'Sales' THEN 2
        WHEN 'Product' THEN 3
        WHEN 'Governed' THEN 4
    END;