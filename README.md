# Medallion Architecture MVP - Product Data Integration

A production-ready **Medallion Architecture** implementation for product data integration using **dbt** and **DuckDB**, containerized with **Docker** for consistent execution.

## Overview

This project demonstrates a complete **Bronze → Silver → Gold** data pipeline that consolidates product information from multiple sources into a unified product master dimension.

### Business Problem Solved
- **Data Fragmentation**: Product information scattered across POS, e-commerce, and supplier systems
- **Inconsistent Identifiers**: Different SKU/UPC formats across systems  
- **Data Quality Issues**: Missing, duplicate, or conflicting product attributes
- **Manual Integration**: Time-consuming manual processes to create unified views

### Solution Approach
- **Medallion Architecture**: Structured data processing with clear quality gates
- **Survivorship Rules**: Automated data conflict resolution based on source priority
- **Standardized Identifiers**: Unified UPC/GTIN matching across all sources
- **Automated Pipeline**: One-command execution with comprehensive testing

## Architecture

```
Raw CSV Files → Bronze (Staging) → Silver (Business Logic) → Gold (Analytics)
```

### **Bronze Layer (Staging)**
- **Purpose**: Data ingestion with basic cleansing and standardization
- **Models**: `stg_pos_item`, `stg_ecom_catalog`, `stg_supplier_catalog`, `stg_pricing`
- **Transformations**: Data type casting, null handling, column standardization

### **Silver Layer (Business Logic)**  
- **Purpose**: Business rules and data integration with survivorship logic
- **Models**: `s_product_keys`, `s_product_attributes`, `s_product_pricing`
- **Key Features**: 
  - Product key generation and standardization
  - Survivorship rules (ecom > pos > supplier for names, pos > ecom > supplier for categories)
  - Data lineage tracking with source system identification

### **Gold Layer (Analytics)**
- **Purpose**: Analytics-ready dimensional model for business intelligence
- **Models**: `dim_product_master`, `v_product_master`
- **Business Value**: Single source of truth for product data across all channels

## Data Flow Examples

This section shows how a single product flows through each layer of the medallion architecture, demonstrating the transformations at each stage.

### Raw Data (CSV Files)

**pos_item.csv:**
```csv
pos_sku,upc,name,brand,size,size_uom,category,subcategory,status
100001,041220007118,Whole Milk 1 Gallon,HEB,1,GAL,Dairy,Milk,ACTIVE
```

**ecom_catalog.csv:**
```csv
product_id,gtin,title,brand,net_content,net_uom,category,status
E001,041220007118,Organic Whole Milk - 1 Gallon,HEB,1,GAL,Beverages,ACTIVE
```

**supplier_catalog.csv:**
```csv
supplier_sku,gtin,description,brand
S123,041220007118,Grade A Whole Milk,HEB
```

### Bronze Layer (Standardization)

After bronze layer processing (`stg_pos_item`, `stg_ecom_catalog`, `stg_supplier_catalog`):

**stg_pos_item:**
```sql
pos_sku     | upc           | name                | brand | size_value | size_uom | category | source_system
100001      | 041220007118  | Whole Milk 1 Gallon| HEB   | 1.0        | GAL      | Dairy    | pos
```

**stg_ecom_catalog:**
```sql
ecom_sku | gtin          | title                          | brand | size_value | size_uom | category   | source_system
E001     | 041220007118  | Organic Whole Milk - 1 Gallon | HEB   | 1.0        | GAL      | Beverages  | ecom
```

**stg_supplier_catalog:**
```sql
supplier_sku | gtin          | description        | brand | source_system
S123         | 041220007118  | Grade A Whole Milk | HEB   | supplier
```

**Key Bronze Transformations:**
- UPC/GTIN forced to varchar (prevents scientific notation)
- Empty strings converted to NULL
- Size converted to numeric values
- Source system tracking added
- Column names standardized across systems

### Silver Layer (Survivorship)

After silver layer processing (`s_product_attributes`):

```sql
product_key | upc_gtin      | product_name                   | brand | category | size_value | size_uom | source_count
abc123def   | 041220007118  | Organic Whole Milk - 1 Gallon | HEB   | Dairy    | 1.0        | GAL      | 3
```

**Key Silver Transformations - Survivorship Rules Applied:**
- **Product Name**: Ecom wins ("Organic Whole Milk - 1 Gallon" vs "Whole Milk 1 Gallon")
- **Category**: POS wins ("Dairy" vs "Beverages") - POS has better category hierarchy
- **Master Key**: Generated stable hash key (abc123def) from UPC/GTIN
- **Source Count**: Shows data came from all 3 systems (3)
- **Conflict Resolution**: Automatic based on configured priority rules

**Survivorship Priority Rules:**
```yaml
# From dbt_project.yml
survivorship_rules:
  name_priority: ['ecom', 'pos', 'supplier']      # Ecom names are most descriptive
  category_priority: ['pos', 'ecom', 'supplier']  # POS categories are most accurate
  brand_priority: ['ecom', 'pos', 'supplier']     # Ecom brands are most consistent
```

### Gold Layer (Analytics-Ready)

After gold layer processing (`dim_product_master`):

```sql
product_key | upc_gtin      | product_name                   | brand | category | price_store | price_ecom | price_variance_pct | best_price | data_quality_status | source_count
abc123def   | 041220007118  | Organic Whole Milk - 1 Gallon | HEB   | Dairy    | 4.99        | 4.79       | 4.0               | 4.79       | Complete           | 3
```

**Key Gold Transformations - Business Intelligence Ready:**
- **Complete Product View**: All attributes and pricing in one record
- **Calculated Metrics**: Price variance between channels (4.0%)
- **Best Price**: Lowest available price across channels ($4.79)
- **Data Quality**: Completeness indicator ("Complete")
- **Cross-Channel Analytics**: Compare store vs ecom pricing
- **Audit Trail**: Full lineage from source systems

**Business Value Delivered:**
- **Single Source of Truth**: One record represents the complete product
- **Automated Conflict Resolution**: No manual intervention needed
- **Cross-Channel Insights**: Price comparison and variance analysis
- **Data Quality Monitoring**: Automatic completeness checking
- **Source Transparency**: Know exactly where each piece of data originated

## Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Data Processing** | dbt 1.10.7 | SQL-based transformations and testing |
| **Database** | DuckDB 1.1.3 | Fast analytical database for data processing |
| **Containerization** | Docker | Consistent, reproducible execution environment |
| **Data Quality** | dbt-expectations | Comprehensive data validation and testing |
| **Architecture** | Medallion Pattern | Structured bronze → silver → gold data flow |

## Project Structure

```
medallion-architecture/
├── Dockerfile                 # Container definition
├── docker-entrypoint.sh       # Pipeline execution script
├── dbt_project.yml            # dbt configuration
├── packages.yml               # dbt package dependencies
├── requirements.txt           # Python dependencies
├── models/                    # dbt models
│   ├── staging/              # Bronze layer models
│   ├── silver/               # Silver layer models  
│   ├── gold/                 # Gold layer models
│   └── schema.yml            # Model tests and documentation
├── seeds/                     # Sample CSV data
│   ├── pos_item.csv          # Point of sale items
│   ├── ecom_catalog.csv      # E-commerce catalog
│   ├── supplier_catalog.csv  # Supplier products
│   └── pricing.csv           # Product pricing
├── macros/                    # Reusable dbt macros
├── profiles/                  # dbt connection profiles
├── run-simple.bat            # Windows execution script
└── run-simple.sh             # Unix execution script
```

## Quick Start

### Prerequisites
- **Docker** installed and running
- **Git** for cloning the repository

### 1. Clone Repository
```bash
git clone https://github.com/thebottlerocket/medallion-architecture.git
cd medallion-architecture
```

### 2. Execute Pipeline

**Windows:**
```cmd
run-simple.bat
```

**Unix/Linux/MacOS:**
```bash
chmod +x run-simple.sh
./run-simple.sh
```

**Manual Commands:**
```bash
# Build the Docker image
docker build -t medallion-product-mvp .

# Run the complete pipeline
docker run --rm medallion-product-mvp
```

### 3. Expected Output
```
Medallion Architecture MVP - Docker Execution
==================================================
Bronze layer data loaded successfully
Silver and Gold layers created successfully  
Tests: Data validation completed
Your enterprise data platform is ready for business intelligence!
```

**Note**: The container exits after completion. To query the data interactively, use the command in the next section.

## Querying Results

### Option 1: Interactive Database Access (Recommended)
```bash
# Run pipeline AND stay in container for querying
docker run --rm -it medallion-product-mvp bash
```

This command:
1. Executes the complete medallion pipeline
2. Keeps the container running with a bash shell
3. Allows you to query the DuckDB database interactively

### Option 2: Pipeline Only (Default)
```bash
# Run pipeline and exit (no querying possible)
docker run --rm medallion-product-mvp
```

This command runs the pipeline and exits immediately.

### Sample Queries (Once in Interactive Mode)
```bash
# Start DuckDB CLI
duckdb target/duckdb.db

# Or run direct SQL queries
duckdb target/duckdb.db -c "SELECT * FROM main_gold.dim_product_master LIMIT 5;"
```

```sql
-- Gold Layer: Complete Product Master
SELECT * FROM main_gold.dim_product_master LIMIT 10;

-- Silver Layer: Product Attributes with Survivorship
SELECT * FROM main_silver.s_product_attributes LIMIT 10;

-- Bronze Layer: Cleaned Source Data
SELECT * FROM main_bronze.stg_pos_item LIMIT 10;
```

### Option 3: Persist Database Locally
```bash
# Mount target directory to persist DuckDB file
docker run --rm -v "$(pwd)/target:/app/target" medallion-product-mvp
```

## Data Quality & Testing

The pipeline includes **45 comprehensive tests** covering:

- **Schema Validation**: Not null, unique constraints, data type verification
- **Business Logic**: Accepted values, referential integrity, relationship tests  
- **Data Quality**: Range validation, regex pattern matching, completeness checks
- **Source Lineage**: Source system tracking and audit trails

## Sample Data

The project includes realistic sample data:
- **5 POS items** with UPC codes and product hierarchy
- **5 E-commerce products** with GTIN identifiers  
- **5 Supplier catalog entries** with manufacturer details
- **9 Pricing records** across store and e-commerce channels

## Configuration

### Survivorship Rules
Configured in `dbt_project.yml`:
```yaml
vars:
  survivorship_rules:
    name_priority: ['ecom', 'pos', 'supplier']      # E-commerce names preferred
    category_priority: ['pos', 'ecom', 'supplier']  # POS categories preferred
    brand_priority: ['ecom', 'pos', 'supplier']     # E-commerce brands preferred
```

### Data Quality Thresholds
```yaml
vars:
  data_quality:
    max_price: 10000        # Maximum valid price
    min_price: 0            # Minimum valid price
    max_row_variance_pct: 20 # Maximum acceptable data variance
```

## Business Value

### Key Metrics
- **Data Integration**: 3 source systems → 1 unified product master
- **Data Quality**: 45 automated tests ensure data integrity
- **Performance**: Complete pipeline execution in <60 seconds
- **Scalability**: Container-based architecture supports horizontal scaling

### Use Cases
- **Product Information Management (PIM)**: Central product data repository
- **Business Intelligence**: Analytics-ready dimensional model
- **Data Governance**: Automated lineage and quality monitoring
- **API Services**: Unified product data for applications

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

