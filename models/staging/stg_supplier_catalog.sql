
{{ config(materialized='table') }}

select
  cast(supplier_sku as varchar)       as supplier_sku,
  nullif(supplier_name, '')           as supplier_name,
  cast(gtin as varchar)               as gtin,
  nullif(description, '')             as description,
  nullif(brand, '')                   as brand,
  try_cast(case_size as double)       as case_size,
  upper(nullif(case_uom, 'UNIT'))     as case_uom,
  'supplier'                          as source_system
from {{ ref('supplier_catalog') }}
