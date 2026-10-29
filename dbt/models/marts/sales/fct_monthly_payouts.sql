{{
  config(
    materialized='table',
    tags=['finance', 'commissions', 'sales']
  )
}}

/*
  Monthly compensation report by salesperson / role.
  Final output grain: payout_month × user_id × payout_role
*/

select
    payout_month,
    user_id,
    user_name,
    email,
    payout_role,
    count(distinct opportunity_id) as deals,
    sum(amount) as total_credited_amount,
    sum(payout_amount) as total_payout,
    sum(case when opportunity_type = 'New Business' then payout_amount else 0 end) as payout_new_business,
    sum(case when opportunity_type in ('Expansion', 'Upsell', 'Existing Business') then payout_amount else 0 end) as payout_expansion,
    sum(case when opportunity_type = 'Renewal' then payout_amount else 0 end) as payout_renewal
from {{ ref('fct_opportunity_payout_detail') }}
group by 1, 2, 3, 4, 5
order by payout_month desc, total_payout desc
