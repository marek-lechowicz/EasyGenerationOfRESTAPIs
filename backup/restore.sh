#!/bin/bash

# Recreate the database
echo "Restoring database...";
psql -U postgres -c "CREATE DATABASE dvdrental;";
pg_restore -U postgres --dbname=dvdrental --verbose ./dvdrental.tar;

echo "Adding web_anon role...";
psql --username postgres --dbname=dvdrental <<-EOSQL
	CREATE ROLE web_anon WITH NOLOGIN;
	GRANT ALL PRIVILEGES ON SCHEMA public TO web_anon;
	GRANT ALL PRIVILEGES ON public.film TO web_anon;
EOSQL

echo "Adding web_anon role...";
psql --username postgres --dbname=dvdrental <<-EOSQL
	CREATE ROLE actor_user WITH NOLOGIN;
	GRANT ALL PRIVILEGES ON SCHEMA public TO actor_user;
	GRANT ALL PRIVILEGES ON public.actor TO actor_user;
EOSQL

echo "Adding inventory_user role...";
psql --username postgres --dbname=dvdrental <<-EOSQL
	CREATE ROLE inventory_user WITH NOLOGIN;
	GRANT ALL PRIVILEGES ON SCHEMA public TO inventory_user;
	GRANT ALL PRIVILEGES ON public.inventory TO inventory_user;
EOSQL

echo "Adding authenticator role...";
psql --username postgres --dbname=dvdrental <<-EOSQL
	CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'qwerty';
	GRANT web_anon TO authenticator;
	GRANT actor_user TO authenticator;
	GRANT inventory_user TO authenticator;
EOSQL


