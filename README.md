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

### Setup Data Warehouse and Elementary
- Load data into data warehouse
    - for BigQuery, Databricks, Redshift or Snowflake, see (guides)[https://courses.getdbt.com/courses/take/fundamentals/texts/43380412-setting-up-dbt-cloud-and-your-data-platform]
    - for Postgres,
        - create table in schema defined in `profiles.yml`
        ```
        CREATE TABLE "dbtSchema_Arthur20240304".raw_transactions
        (
            timestamp timestamp without time zone,
            transaction_id character(4),
            customer_id smallint
        );
        ```
        - insert data into created table
        ```
        INSERT INTO "dbtSchema_Arthur20240304".raw_transactions (timestamp, transaction_id, customer_id)
        VALUES
            ('2024-03-08 04:05:06', NULL, 1),
            ('2024-03-09 04:05:06', '1034', 25),
            ('2024-03-10 03:26:37', '1008', 3),
            ('2024-03-10 08:29:16', '0001', 4),
            ('2024-03-10 11:47:31', '0001', 4),
            ('2024-03-10 13:47:31', '0001', 4),
            ('2024-03-10 13:48:31', '0001', 4),
            ('2024-03-10 13:55:23', '0001', 4),
            ('2024-03-10 14:32:23', '0001', 4),
            ('2024-03-10 15:52:23', '0001', 4),
            ('2024-03-10 16:52:23', '0001', 4),
            ('2024-03-10 17:43:27', '0201', 13),
            ('2024-03-10 21:35:46', '2013', 37),
            ('2024-03-10 22:32:17', '0203', 58),
            ('2024-03-10 22:34:17', '0203', 58),
            ('2024-03-10 22:43:17', '0203', 58),
            ('2024-03-10 22:47:17', '0203', 58),
            ('2024-03-10 22:52:17', '0203', 58),
            ('2024-03-10 23:02:17', '0203', 58),
            ('2024-03-10 23:04:17', '0203', 58),
            ('2024-03-10 23:14:17', '0203', 58),
            ('2024-03-10 23:15:17', '0203', 58),
            ('2024-03-10 23:16:29', '0203', 58),
            ('2024-03-10 23:23:32', '0203', 58),
            ('2024-03-10 23:32:17', '0203', 58),
            ('2024-03-10 23:33:17', '0203', 58),
        ```

- In `models` folder,
    - create `schema.yml` that defines sources and models (optionally add tests for model's columns, and expect it to fail!)
    ```
    version: 2

    sources:
    - name: dbtSchema_Arthur20240304
        database: postgres
        schema: dbtSchema_Arthur20240304
        tables:
        - name: raw_transactions

    models:
        - name: fct_transactions
        description: "Fact table of transactions"
        columns:
            - name: transaction_id
                description: "The primary key for this table"
                tests:
                - unique
                - not_null
            - name: customer_id
                tests:
                - unique
    ```

    - create models e.g. fct_transactions.sql
    ```
    select *
    from {{ source('dbtSchema_Arthur20240304', 'raw_transactions')}}
    ```

- Run `dbt build` to run models and tests, or `dbt test` to run tests only

- Quickstart Elementary per (official guide)[https://docs.elementary-data.com/oss/quickstart/quickstart-cli-package]
    - when setting up `profiles.yml`, consider "'Least Privilege' Security Principal" test in next section

### Testing Elementary:
- ("Least Privilege" Security Principal, only needs dedicated role with read-only access to Elementary schema?)[https://docs.elementary-data.com/cloud/general/security-and-privacy]
    - how to create Postgres read-only role, for Elementary to connect?
    *instead of Group Role and Login Role, possible to directly grant Privileges to Login Role?*
        - create a Group Role
            - to have read-only Privilege to Elementary schema (and nothing else)
            - to be assigned to a Login Role, created in next step
        
        - grant Privileges to created Group Role:
            - `USAGE` on Elementary schema,
            - `SELECT` (i.e. read-only) on all tables/views in Elementary schema
        ```
        GRANT USAGE ON SCHEMA <Elementary schema name>
        TO <Group Role>;
        GRANT SELECT ON ALL TABLES IN SCHEMA <Elementary schema name>
        TO <Group Role>;
        ```
        e.g.
        ```
        GRANT USAGE ON SCHEMA "dbtSchema_Arthur20240304_elementary" 
        TO "read_dbtSchema_Arthur20240304_elementary";
        GRANT SELECT ON ALL TABLES IN SCHEMA "dbtSchema_Arthur20240304_elementary" 
        TO "read_dbtSchema_Arthur20240304_elementary";
        ```
        - solves error: # TODO fix having to re-grant after every dbt build and edr report?
        ```
        Encountered an error while running operation: Database Error
        permission denied for view <view name>
        ```
        - (optional)
            - `GRANT ... ALL TABLES` also affects views, per (docs)[https://www.postgresql.org/docs/current/sql-grant.html]
            - (docs on `REVOKE ALL`)[https://www.postgresql.org/docs/current/sql-revoke.html] to reverse `GRANT` e.g.
            ```
            REVOKE ALL ON ALL TABLES IN SCHEMA <Schema name> 
            FROM <Role>;
            ```
        
        - create a Login Role
            - make it a member of Group Role created earlier
            - use Role's `user` and `password` for `elementary` profile in `profiles.yml`
    
    - TEST: does `edr report` successfully generate a report, when
    `elementary` profile in `profiles.yml` only has `USAGE` privilege for Elementary schema, and only `SELECT` privileges on all tables/views in that schema, 
    without any access to all other schemas?
        - expected: yes
        - (optional) for Postgres, verify `elementary` profile indeed has no access to all other schemas, by creating a new connection in pgAdmin4 using that profile, and running SQL queries on other schemas. Expected `ERROR: permission denied`.

- (Anomaly detection tests)[https://docs.elementary-data.com/data-tests/introduction#anomaly-detection-tests]
    - For each test, data is split into `time buckets` (e.g. 23Mar, 24Mar etc.). For a certain metric (e.g. row count, freshness etc.) a.k.a. `data monitor`, buckets within `detection period` (i.e. more recent) are compared to buckets within `training period` (i.e. less recent). Test fails if anomalies detected, based on anomaly detection method (next).
    - (Anomaly detection method)[https://docs.elementary-data.com/data-tests/data-anomaly-detection] uses "standard score" a.k.a. "Z-score", representing no. of standard deviations of a value from (historical) average of a set of values
    - tried "Volume anomalies", statistics of anomaly detection method can be difficult and not intuitive, better-suited for more complex use-cases


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [dbt community](https://getdbt.com/community) to learn from other analytics engineers
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
