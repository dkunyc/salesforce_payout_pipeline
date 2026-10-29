# Salesforce Monthly Payout Pipeline

End-to-end pipeline that:
1. Ingests the required Salesforce objects with **dlt**
2. Transforms them with **dbt** into a monthly compensation report by salesperson / role (AE / AM / Support)

## Folder structure

```
salesforce_payout_pipeline/
├── dlt/
│   ├── salesforce_pipeline.py      # dlt ingestion script
│   └── secrets.toml.example        # credential template
├── dbt/
│   └── models/
│       ├── sources.yml
│       └── marts/sales/
│           ├── fct_opportunity_payout_detail.sql
│           ├── fct_monthly_payouts.sql
│           └── schema.yml
├── docs/
│   └── payout_model_assumptions.md
└── requirements.txt
```

## Quick start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Configure Salesforce credentials
cp dlt/secrets.toml.example ~/.dlt/secrets.toml
# edit with real values

# 3. Run ingestion
cd dlt
python salesforce_pipeline.py

# 4. Run dbt models
cd ../dbt
dbt run --select fct_opportunity_payout_detail fct_monthly_payouts
dbt test
```

## Model layers

```
staging/
  stg_salesforce__opportunity
  stg_salesforce__opportunity_team_member
  stg_salesforce__user
        ↓
intermediate/
  int_opportunity_payouts          # role mapping + rates applied
        ↓
marts/sales/
  fct_opportunity_payout_detail    # Opportunity × Person
  fct_monthly_payouts              # Month × Person × Role  ← final report
```

Run the full DAG:

```bash
cd dbt
dbt run
dbt test
```

`fct_monthly_payouts` — one row per month × salesperson × role with:

- total payout
- breakdown by New Business / Expansion / Renewal
- deal count

## Assumptions & rates

See `docs/payout_model_assumptions.md` for the full list of confirmed assumptions, role mapping, and the industry-standard rate card used.
