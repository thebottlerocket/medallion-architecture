
{{ config(materialized='view') }}

select * from {{ ref('dim_product_master') }}
