{{
  config(
    materialized='view',
    tags=['staging', 'salesforce']
  )
}}

with source as (
    select * from {{ source('salesforce', 'user') }}
),

renamed as (
    select
        id                              as user_id,
        name                            as user_name,
        email
    from source
)

select * from renamed
