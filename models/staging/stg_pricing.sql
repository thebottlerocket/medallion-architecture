
{{ config(materialized='view') }}

select
  product_upc as upc_gtin,
  case 
    when lower(channel) = 'store' then 'store'
    when lower(channel) = 'ecom' then 'ecom'
    else channel
  end as channel,
  price,
  current as is_current,
  valid_from,
  valid_to,
  current_timestamp as dbt_loaded_at,
  '{{ invocation_id }}' as dbt_run_id
from {{ ref('pricing') }}
