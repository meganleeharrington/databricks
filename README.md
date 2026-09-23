# Databricks Projects

This repository contains Databricks projects and implementations developed by The Information Lab team.

## Projects

### KPI Trust Lab

A comprehensive demonstration of how organizations can establish confidence in their data using governed metric definitions through Unity Catalog.

**Team:** Databrick-by-Databrick  
**Team Members:** Michael Bellamy, Vick Patel, and Megan Harrington

#### Overview

This project showcases how to eliminate metric definition ambiguity across multiple departments using Databricks Unity Catalog. We created a realistic scenario where a fictional company's different departments (Sales, Finance, Operations) each use their own definitions for critical metrics like Revenue, Active Customers, and Conversion Rate. The project demonstrates the value of governed, organization-wide metric definitions and how they improve data confidence.

#### Key Features

- **Synthetic Dataset**: Realistic fictional company data across six tables
- **Department-Specific Definitions**: Multiple conflicting metric interpretations
- **Governed Metrics**: Unity Catalog metric views for organization-wide definitions
- **Genie Integration**: AI-powered querying with trained metric understanding
- **Comparative Analysis**: Before/after dashboards showing the impact of governance

#### Quick Start

1. Navigate to the `kpi-trust-lab/` folder
2. Upload the CSV files from `data/raw/` to Databricks
3. Run the notebooks in sequence:
   - `notebooks/01_load_raw_data.py` - Load data into tables
   - `notebooks/02_validate_data.sql` - Validate data quality
   - `notebooks/03_create_business_views.sql` - Create department-specific views
   - `notebooks/04_create_metric_views.sql` - Create governed metric definitions
4. Connect your data to Genie using `genie/genie_instructions.md`
5. Deploy the dashboard from `dashboards/kpi_trust_lab.lvdash.json`

#### Project Structure

```
kpi-trust-lab/
├── README.md                          # Project-specific documentation
├── data/raw/                          # Raw data files (CSV)
├── notebooks/                         # Databricks notebooks (Python & SQL)
├── dashboards/                        # Dashboards configuration
├── genie/                             # Genie Agent configuration
├── docs/                              # Project documentation
└── .gitignore
```

#### Key Deliverables

- **Metric Definitions**: Governed vs. department-specific comparisons in `docs/metric_definitions.md`
- **Data Foundation**: Seven CSV files providing synthetic business data
- **Analysis Notebooks**: End-to-end workflow from raw data to governed metrics
- **Dashboard**: Visual comparison of metrics before and after governance
- **Genie Training**: Agent configuration for intelligent metric queries

#### What Makes This Valuable

- **Solves Real Problem**: Addresses the common challenge of metric definition ambiguity in organizations
- **Practical Approach**: Uses Databricks' native tools (Unity Catalog, Genie, Dashboards)
- **Measurable Impact**: Demonstrates tangible improvements through before/after comparisons
- **Scalable Solution**: Approach can be applied to larger datasets and more complex organizations

#### Where Clients Benefit Most

Organizations looking to implement metric governance would benefit from:
- Consultant verification of agent training
- Validation across more complex data relationships
- Extension to larger datasets with multiple departments

---

**For more information on the KPI Trust Lab project, see [kpi-trust-lab/README.md](kpi-trust-lab/README.md)**
