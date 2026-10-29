{{
  config(
    materialized='view',
    tags=['staging', 'netsuite']
  )
}}

/*
  Staging model for NetSuite usage-based revenue.
  Adjust column names to match the actual NetSuite object / SuiteQL result
  you load with dlt (invoice, revenue recognition, custom usage transaction, etc.).
*/

with source as (
    select * from {{ source('netsuite', 'usage_revenue') }}
),

renamed as (
    select
        -- Replace with the actual NetSuite account / customer identifier
        customer_id                     as netsuite_customer_id,
        -- Field that maps to the same internal_organization_id used in Salesforce
        internal_organization_id,
        transaction_date,
        date_trunc('month', transaction_date) as revenue_month,
        amount                          as usage_revenue_usd,
        currency
    from source
    where amount > 0
)

select * from renamed
