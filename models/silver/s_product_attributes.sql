
{{ config(
    materialized='table'
) }}

with source_data as (
  -- Union all sources with standardized columns and source indicators
  select 
    upc as upc_gtin,
    name as product_name,
    brand,
    size_value,
    size_uom,
    category,
    subcategory,
    status,
    'pos' as source_system,
    current_timestamp as dbt_loaded_at,
    '{{ invocation_id }}' as dbt_run_id
  from {{ ref('stg_pos_item') }}
  
  union all
  
  select 
    gtin as upc_gtin,
    title as product_name,
    brand,
    size_value,
    size_uom,
    category,
    null as subcategory,
    status,
    'ecom' as source_system,
    current_timestamp as dbt_loaded_at,
    '{{ invocation_id }}' as dbt_run_id
  from {{ ref('stg_ecom_catalog') }}
  
  union all
  
  select 
    gtin as upc_gtin,
    description as product_name,
    brand,
    null as size_value,
    null as size_uom,
    null as category,
    null as subcategory,
    'ACTIVE' as status,
    'supplier' as source_system,
    current_timestamp as dbt_loaded_at,
    '{{ invocation_id }}' as dbt_run_id
  from {{ ref('stg_supplier_catalog') }}
),

keys as (
  select * from {{ ref('s_product_keys') }}
),

survivorship as (
  select 
    k.product_key,
    k.natural_key as upc_gtin,
    
    -- Survivorship logic: ecom -> pos -> supplier
    coalesce(
      max(case when source_system = 'ecom' then product_name end),
      max(case when source_system = 'pos' then product_name end),
      max(case when source_system = 'supplier' then product_name end)
    ) as product_name,
    
    coalesce(
      max(case when source_system = 'ecom' then brand end),
      max(case when source_system = 'pos' then brand end),
      max(case when source_system = 'supplier' then brand end)
    ) as brand,
    
    -- Category: pos -> ecom -> supplier
    coalesce(
      max(case when source_system = 'pos' then category end),
      max(case when source_system = 'ecom' then category end),
      max(case when source_system = 'supplier' then category end)
    ) as category,
    
    -- Size information - prefer ecom then pos
    coalesce(
      max(case when source_system = 'ecom' then size_value end),
      max(case when source_system = 'pos' then size_value end)
    ) as size_value,
    
    coalesce(
      max(case when source_system = 'ecom' then size_uom end),
      max(case when source_system = 'pos' then size_uom end)
    ) as size_uom,
    
    -- Subcategory only from POS
    max(case when source_system = 'pos' then subcategory end) as subcategory,
    
    -- Active if any source shows active status
    case 
      when max(case when source_system = 'pos' and status != 'DISCONTINUED' then 1 else 0 end) = 1 then true
      when max(case when source_system = 'ecom' and status = 'ACTIVE' then 1 else 0 end) = 1 then true
      else false
    end as is_active,
    
    -- Metadata
    count(distinct source_system) as source_count,
    max(dbt_loaded_at) as dbt_loaded_at,
    max(dbt_run_id) as dbt_run_id
    
  from keys k
  left join source_data s on s.upc_gtin = k.natural_key
  group by k.product_key, k.natural_key
)

select * from survivorship
