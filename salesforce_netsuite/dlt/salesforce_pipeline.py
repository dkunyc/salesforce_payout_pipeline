"""
dlt pipeline: Salesforce → Warehouse
Objects required for monthly salesperson compensation payouts:
  - Opportunity
  - OpportunityTeamMember
  - User

Run:
  python salesforce_pipeline.py
"""

import dlt
from dlt.sources.salesforce import salesforce_source


def load_salesforce() -> None:
    pipeline = dlt.pipeline(
        pipeline_name="salesforce_payout",
        destination="duckdb",          # change to snowflake / bigquery / etc.
        dataset_name="salesforce_raw",
    )

    # Only the objects needed for the payout model
    source = salesforce_source().with_resources(
        "opportunity",
        "opportunity_team_member",
        "user",
    )

    # Optional: incremental on SystemModstamp
    # source.opportunity.apply_hints(incremental=dlt.sources.incremental("system_modstamp"))

    load_info = pipeline.run(source)
    print(load_info)


if __name__ == "__main__":
    load_salesforce()
