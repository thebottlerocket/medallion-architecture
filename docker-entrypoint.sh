#!/usr/bin/env bash
set -euo pipefail

echo "Medallion Architecture MVP - Docker Execution"
echo "=================================================="
echo "Python: $(python --version)"
echo "Working directory: $(pwd)"
echo ""

echo "Installing dbt packages..."
dbt deps || echo "Package installation failed, continuing..."

echo ""
echo "STEP 1: Loading raw data (Bronze layer)..."
dbt seed
if [ $? -eq 0 ]; then
    echo "Raw data loaded successfully"
else
    echo "Raw data loading failed"
    exit 1
fi

echo ""
echo "STEP 2: Building models (Silver & Gold layers)..."
dbt run
if [ $? -eq 0 ]; then
    echo "All models built successfully"
else
    echo "Model building failed"
    exit 1
fi

echo ""
echo "STEP 3: Running data quality tests..."
dbt test --store-failures
if [ $? -eq 0 ]; then
    echo "All tests passed"
    test_status="All tests passed"
else
    echo "⚠ Some tests failed (check details above)"
    test_status="Some tests failed"
fi

echo ""
echo "=================================================="
echo "PIPELINE COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo "Results:"
echo "• Bronze Layer: Raw CSV data ingested and standardized"
echo "• Silver Layer: Business rules applied with survivorship logic"  
echo "• Gold Layer: Analytics-ready product master created"
echo "• Data Quality: $test_status"
echo ""
echo "Query your data using these table names:"
echo "  Bronze: main_bronze.stg_pos_item, main_bronze.stg_ecom_catalog"
echo "  Silver: main_silver.s_product_attributes, main_silver.s_product_keys"
echo "  Gold:   main_gold.dim_product_master, main_gold.v_product_master"
echo ""
echo "Your medallion architecture is ready for analytics!"
