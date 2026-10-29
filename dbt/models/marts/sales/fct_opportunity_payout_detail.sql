{{
  config(
    materialized='table',
    tags=['finance', 'commissions', 'sales']
  )
}}

/*
  Detail-level payout model: one row per Opportunity × Person
  Grain: opportunity_id + user_id
  Uniqueness tested in schema.yml
*/

with closed_won as (
    select
        o.id                            as opportunity_id,
        o.name                          as opportunity_name,
        o.accountid                     as account_id,
        o.amount,
        o.closedate                     as close_date,
        date_trunc('month', o.closedate) as payout_month,
        o.type                          as opportunity_type,
        o.ownerid                       as owner_id
    from {{ source('salesforce', 'opportunity') }} o
    where o.stagename = 'Closed Won'
      and o.amount > 0
      and o.closedate is not null
),

team as (
    select
        otm.opportunityid               as opportunity_id,
        otm.userid                      as user_id,
        otm.teammemberrole              as team_member_role,
        coalesce(otm.splitpercentage, 100) / 100.0 as split_pct,
        u.name                          as user_name,
        u.email
    from {{ source('salesforce', 'opportunity_team_member') }} otm
    inner join {{ source('salesforce', 'user') }} u
        on u.id = otm.userid
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

rate_card as (
    select
        cw.opportunity_id,
        cw.opportunity_type,
        rm.payout_role,
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
    cross join (select distinct payout_role from role_mapped) rm
)

select
    cw.payout_month,
    cw.opportunity_id,
    cw.opportunity_name,
    cw.account_id,
    cw.opportunity_type,
    cw.amount,
    cw.close_date,
    rm.user_id,
    rm.user_name,
    rm.email,
    rm.payout_role,
    rm.team_member_role,
    rm.split_pct,
    rc.commission_rate,
    cw.amount * rm.split_pct * rc.commission_rate as payout_amount
from closed_won cw
inner join role_mapped rm
    on rm.opportunity_id = cw.opportunity_id
inner join rate_card rc
    on rc.opportunity_id = cw.opportunity_id
   and rc.payout_role = rm.payout_role
where rm.payout_role != 'Other'
  and rc.commission_rate > 0
