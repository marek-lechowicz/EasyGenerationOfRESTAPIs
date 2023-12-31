#!/bin/bash

# Recreate the database
echo "Restoring database...";
psql -U postgres -c "CREATE DATABASE dvdrental;";
pg_restore -U postgres --dbname=dvdrental --verbose ./dvdrental.tar;
echo "Database restored successfully!";

# Add no-login web_anon role
# echo "Adding web_anon role...";
psql --username postgres --dbname=dvdrental <<-EOSQL
	CREATE ROLE web_anon WITH NOLOGIN;
	GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO web_anon;
EOSQL
echo "web_anon role added successfully!";

