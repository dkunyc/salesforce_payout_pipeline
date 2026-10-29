# Monthly Opportunity Payout Model — Assumptions, Choices & Rate Rationale

**Pipeline**: dlt (Salesforce) → dbt  
**Final model**: `fct_monthly_payouts`  
**Last updated**: 2026-10-28

## Confirmed Assumptions

| Assumption | Decision |
|------------|----------|
| **Source objects** | Opportunity + OpportunityTeamMember + User (loaded by dlt) |
| **Deal type** | `Opportunity.Type` |
| **Role mapping** | TeamMemberRole → AE / AM / Support |
| **Credit** | `SplitPercentage` |
| **Timing** | Month of CloseDate |
| **Filter** | Closed Won + Amount > 0 |

## Rate Card (placeholders)

| Role | New Business | Expansion | Renewal |
|------|--------------|-----------|---------|
| AE   | 10%          | 7%        | 3%      |
| AM   | 0%           | 7%        | 2%      |
| Support (overlay) | 1.5% | 1.5% | 1.5% |

Rates are industry-standard placeholders based on 2025–2026 SaaS/AI benchmarks (Bridge Group, Scalerr, ICONIQ, ORM). Edit them in the `rate_card` CTE of `fct_opportunity_payout_detail.sql`.

## Model Layers

| Model | Grain | Purpose |
|-------|-------|---------|
| `fct_opportunity_payout_detail` | Opportunity × Person | Many-to-many bridge. Uniqueness tested on `(opportunity_id, user_id)`. |
| `fct_monthly_payouts` | Month × Person × Role | Final monthly compensation report. |
