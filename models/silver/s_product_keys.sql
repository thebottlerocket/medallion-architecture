
{{ config(materialized='table') }}

with keys as (
  select distinct upc as id from {{ ref('stg_pos_item') }}
  union
  select distinct gtin as id from {{ ref('stg_ecom_catalog') }}
  union
  select distinct gtin as id from {{ ref('stg_supplier_catalog') }}
), normalized as (
  select trim(id) as id from keys where id is not null
)
select
  id as natural_key,
  -- a stable surrogate key; duckdb has md5()
  md5(id) as product_key
from normalized
