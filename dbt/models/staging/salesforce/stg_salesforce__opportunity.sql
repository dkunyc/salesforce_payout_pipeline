{{
  config(
    materialized='view',
    tags=['staging', 'salesforce']
  )
}}

with source as (
    select * from {{ source('salesforce', 'opportunity') }}
),

renamed as (
    select
        id                              as opportunity_id,
        name                            as opportunity_name,
        accountid                       as account_id,
        amount,
        closedate                       as close_date,
        date_trunc('month', closedate)  as close_month,
        stagename                       as stage_name,
        type                            as opportunity_type,
        ownerid                         as owner_id,
        iswon,
        isclosed
    from source
)

select * from renamed
