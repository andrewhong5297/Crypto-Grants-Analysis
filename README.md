# Crypto Grants Analysis

Tracking and analyzing grants in the context of protocol activity. We want to aggregate grants data from across the ecosystem and then tie it to onchain metrics and KPIs in a Dune dashboard. Link to dashboard.

>*This repo was created [using this template](https://github.com/duneanalytics/DuneQueryRepo) to [manage your Dune queries](https://dune.mintlify.app/api-reference/crud/endpoint/create) and any [CSVs as Dune tables](https://dune.mintlify.app/api-reference/upload/endpoint/upload).*

### For Contributors

To add a grant, go to the `/uploads` folder and add a row onto an existing CSV sheet or create a new one. It will then get uploaded into Dune as a table. There is currently one CSV called `evm_grants.csv` that can be queried on Dune as `dune.cryptodatabytes.dataset_evm_grants`. The schema we're using for grants right now is below:

| Column Name | Type | Description |
| ----------- | ---- | ----------- |
| `grant_source` | varchar | name of the project/entity giving the grant |
| `grantee` | varchar | name of the project/entity recieving the grant |
| `dune_namespaces` | array(varchar) | namespace(s) of relevant decoded tables in Dune |
| `grant_date` | timestamp | date of grant confirmation/approval |
| `grant_token_address` | varbinary | address of the token that the grant is paid out in |
| `grant_amount` | double | amount of the token given in the grant |
| `grant_name` | varchar | name of grant cycle |
| `grant_type` | varchar | retroactive, proactive (you can suggest others too) |
| `grant_category` | varchar | purpose of the grant (growth, NFTs, creators, etc) |
| `grant_distribution` | varchar | how the grant is given to the grantee (claim, airdrop, farm, vesting) |
| `grant_blockchain` | varchar | blockchain that the grant was given out on |

I've set up four types of issues right now:
- `bugs`: This is for data quality issues like miscalculations or broken queries.
- `chart improvements`: This is for suggesting improvements to the visualizations.
- `query improvements`: This is for suggesting improvements to the query itself, such as adding an extra column or table that enhances the results.
- `generic questions`: This is a catch all for other questions or suggestions you may have about the dashboard.

If you want to contribute, either start an issue or go directly into making a PR (using the same labels as above). Once the PR is merged, the queries will get updated in the frontend.

### Query Management Scripts

You'll need python and pip installed to run the script commands. If you don't have a package manager set up, then use either [conda](https://www.anaconda.com/download) or [poetry](https://python-poetry.org/) . Then install the required packages:

```
pip install -r requirements.txt
```

| Script | Action                                                                                                                                                    | Command |
|---|-----------------------------------------------------------------------------------------------------------------------------------------------------------|---|
| `pull_from_dune.py` | updates/adds queries to your repo based on ids in `queries.yml`                                                                                           | `python scripts/pull_from_dune.py` |
| `push_to_dune.py` | updates queries to Dune based on files in your `/queries` folder                                                                                          | `python scripts/push_to_dune.py` |
| `preview_query.py` | gives you the first 20 rows of results by running a query from your `/queries` folder. Specify the id. This uses Dune API credits | `python scripts/preview_query.py 2615782` |
| `upload_to_dune.py` | uploads/updates any tables from your `/uploads` folder. Must be in CSV format, and under 200MB. | `python scripts/upload_to_dune.py` |