CREATE VIEW 'databrick_by_databrick'.'default'.'metric_view'
(
    'Finance Revenue' COMMENT "Invoice amount less refunds for invoices issued in period",
    'Sales Revenue' COMMENT "Annual contract value for opportunities closed won in period",
    'Product Revenue' COMMENT "Month-end MRR for non-churned subscriptions multiplied by 12",
    'Governed Revenue' COMMENT "Monthly service value attributable to the reporting period, net of refunds",
    'Finance Active Customers' COMMENT "Distinct customers with a paid invoice in the trailing 90 days",
    'Sales Active Customers' COMMENT "Customer master status equals Active or Trial",
    'Product Active Customers' COMMENT "At least 3 sessions in reporting month",
    'Governed Active Customers' COMMENT "Active paid subscription and at least 1 session in trailing 60 days",
    'Marketing Conversion Rate' COMMENT "MQLs that created an opportunity divided by all MQLs created in cohort month",
    'Sales Conversion Rate' COMMENT "Closed-won opportunities divided by all closed opportunities in close month",
    'Executive Conversion Rate' COMMENT "Leads tied to a won customer divided by all leads created in cohort month",
    'Governed Conversion Rate' COMMENT "Qualified leads tied to a closed-won customer divided by qualified leads created in cohort month"
)

WITH METRICS
LANGUAGE YAML
AS $$
version: 1.0

source: databrick_by_databrick.default.leads
joins:
  - name: opportunities
    source: databrick_by_databrick.default.opportunities
    'on': 

dimensions:
  - name: 
    expr: 