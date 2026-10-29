{{
  config(
    materialized='view',
    tags=['staging', 'salesforce']
  )
}}

with source as (
    select * from {{ source('salesforce', 'opportunity_team_member') }}
),

renamed as (
    select
        opportunityid                   as opportunity_id,
        userid                          as user_id,
        teammemberrole                  as team_member_role,
        coalesce(splitpercentage, 100) / 100.0 as split_pct
    from source
)

select * from renamed
