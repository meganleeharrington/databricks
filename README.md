# Databricks Projects

This repository contains Databricks projects and implementations developed by The Information Lab team.

## Projects

### KPI Trust Lab

KPI Trust Lab demonstrates how organizations can resolve conflicting KPI definitions by creating governed enterprise metrics in Databricks.

**Team:** Databrick-by-Databrick  
**Team Members:** Michael Bellamy, Vick Patel, and Megan Harrington

#### Overview

Organizations often use the same KPI name for calculations that represent different business concepts. Revenue might refer to billed revenue, closed-won contract value, recurring run rate, or recognized revenue, depending on the department producing the report.

KPI Trust Lab uses a fictional B2B SaaS company to demonstrate this problem across three KPI families:

- Revenue
- Active customers
- Conversion rate

The project calculates the departmental definitions, reconciles the results, and establishes one certified enterprise definition for each KPI using Unity Catalog metric views. These governed measures are then reused in an AI/BI dashboard and a Genie Agent.

The objective is not to eliminate department-specific measures. It is to label them accurately and prevent different business concepts from being presented under the same KPI name.

#### Key Features

- **Synthetic data:** Reproducible fictional SaaS data covering customers, subscriptions, invoices, product usage, leads, opportunities, and metric definitions
- **Git-integrated development:** Source data, notebooks, documentation, and the dashboard are managed through a GitHub repository connected to a Databricks Git folder
- **Python ingestion:** Raw CSV files are loaded from the repository and written as managed Delta tables
- **Data validation:** Row counts, data types, table relationships, and expected KPI results are tested before the reporting layer is created
- **Departmental KPI views:** Finance, Sales, Product, Marketing, and Executive definitions are calculated separately
- **KPI reconciliation:** Calculated results are compared with reference values to identify discrepancies
- **Governed metrics:** Certified enterprise measures are defined through Unity Catalog metric views
- **AI/BI dashboard:** Departmental results, findings, and recommended enterprise definitions are presented as a consulting assessment
- **Genie Agent:** Business instructions, semantic metadata, example SQL, and trusted queries guide natural-language analysis

#### Architecture

```text
Repository CSV files
        ↓
Python ingestion notebook
        ↓
Managed Delta tables
        ↓
Validation and reconciliation
        ↓
Departmental business views
        ↓
Unity Catalog metric views
        ↓
AI/BI dashboard and Genie Agent
```

#### Quick Start

##### 1. Connect the repository to Databricks

Clone or connect this GitHub repository as a Databricks Git folder. Run the project from within the Git folder so the ingestion notebook can resolve the repository-relative data paths.

##### 2. Confirm the target catalog and schema

The notebooks are configured to use:

```text
databrick_by_databrick.kpi_trust_lab
```

Update the `catalog` and `schema` variables if your workspace uses different names.

The executing user requires permission to:

- Use the target catalog
- Create and use the target schema
- Create tables and views
- Use an appropriate SQL warehouse or compute resource

##### 3. Run the notebooks in sequence

1. `notebooks/01_load_raw_data.py`  
   Reads the CSV files from `data/raw/`, applies the required data types, and creates managed Delta tables.

2. `notebooks/02_validate_data.sql`  
   Validates row counts, table relationships, date coverage, data quality, and KPI reconciliation results.

3. `notebooks/03_create_business_views.sql`  
   Creates departmental comparison views and the governed source views used by the semantic layer.

4. `notebooks/04_create_metric_views.sql`  
   Creates Unity Catalog metric views for certified revenue, active-customer, and conversion measures.

##### 4. Review the dashboard

Open the Databricks AI/BI dashboard stored at:

```text
notebooks/KPI Trust Lab.lvdash.json
```

The dashboard presents:

- The business problem
- Departmental KPI results
- The definitions used by each department
- The recommended enterprise definitions
- The governed solution implemented through Unity Catalog

##### 5. Configure the Genie Agent

Use the materials in the `genie/` directory to configure the Genie Agent.

Configuration includes:

- Governed metric views as primary analytical sources
- Departmental comparison views for explaining conflicting results
- Business terminology and response instructions
- Example SQL for common questions
- Parameterized trusted queries for verified answers
- Tests using alternative natural-language phrasing

#### Project Structure

```text
kpi-trust-lab/
├── README.md
├── data/
│   ├── raw/                         # Synthetic source CSV files
│   └── reference/                   # KPI reconciliation reference data
├── notebooks/
│   ├── 01_load_raw_data.py
│   ├── 02_validate_data.sql
│   ├── 03_create_business_views.sql
│   ├── 04_create_metric_views.sql
│   └── KPI Trust Lab.lvdash.json   # Databricks AI/BI dashboard
├── genie/                           # Genie instructions and example queries
├── docs/                            # Supporting project documentation
└── .gitignore
```

#### Data Foundation

The raw data contains seven primary datasets:

- Customers
- Subscriptions
- Invoices
- Product usage
- Leads
- Opportunities
- Metric definitions

A separate reconciliation file contains the expected departmental and governed KPI results used during validation.

All organizations, people, transactions, and business results in the project are synthetic.

#### Governed KPI Definitions

The project establishes the following enterprise measures:

- **Recognized Subscription Revenue:** Active contracted monthly recurring value attributable to the reporting month, net of allocated refunds
- **Paying and Engaged Customers:** Customers with an active paid subscription and recent product engagement
- **Qualified Lead-to-Customer Conversion:** Qualified leads associated with a closed-won opportunity divided by all qualified leads in the reporting cohort

Departmental measures remain available under more precise names, such as closed-won ACV, run-rate ARR, recent payers, and opportunity win rate.

#### Key Deliverables

- Reproducible synthetic source data
- Python-based ingestion into managed Delta tables
- Data-quality and relationship validation
- KPI reconciliation tests
- Departmental business views
- Governed Unity Catalog metric views
- AI/BI dashboard
- Genie Agent instructions and trusted-query examples
- Git-managed Databricks project assets

#### What This Demonstrates

- Why conflicting KPI results can all be mathematically correct
- Why business terminology must be resolved before enabling conversational analytics
- How a semantic layer separates enterprise metrics from departmental measures
- How Unity Catalog metric views allow governed calculations to be defined once and reused
- How metadata, instructions, and example SQL improve Genie Agent reliability
- How Git supports collaboration and version control for Databricks project assets

#### Where Clients Benefit Most

This approach is particularly useful for organizations that:

- Report different values for KPIs with the same name
- Need consistent metrics across departments and reporting tools
- Are introducing self-service or conversational analytics
- Want governed definitions that can be traced to source data
- Need a repeatable process for testing and certifying business measures

---

For implementation details, see [kpi-trust-lab/README.md](kpi-trust-lab/README.md).
