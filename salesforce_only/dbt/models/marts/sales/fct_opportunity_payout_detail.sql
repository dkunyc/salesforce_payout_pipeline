{{
  config(
    materialized='table',
    tags=['finance', 'commissions', 'sales']
  )
}}

select
    payout_month,
    opportunity_id,
    opportunity_name,
    account_id,
    opportunity_type,
    amount,
    close_date,
    user_id,
    user_name,
    email,
    payout_role,
    team_member_role,
    split_pct,
    commission_rate,
    payout_amount
from {{ ref('int_opportunity_payouts') }}
