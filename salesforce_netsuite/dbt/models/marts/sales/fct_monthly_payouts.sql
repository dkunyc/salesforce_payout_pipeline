{{
  config(
    materialized='table',
    tags=['finance', 'commissions', 'sales']
  )
}}

/*
  Final monthly compensation report.
  Commission is based on NetSuite usage revenue, not Salesforce Opportunity amount.
*/

select
    payout_month,
    user_id,
    user_name,
    email,
    payout_role,
    count(distinct opportunity_id)              as deals,
    sum(usage_revenue_usd)                      as total_usage_revenue_usd,
    sum(payout_amount_usd)                      as total_payout_usd,
    sum(case when opportunity_type = 'New Business' then payout_amount_usd else 0 end) as payout_new_business_usd,
    sum(case when opportunity_type in ('Expansion', 'Upsell', 'Existing Business') then payout_amount_usd else 0 end) as payout_expansion_usd,
    sum(case when opportunity_type = 'Renewal' then payout_amount_usd else 0 end) as payout_renewal_usd
from {{ ref('fct_opportunity_payout_detail') }}
group by 1, 2, 3, 4, 5
order by payout_month desc, total_payout_usd desc
