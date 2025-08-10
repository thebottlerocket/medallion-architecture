
{{ config(
    materialized='table'
) }}

with attributes as (
  select * from {{ ref('s_product_attributes') }}
),

pricing as (
  select * from {{ ref('s_product_pricing') }}
),

final as (
  select
    -- Primary identifiers
    a.product_key,
    a.upc_gtin,
    
    -- Product information
    a.product_name,
    a.brand,
    a.size_value,
    a.size_uom,
    a.category,
    a.subcategory,
    a.is_active,
    
    -- Pricing information
    p.price_store,
    p.price_ecom,
    
    -- Calculated fields
    case 
      when p.price_store is not null and p.price_ecom is not null 
      then abs(p.price_store - p.price_ecom) / p.price_store * 100
      else null 
    end as price_variance_pct,
    
    case 
      when p.price_store is not null and p.price_ecom is not null
      then least(p.price_store, p.price_ecom)
      else coalesce(p.price_store, p.price_ecom)
    end as best_price,
    
    -- Data quality indicators
    case 
      when a.product_name is null then 'Missing Name'
      when a.brand is null then 'Missing Brand'
      when p.price_store is null and p.price_ecom is null then 'Missing Price'
      else 'Complete'
    end as data_quality_status,
    
    a.source_count,
    
    -- Audit fields
    a.dbt_loaded_at,
    a.dbt_run_id,
    current_timestamp as gold_processed_at
    
  from attributes a
  left join pricing p on p.upc_gtin = a.upc_gtin
)

select * from final
