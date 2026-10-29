{{
  config(
    materialized='view',
    tags=['staging', 'salesforce']
  )
}}

/*
  Mapping table: Salesforce Account → internal_organization_id
  Adjust the source column names to match your actual Salesforce Account fields.
*/

with source as (
    select * from {{ source('salesforce', 'account') }}
),

renamed as (
    select
        id                              as salesforce_account_id,
        name                            as account_name,
        -- Replace with the actual custom field that stores the internal org id
        internal_organization_id__c     as internal_organization_id
    from source
    where internal_organization_id__c is not null
)

select * from renamed
