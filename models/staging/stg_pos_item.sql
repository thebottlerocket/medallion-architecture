
{{ config(materialized='table') }}

select
  cast(pos_sku as varchar)            as pos_sku,
  cast(upc as varchar)                as upc,
  nullif(name, '')                    as name,
  nullif(brand, '')                   as brand,
  try_cast(size as double)            as size_value,
  upper(nullif(size_uom, ''))         as size_uom,
  nullif(category, '')                as category,
  nullif(subcategory, '')             as subcategory,
  upper(nullif(status, 'ACTIVE'))     as status,
  'pos'                               as source_system
from {{ ref('pos_item') }}
