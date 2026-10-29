{{
  config(
    materialized='view',
    tags=['intermediate']
  )
}}

/*
  Intermediate model: Salesforce credit (who + deal type)
  joined to NetSuite usage revenue on internal_organization_id.

  Grain: opportunity_id × user_id × revenue_month
  Commission is calculated on NetSuite usage_revenue_usd, not Opportunity.amount_usd.
*/

with closed_won as (
    select *
    from {{ ref('stg_salesforce__opportunity') }}
    where is_won = true
      and amount_usd > 0
      and close_date is not null
),

account_map as (
    select
        salesforce_account_id,
        internal_organization_id
    from {{ ref('stg_salesforce__account') }}
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

netsuite_revenue as (
    select
        internal_organization_id,
        revenue_month,
        sum(usage_revenue_usd) as usage_revenue_usd
    from {{ ref('stg_netsuite__usage_revenue') }}
    group by 1, 2
),

joined as (
    select
        cw.opportunity_id,
        cw.opportunity_name,
        cw.salesforce_account_id,
        am.internal_organization_id,
        cw.opportunity_type,
        cw.amount_usd                       as opportunity_amount_usd,
        cw.close_date,
        nr.revenue_month                    as payout_month,
        nr.usage_revenue_usd,
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
    inner join account_map am
        on am.salesforce_account_id = cw.salesforce_account_id
    inner join role_mapped rm
        on rm.opportunity_id = cw.opportunity_id
    inner join netsuite_revenue nr
        on nr.internal_organization_id = am.internal_organization_id
)

select
    *,
    usage_revenue_usd * split_pct * commission_rate as payout_amount_usd
from joined
where payout_role != 'Other'
  and commission_rate > 0
