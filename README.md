Welcome to your new dbt project!

### Setup to run locally (using dbt Core)
- Create virtual environment and activate it
```
python3 -m venv .venv # create a virtual environment
```

- **NOTE:** This project uses Postgres as data warehouse. See [setup instructions](https://docs.getdbt.com/docs/core/connect-data-platform/postgres-setup) for other data warehouses.

- Install project `requirements.txt` into virtual environment:
    - in `requirements.txt`, replace `dbt-postgres` adapter package if not using Postgres
```
python3 -m pip install -r requirements.txt # install the project's requirements
# if above doesn't work, run without python3 -m...
pip install -r requirements.txt
```

- Setup `profiles.yml` to connect to data warehouse
    - DO NOT VERSION CONTROL SENSITIVE INFO! see [`profiles.yml` best practices](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles)
    - if not using Postgres, see [setup instructions](https://docs.getdbt.com/docs/core/connect-data-platform/postgres-setup) for other data warehouses

- (optional) Run `dbt debug`, expect final message `All checks passed!` 
    - ref: (dbt-labs/jaffle-shop)[https://github.com/dbt-labs/jaffle-shop/tree/main] project, project skeleton from results of "initialize project" in dbt Cloud

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [dbt community](https://getdbt.com/community) to learn from other analytics engineers
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
