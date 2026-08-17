# SQL schema and seed
                                                             	
This directory contains the authoritative SQL schema (sql/schema.sql) and seed data (sql/seed.sql) for the project.

Guidelines
- sql/schema.sql is the source of truth for the database DDL and is maintained manually.
- sql/seed.sql contains the initial data used for development/testing.

How to import locally
1. Create a test database (example):

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS decanet_test CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

2.Import the schema and seed:

```bash
mysql -u root -p decanet_test < sql/schema.sql
mysql -u root -p decanet_test < sql/seed.sql

3.Update schema version and stored procs :

mysql -u root -p decanet_test < sql/dc_version.sql
mysql -u root -p decanet_test < sql/dc_procs_mardb_ux.sql 


```bash
mysql -u root -p decanet_test < sql/schema.sql
mysql -u root -p decanet_test < sql/seed.sql


Quick checks:

```bash
mysql -u root -p decanet_test -e "SELECT COUNT(*) FROM abit;"
mysql -u root -p decanet_test -e "SELECT COUNT(*) FROM city;"


CI

A GitHub Actions workflow (.github/workflows/sql-import.yml) runs on pushes to sql/** and attempts to import the schema and seed into a temporary MySQL service to validate them.
Notes

You control and maintain sql/schema.sql; if you modify it, update seed.sql and consider running the CI locally first.