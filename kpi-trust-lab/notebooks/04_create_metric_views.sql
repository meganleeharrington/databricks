-- 04_create_metric_views.sql
-- Create governed metric views using Unity Catalog

-- TODO: Add metric view definitions

DESCRIBE TABLE
databrick_by_databrick.kpi_trust_lab.kpi_reconciliation_reference;

DESCRIBE TABLE
databrick_by_databrick.kpi_trust_lab.metric_definitions;

-- COMMAND ----------
-- Test Metric Definitions --
SELECT
    r.kpi_name,
    r.department AS definition_owner,
    r.definition_name,
    r.value AS expected_value,
    r.unit,
    r.status,
    d.business_rule,
    d.time_basis,
    d.source_tables,
    d.governance_note
FROM databrick_by_databrick.kpi_trust_lab
    .kpi_reconciliation_reference r
LEFT JOIN databrick_by_databrick.kpi_trust_lab
    .metric_definitions d
    ON LOWER(r.kpi_name) = LOWER(d.kpi_name)
   AND LOWER(r.department) = LOWER(d.department)
   AND LOWER(r.definition_name) = LOWER(d.definition_name)
WHERE LOWER(r.kpi_name) IN (
    'active customers',
    'conversion rate'
)
ORDER BY
    r.kpi_name,
    CASE r.department
        WHEN 'Finance' THEN 1
        WHEN 'Sales' THEN 2
        WHEN 'Marketing' THEN 3
        WHEN 'Product' THEN 4
        WHEN 'Executive' THEN 5
        WHEN 'Governed' THEN 6
        ELSE 7
    END;

-- Active Customer Views --

-- Finance: customers with a paid invoice in the trailing 90 days.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .finance_active_customers_july_2026
COMMENT 'Finance active customers: distinct customers with a paid invoice in the trailing 90 days through July 31, 2026.'
AS

SELECT
    DATE '2026-07-31' AS snapshot_date,
    COUNT(DISTINCT customer_id) AS active_customers
FROM databrick_by_databrick.kpi_trust_lab.invoices
WHERE payment_date BETWEEN
      DATE_SUB(DATE '2026-07-31', 89)
      AND DATE '2026-07-31';

-- COMMAND ---

-- Sales: customers with an Active or Trial CRM master status.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .sales_active_customers_july_2026
COMMENT 'Sales active customers: customer master records with an Active or Trial CRM status.'
AS

SELECT
    DATE '2026-07-31' AS snapshot_date,
    COUNT(DISTINCT customer_id) AS active_customers
FROM databrick_by_databrick.kpi_trust_lab.customers
WHERE master_status IN ('Active', 'Trial');

-- COMMAND ---

-- Product: customers with at least three sessions in July.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .product_active_customers_july_2026
COMMENT 'Product active customers: customers with at least three product sessions during July 2026.'
AS

SELECT
    DATE '2026-07-31' AS snapshot_date,
    COUNT(DISTINCT customer_id) AS active_customers
FROM databrick_by_databrick.kpi_trust_lab.product_usage
WHERE usage_month = DATE '2026-07-01'
  AND sessions >= 3;

-- COMMAND ---

-- Governed: active paid subscription and product engagement
-- during the trailing 60-day period.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .governed_active_customers_july_2026
COMMENT 'Certified active customers: customers with an active paid subscription and at least one product session during the trailing 60 days through July 31, 2026.'
AS

WITH active_paid_subscriptions AS (
    SELECT DISTINCT customer_id
    FROM databrick_by_databrick.kpi_trust_lab.subscriptions
    WHERE subscription_start_date <= DATE '2026-07-31'
      AND (
            churn_date IS NULL
            OR churn_date > DATE '2026-07-31'
          )
      AND subscription_status <> 'Trial'
),

recently_engaged AS (
    SELECT DISTINCT customer_id
    FROM databrick_by_databrick.kpi_trust_lab.product_usage
    WHERE usage_month >= DATE_TRUNC(
              'MONTH',
              DATE_SUB(DATE '2026-07-31', 59)
          )
      AND usage_month <= DATE '2026-07-31'
      AND sessions >= 1
)

SELECT
    DATE '2026-07-31' AS snapshot_date,
    COUNT(DISTINCT s.customer_id) AS active_customers
FROM active_paid_subscriptions s
INNER JOIN recently_engaged e
    ON s.customer_id = e.customer_id;

-- COMMAND ---

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .active_customer_definition_comparison
COMMENT 'Comparison of departmental and certified active-customer definitions for July 2026.'
AS

SELECT
    'Finance' AS definition_owner,
    'Recent payer' AS definition_name,
    snapshot_date,
    active_customers AS value
FROM databrick_by_databrick.kpi_trust_lab
    .finance_active_customers_july_2026

UNION ALL

SELECT
    'Sales',
    'Active or trial master status',
    snapshot_date,
    active_customers
FROM databrick_by_databrick.kpi_trust_lab
    .sales_active_customers_july_2026

UNION ALL

SELECT
    'Product',
    '3+ sessions in month',
    snapshot_date,
    active_customers
FROM databrick_by_databrick.kpi_trust_lab
    .product_active_customers_july_2026

UNION ALL

SELECT
    'Governed',
    'Paying and engaged',
    snapshot_date,
    active_customers
FROM databrick_by_databrick.kpi_trust_lab
    .governed_active_customers_july_2026;

-- COMMAND --

SELECT *
FROM databrick_by_databrick.kpi_trust_lab
    .active_customer_definition_comparison
ORDER BY
    CASE definition_owner
        WHEN 'Finance' THEN 1
        WHEN 'Sales' THEN 2
        WHEN 'Product' THEN 3
        WHEN 'Governed' THEN 4
    END;

-- Conversation Rate Views --
-- COMMAND --

-- July lead cohort used by Marketing, Executive and Governed.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab.july_2026_lead_cohort
COMMENT 'Leads created during July 2026, enriched with associated opportunity outcomes.'
AS

SELECT
    l.lead_id,
    l.lead_created_date,
    l.mql_date,
    l.qualified_date,
    o.opportunity_id,
    o.stage,
    o.close_date
FROM databrick_by_databrick.kpi_trust_lab.leads l
LEFT JOIN databrick_by_databrick.kpi_trust_lab.opportunities o
    ON l.lead_id = o.lead_id
WHERE l.lead_created_date >= DATE '2026-07-01'
  AND l.lead_created_date < DATE '2026-08-01';

-- COMMAND ----------

-- Sales: Closed Won opportunities divided by all closed opportunities.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .sales_conversion_july_2026
COMMENT 'Sales conversion: July closed-won opportunities divided by all opportunities closed during July 2026.'
AS

SELECT
    DATE '2026-07-01' AS reporting_month,
    TRY_DIVIDE(
        COUNT(DISTINCT CASE
            WHEN stage = 'Closed Won' THEN opportunity_id
        END),
        COUNT(DISTINCT CASE
            WHEN stage IN ('Closed Won', 'Closed Lost')
                THEN opportunity_id
        END)
    ) AS conversion_rate
FROM databrick_by_databrick.kpi_trust_lab.opportunities
WHERE close_date >= DATE '2026-07-01'
  AND close_date < DATE '2026-08-01';

-- COMMAND ----------

-- Marketing: MQLs in the July lead cohort that created an
-- opportunity, divided by all MQLs in that cohort.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .marketing_conversion_july_2026
COMMENT 'Marketing conversion: July lead-cohort MQLs associated with an opportunity divided by all MQLs in the cohort.'
AS

SELECT
    DATE '2026-07-01' AS reporting_month,
    TRY_DIVIDE(
        COUNT(DISTINCT CASE
            WHEN mql_date IS NOT NULL
             AND opportunity_id IS NOT NULL
                THEN lead_id
        END),
        COUNT(DISTINCT CASE
            WHEN mql_date IS NOT NULL THEN lead_id
        END)
    ) AS conversion_rate
FROM databrick_by_databrick.kpi_trust_lab.july_2026_lead_cohort;

-- COMMAND ----------

-- Executive: all July leads that became customers,
-- divided by all leads created in July.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .executive_conversion_july_2026
COMMENT 'Executive conversion: July lead-cohort leads associated with a closed-won opportunity divided by all leads in the cohort.'
AS

SELECT
    DATE '2026-07-01' AS reporting_month,
    TRY_DIVIDE(
        COUNT(DISTINCT CASE
            WHEN stage = 'Closed Won' THEN lead_id
        END),
        COUNT(DISTINCT lead_id)
    ) AS conversion_rate
FROM databrick_by_databrick.kpi_trust_lab.july_2026_lead_cohort;

-- COMMAND --

-- Governed: qualified July leads that became customers,
-- divided by all qualified leads in the July cohort.

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .governed_conversion_july_2026
COMMENT 'Certified conversion: qualified July lead-cohort leads associated with a closed-won opportunity divided by all qualified leads in the cohort.'
AS

SELECT
    DATE '2026-07-01' AS reporting_month,
    TRY_DIVIDE(
        COUNT(DISTINCT CASE
            WHEN qualified_date IS NOT NULL
             AND stage = 'Closed Won'
                THEN lead_id
        END),
        COUNT(DISTINCT CASE
            WHEN qualified_date IS NOT NULL THEN lead_id
        END)
    ) AS conversion_rate
FROM databrick_by_databrick.kpi_trust_lab.july_2026_lead_cohort;

-- COMMAND ----------

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .conversion_definition_comparison
COMMENT 'Comparison of departmental and certified conversion-rate definitions for July 2026.'
AS

SELECT
    'Sales' AS definition_owner,
    'Closed opportunity win rate' AS definition_name,
    reporting_month,
    conversion_rate AS value
FROM databrick_by_databrick.kpi_trust_lab
    .sales_conversion_july_2026

UNION ALL

SELECT
    'Marketing',
    'MQL to opportunity',
    reporting_month,
    conversion_rate
FROM databrick_by_databrick.kpi_trust_lab
    .marketing_conversion_july_2026

UNION ALL

SELECT
    'Executive',
    'Lead to customer',
    reporting_month,
    conversion_rate
FROM databrick_by_databrick.kpi_trust_lab
    .executive_conversion_july_2026

UNION ALL

SELECT
    'Governed',
    'Qualified lead to customer',
    reporting_month,
    conversion_rate
FROM databrick_by_databrick.kpi_trust_lab
    .governed_conversion_july_2026;

-- COMMAND ----------

SELECT
    definition_owner,
    definition_name,
    DATE_FORMAT(reporting_month, 'MMMM yyyy') AS reporting_month,
    CAST(ROUND(value, 3) AS DECIMAL(10,3)) AS conversion_rate,
    CONCAT(
        CAST(ROUND(value * 100, 1) AS DECIMAL(10,1)),
        '%'
    ) AS display_rate
FROM databrick_by_databrick.kpi_trust_lab
    .conversion_definition_comparison
ORDER BY
    CASE definition_owner
        WHEN 'Sales' THEN 1
        WHEN 'Marketing' THEN 2
        WHEN 'Executive' THEN 3
        WHEN 'Governed' THEN 4
    END;

-- Governed Conversion Metric --

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .governed_revenue_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1

comment: >
  Certified subscription-revenue metrics. Revenue is based on
  active contracted monthly recurring value, net of refunds
  allocated to the reporting month.

source: databrick_by_databrick.kpi_trust_lab.governed_revenue_monthly

fields:
  - name: reporting_month
    expr: source.reporting_month
    display_name: Reporting Month
    comment: Month to which recognized subscription revenue is attributed.
    synonyms:
      - month
      - revenue month
      - service month

measures:
  - name: recognized_subscription_revenue
    expr: SUM(source.revenue)
    display_name: Recognized Subscription Revenue
    comment: >
      Certified monthly subscription revenue based on active
      contracted MRR, net of refunds allocated to the month.
    synonyms:
      - revenue
      - recognized revenue
      - subscription revenue
      - monthly revenue
$$;

-- COMMAND ----------

-- Governed Customer Metric View --

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .governed_customer_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1

comment: >
  Certified active-customer metrics. An active customer has
  an active paid subscription and at least one product session
  in the trailing 60 days.

source: databrick_by_databrick.kpi_trust_lab.governed_active_customers_july_2026

fields:
  - name: snapshot_date
    expr: source.snapshot_date
    display_name: Snapshot Date
    comment: Date on which active-customer status is evaluated.
    synonyms:
      - as of date
      - customer snapshot

measures:
  - name: paying_and_engaged_customers
    expr: MAX(source.active_customers)
    display_name: Paying and Engaged Customers
    comment: >
      Certified count of customers with an active paid
      subscription and recent product engagement.
    synonyms:
      - active customers
      - engaged customers
      - paying customers
      - customer count
$$;

-- COMMAND ----------
-- Governed Conversion Metric View  --

CREATE OR REPLACE VIEW
databrick_by_databrick.kpi_trust_lab
    .governed_conversion_metrics
WITH METRICS
LANGUAGE YAML
AS
$$
version: 1.1

comment: >
  Certified funnel-conversion metrics. Conversion is measured
  as qualified leads that become customers divided by all
  qualified leads in the reporting cohort.

source: databrick_by_databrick.kpi_trust_lab.governed_conversion_july_2026

fields:
  - name: reporting_month
    expr: source.reporting_month
    display_name: Cohort Month
    comment: Month in which the lead cohort was created.
    synonyms:
      - reporting month
      - lead month
      - cohort

measures:
  - name: qualified_lead_to_customer_conversion
    expr: MAX(source.conversion_rate)
    display_name: Qualified Lead-to-Customer Conversion
    comment: >
      Certified proportion of qualified cohort leads associated
      with a closed-won opportunity.
    synonyms:
      - conversion rate
      - qualified conversion
      - lead conversion
      - win conversion
$$;

-- COMMAND ----------
-- Test Revenue Metric View  --

SELECT
    reporting_month,
    MEASURE(recognized_subscription_revenue)
        AS recognized_subscription_revenue
FROM databrick_by_databrick.kpi_trust_lab
    .governed_revenue_metrics
WHERE reporting_month = DATE '2026-07-01'
GROUP BY reporting_month;

-- July --
SELECT
    DATE_FORMAT(reporting_month, 'MMMM yyyy')
        AS reporting_month,
    CAST(
        MEASURE(recognized_subscription_revenue)
        AS DECIMAL(18,2)
    ) AS recognized_subscription_revenue
FROM databrick_by_databrick.kpi_trust_lab
    .governed_revenue_metrics
WHERE reporting_month >= DATE '2026-07-01'
  AND reporting_month < DATE '2026-08-01'
GROUP BY reporting_month;

-- COMMAND ----------
-- Test Active Customer View ----------


SELECT
    DATE_FORMAT(snapshot_date, 'MMMM yyyy')
        AS reporting_month,
    MEASURE(paying_and_engaged_customers)
        AS paying_and_engaged_customers
FROM databrick_by_databrick.kpi_trust_lab
    .governed_customer_metrics
GROUP BY snapshot_date;

-- COMMAND ----------
-- Test Conversion View --

SELECT
     DATE_FORMAT(reporting_month, 'MMMM yyyy')
        AS reporting_month,
    CAST(
        ROUND(
            MEASURE(qualified_lead_to_customer_conversion),
            3
        ) AS DECIMAL(10,3)
    ) AS qualified_lead_to_customer_conversion
FROM databrick_by_databrick.kpi_trust_lab
    .governed_conversion_metrics
GROUP BY reporting_month;