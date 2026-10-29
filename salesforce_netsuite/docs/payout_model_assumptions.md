# Monthly Opportunity Payout Model — Assumptions & Design

**Last updated**: 2026-10-28

## Join Strategy

Salesforce and NetSuite are joined on `internal_organization_id`:

- Salesforce Account has a custom field (`internal_organization_id__c`) that stores the shared key
- NetSuite usage revenue records also carry `internal_organization_id`
- This allows attribution of usage revenue to the Salesforce team that owns the account

## Commission Basis

- **Who gets credit**: Salesforce Opportunity + OpportunityTeamMember (role + split)
- **How much**: NetSuite usage revenue (`usage_revenue_usd`) for that organization in the month
- **Rate**: Determined by Opportunity.Type (New Business / Expansion / Renewal) and payout role (AE / AM / Support)

Salesforce `amount_usd` is retained for reference but is **not** used in the payout calculation.

## Naming Conventions

All columns use `snake_case` with explicit units where relevant:

- `amount_usd`
- `usage_revenue_usd`
- `payout_amount_usd`
- `is_won`
- `is_closed`
- `split_pct`
- `internal_organization_id`

## Rate Card (placeholders)

| Role | New Business | Expansion | Renewal |
|------|--------------|-----------|---------|
| AE   | 10%          | 7%        | 3%      |
| AM   | 0%           | 7%        | 2%      |
| Support (overlay) | 1.5% | 1.5% | 1.5% |

## Placeholders to Adjust

| Item | Location | What to change |
|------|----------|----------------|
| Salesforce Account custom field | `stg_salesforce__account.sql` | `internal_organization_id__c` |
| NetSuite source table name | `sources.yml` + `stg_netsuite__usage_revenue.sql` | `usage_revenue` |
| NetSuite column names | `stg_netsuite__usage_revenue.sql` | `customer_id`, `internal_organization_id`, `amount`, `transaction_date` |
