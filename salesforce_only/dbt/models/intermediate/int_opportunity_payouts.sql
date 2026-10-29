{{
  config(
    materialized='view',
    tags=['intermediate']
  )
}}

/*
  Intermediate model: closed-won opportunities joined to team members
  with role mapping and commission rates applied.
  Grain: opportunity_id × user_id
*/

with closed_won as (
    select *
    from {{ ref('stg_salesforce__opportunity') }}
    where stage_name = 'Closed Won'
      and amount > 0
      and close_date is not null
),

team as (
    select
        otm.*,
        u.user_name,
        u.email
    from {{ ref('stg_salesforce__opportunity_team_member') }} otm
    inner join {{ ref('stg_salesforce__user') }} u
        on u.user_id = otm.user_id
),

role_mapped as (
    select
        t.*,
        case
            when lower(t.team_member_role) like '%account executive%'
              or lower(t.team_member_role) like '%ae%'
              or lower(t.team_member_role) = 'owner'
                then 'AE'
            when lower(t.team_member_role) like '%account manager%'
              or lower(t.team_member_role) like '%am%'
                then 'AM'
            when lower(t.team_member_role) like '%support%'
              or lower(t.team_member_role) like '%se%'
              or lower(t.team_member_role) like '%solutions%'
              or lower(t.team_member_role) like '%engineer%'
                then 'Support'
            else 'Other'
        end as payout_role
    from team t
),

with_rates as (
    select
        cw.opportunity_id,
        cw.opportunity_name,
        cw.account_id,
        cw.opportunity_type,
        cw.amount,
        cw.close_date,
        cw.close_month as payout_month,
        rm.user_id,
        rm.user_name,
        rm.email,
        rm.payout_role,
        rm.team_member_role,
        rm.split_pct,
        case
            when rm.payout_role = 'AE' and cw.opportunity_type = 'New Business' then 0.10
            when rm.payout_role = 'AE' and cw.opportunity_type in ('Expansion', 'Upsell', 'Existing Business') then 0.07
            when rm.payout_role = 'AE' and cw.opportunity_type = 'Renewal' then 0.03
            when rm.payout_role = 'AM' and cw.opportunity_type = 'New Business' then 0.00
            when rm.payout_role = 'AM' and cw.opportunity_type in ('Expansion', 'Upsell', 'Existing Business') then 0.07
            when rm.payout_role = 'AM' and cw.opportunity_type = 'Renewal' then 0.02
            when rm.payout_role = 'Support' then 0.015
            else 0.00
        end as commission_rate
    from closed_won cw
    inner join role_mapped rm
        on rm.opportunity_id = cw.opportunity_id
)

select
    *,
    amount * split_pct * commission_rate as payout_amount
from with_rates
where payout_role != 'Other'
  and commission_rate > 0
