
{{ config(materialized='table') }}

select
  cast(ecom_sku as varchar)           as ecom_sku,
  cast(gtin as varchar)               as gtin,
  nullif(title, '')                   as title,
  nullif(brand, '')                   as brand,
  try_cast(net_content as double)     as size_value,
  upper(nullif(net_uom, ''))          as size_uom,
  nullif(category, '')                as category,
  upper(nullif(status, 'ACTIVE'))     as status,
  'ecom'                              as source_system
from {{ ref('ecom_catalog') }}
