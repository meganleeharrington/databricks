# KPI Trust Lab

**Team:** Databrick-by-Databrick

**Team Members:** Michael Bellamy, Vick Patel, and Megan Harrington

## Purpose

This project demonstrates how an organization can establish confidence in their data using governed metric definitions. We created a fictional company with multiple departments, each using reasonable yet conflicting definitions for Revenue, Active Customers, and Conversion Rate. We show how this company can replace ambiguous labels with governed definitions using Unity Catalog metric views, and demonstrate the impact by comparing dashboard and Genie answers before and after governance.

## Data Source

The data comprises six tables: customers, subscriptions, invoices, product usage, leads, and opportunities. All organizations, people, transactions, and values in this dataset were generated and are entirely fictional, designed to represent the types of entities and transactions a typical business might encounter.

## What We Built and Why

One of the core challenges our clients face is creating metric definitions that are governed across multiple departments, each with their own understanding of key metrics. By using the Unity Catalog to create organization-wide metric definitions accessible to everyone, organizations can eliminate ambiguity and ensure consistency.

## How We Got There

**Process:** We generated synthetic data and metric definitions that are realistic for different departments in our fictional company. These varied definitions would produce different results for the same metric given our dataset.

**Implementation:** We uploaded these CSV files and metric definitions to Databricks using the Databricks drag-and-drop CSV upload tool—a straightforward process that allowed us to create tables immediately. One minor challenge: dates in one file didn't load correctly despite matching other date columns, but we resolved this with simple SQL transformations.

**Genie Integration:** We connected the data to a Genie Agent. The clear data labeling allowed the agent to immediately understand column relationships across tables without additional instructions. One challenge: training the agent to produce more complex outputs when asked simple questions. When requested to compare department definitions with governed definitions, the agent required direct conversation to update its behavior.

## Where Clients Need Support

While the process was fairly straightforward, clients would benefit from consultant verification that the agent was properly trained. This involves providing temporary access to broader data and definitions, and performing validation work that siloed organizations typically struggle to achieve independently.

## Future Directions

With three additional weeks, we would explore adding complexity to the dataset to understand how the Genie Agent handles edge cases and more intricate relationships.

## Project Structure

```
kpi-trust-lab/
├── README.md
├── data/
│   └── raw/
│       ├── customers.csv
│       ├── subscriptions.csv
│       ├── invoices.csv
│       ├── product_usage.csv
│       ├── leads.csv
│       ├── opportunities.csv
│       └── metric_definitions.csv
├── notebooks/
│   ├── 01_load_raw_data.py
│   ├── 02_validate_data.sql
│   ├── 03_create_business_views.sql
│   └── 04_create_metric_views.sql
├── dashboards/
│   └── kpi_trust_lab.lvdash.json
├── genie/
│   └── genie_instructions.md
├── docs/
│   └── metric_definitions.md
└── .gitignore
```
