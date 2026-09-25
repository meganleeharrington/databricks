# Genie Instructions

## Overview
This file contains instructions for configuring and training the Genie Agent.

## Key Metrics
- Revenue
- Active Customers
- Conversion Rate

## Training Overview
- Agent should reference governed metric definitions from Unity Catalog
- When comparing definitions, provide: (1) governed definition, (2) department definition, (3) difference

## Training Instructions
When someone asks for a metric that is included in the metric definitions table, default to the governed metric definition. 

If someone asks for a specific department metric definition, first provide the governed metric definition. Then provide that department's definition. Then include the discrepancy between the two metrics in terms of raw numbers and percentage.
