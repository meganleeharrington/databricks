# Databricks notebook source

# 01_load_raw_data.py
# Load synthetic CSV data into governed Delta tables.

import os
from pyspark.sql import functions as F

# COMMAND ----------

# Project configuration
catalog = "databrick_by_databrick"
schema = "kpi_trust_lab"

spark.sql(f"""
    CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}
    COMMENT 'Synthetic B2B SaaS data for the KPI Trust Lab'
""")

print(f"Schema ready: {catalog}.{schema}")

# COMMAND ----------

# Locate the CSV files relative to this notebook.
data_directory = os.path.abspath("../data/raw")
data_path = f"file:{data_directory}"

tables = [
    "customers",
    "subscriptions",
    "invoices",
    "product_usage",
    "leads",
    "opportunities",
    "metric_definitions"
]
date_columns = {
    "customers": [
        "created_date"
    ],
    "subscriptions": [
        "subscription_start_date",
        "churn_date"
    ],
    "invoices": [
        "invoice_date",
        "service_period_end",
        "payment_date"
    ],
    "product_usage": [
        "usage_month"
    ],
    "leads": [
        "lead_created_date",
        "mql_date",
        "qualified_date"
    ],
    "opportunities": [
        "opportunity_created_date",
        "close_date"
    ]
}

decimal_columns = {
    "subscriptions": [
        "monthly_recurring_revenue"
    ],
    "invoices": [
        "invoice_amount",
        "refund_amount"
    ],
    "opportunities": [
        "annual_contract_value"
    ]
}

integer_columns = {
    "product_usage": [
        "sessions",
        "queries",
        "dashboards_viewed",
        "genie_questions"
    ]
}
print(f"Reading files from: {data_path}")
print(f"Writing tables to: {catalog}.{schema}")

# COMMAND ----------

# Confirm that every expected CSV exists before overwriting any table.
missing_files = [
    f"{table_name}.csv"
    for table_name in tables
    if not os.path.exists(
        os.path.join(data_directory, f"{table_name}.csv")
    )
]

if missing_files:
    raise FileNotFoundError(
        "Missing required CSV files: "
        + ", ".join(missing_files)
        + f". Checked directory: {data_directory}"
    )

print("All required CSV files found.")

# COMMAND ----------

# Load each CSV and save it as a managed Delta table.
for table_name in tables:
    source_file = f"{data_path}/{table_name}.csv"
    target_table = f"{catalog}.{schema}.{table_name}"

    # Read everything as a string so data types are controlled explicitly.
    dataframe = (
        spark.read
        .option("header", True)
        .option("inferSchema", False)
        .csv(source_file)
    )

    # Convert date fields (handles both yyyy-MM-dd and M/d/yyyy formats).
    for column_name in date_columns.get(table_name, []):
        dataframe = dataframe.withColumn(
            column_name,
            F.coalesce(
                F.try_to_date(F.col(column_name), "yyyy-MM-dd"),
                F.try_to_date(F.col(column_name), "M/d/yyyy")
            )
        )

    # Convert financial measures.
    for column_name in decimal_columns.get(table_name, []):
        dataframe = dataframe.withColumn(
            column_name,
            F.col(column_name).cast("decimal(18,2)")
        )

    # Convert whole-number activity measures.
    for column_name in integer_columns.get(table_name, []):
        dataframe = dataframe.withColumn(
            column_name,
            F.col(column_name).cast("integer")
        )

    (
        dataframe.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", True)
        .saveAsTable(target_table)
    )

    row_count = spark.table(target_table).count()

    print(f"{target_table}: {row_count:,} rows")

# COMMAND ----------

# Load the supplied KPI reconciliation results as a QA reference table.
reference_directory = os.path.abspath("../data/reference")
reconciliation_file = os.path.join(
    reference_directory,
    "KPI_Reconciliation.csv"
)

if not os.path.exists(reconciliation_file):
    raise FileNotFoundError(
        f"Missing reconciliation file: {reconciliation_file}"
    )

reconciliation_dataframe = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv(f"file:{reconciliation_file}")
)

reconciliation_target = (
    f"{catalog}.{schema}.kpi_reconciliation_reference"
)

(
    reconciliation_dataframe.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", True)
    .saveAsTable(reconciliation_target)
)

reconciliation_count = spark.table(
    reconciliation_target
).count()

print(
    f"{reconciliation_target}: "
    f"{reconciliation_count:,} rows"
)