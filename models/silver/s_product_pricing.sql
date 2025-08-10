
{{ config(materialized='table') }}

with current_pricing as (
  select *
  from {{ ref('stg_pricing') }}
  where is_current = true
),

aggregated as (
  select
    upc_gtin,
    max(case when channel = 'store' then price end) as price_store,
    max(case when channel = 'ecom' then price end) as price_ecom,
    current_timestamp as dbt_loaded_at,
    '{{ invocation_id }}' as dbt_run_id
  from current_pricing
  group by upc_gtin
)

select * from aggregated
