"""
dlt pipeline: Salesforce + NetSuite → Warehouse

Loads:
  - Salesforce: Opportunity, OpportunityTeamMember, User, Account
  - NetSuite: usage revenue (via SuiteQL or REST record)

Run:
  python salesforce_netsuite_pipeline.py
"""

import dlt
from dlt.sources.salesforce import salesforce_source
from dlt.sources.rest_api import rest_api_source


def load_salesforce_and_netsuite() -> None:
    pipeline = dlt.pipeline(
        pipeline_name="salesforce_netsuite_payout",
        destination="duckdb",          # change to snowflake / bigquery / etc.
        dataset_name="raw",
    )

    # ------------------------------------------------------------------
    # Salesforce
    # ------------------------------------------------------------------
    sf_source = salesforce_source().with_resources(
        "opportunity",
        "opportunity_team_member",
        "user",
        "account",
    )

    # ------------------------------------------------------------------
    # NetSuite (SuiteTalk REST + SuiteQL)
    # Adjust the SuiteQL query and resource name to match your usage revenue object
    # ------------------------------------------------------------------
    netsuite_source = rest_api_source(
        {
            "client": {
                "base_url": "https://{{ACCOUNT_ID}}.suitetalk.api.netsuite.com/services/rest/",
                "auth": {
                    "type": "bearer",
                    "token": dlt.secrets["netsuite.access_token"],
                },
            },
            "resources": [
                {
                    "name": "usage_revenue",
                    "endpoint": {
                        "path": "query/v1/suiteql",
                        "method": "POST",
                        "json": {
                            "q": """
                                SELECT
                                    id,
                                    entity          AS customer_id,
                                    custbody_internal_org_id AS internal_organization_id,
                                    trandate        AS transaction_date,
                                    amount,
                                    currency
                                FROM transaction
                                WHERE type = 'CustInvc'
                                  AND amount > 0
                            """
                        },
                        "data_selector": "items",
                    },
                }
            ],
        }
    )

    load_info = pipeline.run([sf_source, netsuite_source])
    print(load_info)


if __name__ == "__main__":
    load_salesforce_and_netsuite()
