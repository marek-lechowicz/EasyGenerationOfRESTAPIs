#!/bin/bash

psql -U postgres -c "CREATE DATABASE dvdrental;";
pg_restore -U postgres --dbname=dvdrental --verbose ./dvdrental.tar;