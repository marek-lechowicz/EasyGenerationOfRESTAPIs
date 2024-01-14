# Easy generation of REST APIs

This document serves as a guide for the Advanced Database Systems project. The objective of the project is to assess and critique a potential solution designed for the simple and automated creation of functioning REST APIs derived from relational database structures. The system is expected to produce an operational REST interface.
The project was based on PostgREST.
Full documentation can be found at: https://postgrest.org/


## Runbook

All that is required to run the project is to have a docker set up the download the repository and use docker compose command given below.

**Requirments:**
Docker: https://docs.docker.com/get-docker/

**Running:**
```
docker compose up --build
```

There is no need  to download database from source, backup/dvdrental.tar includes database data (tables, records) and db is automaticall loaded on a container by restore.sh file.


## Database reference

The database used and its documentation can be found at the following link:
https://www.postgresqltutorial.com/postgresql-getting-started/postgresql-sample-database/

Database model:
![database model diagram](img/dvd-rental-sample-database-diagram.png)


## Querying data

This sections demonstrates which API call corresponds to a given SQL instruction.
Call examples assume the PostgREST server runs on **localhost:3000**.
**NOTE:** `DISTINCT` is currently not supported.

1. SELECT
```sql
SELECT length FROM film;
```
```
http://localhost:3000/film?select=length
```

2. WHERE, LIKE, AND, OR
```sql
SELECT length FROM film WHERE length < 50;
SELECT * FROM film WHERE title ILIKE 'Grosse Wonderful';
SELECT * FROM film WHERE title ILIKE 'G%' AND length < 50;
SELECT * FROM film WHERE title ILIKE 'G%' OR length < 50;
```
```
http://localhost:3000/film?length=lt.50 
http://localhost:3000/film?select=*&title=ilike.Grosse%20Wonderful
http://localhost:3000/film?select=*&and=(title.ilike.G*,length.lt.50)
http://localhost:3000/film?select=*&or=(title.ilike.G*,length.lt.50)
```

3. LIMIT
```sql
SELECT * FROM film LIMIT 3;
```
```
http://localhost:3000/film?limit=3
```
4. ORDER BY
```sql
SELECT * FROM film ORDER BY length DESC;
```
```
http://localhost:3000/film?order=length.desc
```

5. GROUP BY
**NOTE:** In order to use aggregate clauses the user must allow that it their configuration by setting variable **PGRST_DB_AGGREGATES_ENABLED** as **true**. `HAVING` and ordering by aggregated columns are currently supported by the PostGREST.
```sql
SELECT SUM(length) FROM film;
SELECT SUM(length) FROM film WHERE length < 50;
```
```
http://localhost:3000/film?select=length.sum()
http://localhost:3000/film?select=length.sum()&length=lt.50
```

6. JOIN
**NOTE:** By default all joins are **outer joins** to perform **inner** join `!inner` must be added between table an column name. The join condition is generated using the foreign keys columns (respecting composite keys).

```sql
SELECT title, language.name FROM film 
OUTER JOIN language ON film.language_id = language.id;

SELECT title, language.name FROM film 
INNER JOIN language ON film.language_id = language.id;
```
```
http://localhost:3000/film?select=title,language(name)
http://localhost:3000/film?select=title,language!inner(name)
```

7. QUERY COMBINATION
```sql
SELECT SUM(length) FROM film
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
GROUP BY category
WHERE category.name ILIKE 'h%';

SELECT AVG(length) FROM film
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
GROUP BY category
WHERE film.length < 50 OR film.length > 150;
```
```
http://localhost:3000/film?select=length.sum(),category!inner(name)&category.name=ilike.h*

http://localhost:3000/film?select=length.avg(),category!inner(name)&or=(length.lt.50,length.gt.150)
```

8. UPDATE
```sql
UPDATE film
SET length = 40
WHERE title ILIKE 'Grosse Wonderful';
```
```
curl "http://localhost:3000/film?select=*&title=ilike.Grosse%20Wonderful" \
  -X PATCH -H "Content-Type: application/json" \
  -d '{ "length": 40 }' 
```


## Permission and authentication
PostgREST handles the process of verifying users through JSON Web Tokens and relies on the database's set roles to decide what each user can do, which ensures that the security rules are straightforward and centralized. When the server works with the database, it takes on the role of the logged-in user, restricting its abilities to only what that particular user is authorized to do while connected.
https://postgrest.org/en/stable/references/auth.html?highlight=authentication

To manage access create role in database.
```sql
CREATE ROLE role_name;
GRANT usage ON schema schema_name to role_name;
GRANT select ON schema_name.table_name public TO role_name;
```

The example from repo works like this. There are four roles:
 - web_anon - used for unauthenticated requests with right to access *film* table
 - actor_user - used to access *actor* table
 - inventory_user - used to access *inventory* table
 - authenticator - role used to connect to DB

All roles are granted to *authenticator*

```
GRANT web_anon TO authenticator;
GRANT actor_user TO authenticator;
GRANT inventory_user TO authenticator;
```

To enable authentiaction via JWT in docker-compose  configuration the JWT_SECRET is provided (it must be at least 32-characters long)

```
PGRST_JWT_SECRET: "x3utk5afpyjMNkKTUcxABxjYk5OjMiAw"
```

To access the data the requester must provide a token with appropriate role. Normally such token would be issued by the application in our example we might use [JWT site](https://jwt.io/#debugger-io). To create token for authentication as actor_user we need to set "role" as "actor_user" in the "payload" section (other fileds are redundant) and also give our JWT_SECRET in "verify signature" section.

![JWT token generation](img/token_generation.png)

Now to when querying the data user must provide the token to be authenticated as desired role.

**Example:**
Querying as *web_anon*:
```
curl http://localhost:3000/film
```
Result: *List of all films*

```
curl http://localhost:3000/actor
```
Result:
```
{"code":"42501","details":null,"hint":null,"message":"permission denied for table actor"}
```

Querying as *actor_user*:
```bash
export ACTOR_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWN0b3JfdXNlciJ9.5CSAuJ9P2Q5M1VMhqbSvF69AWETek0MHuJ_xiKsBSoc
curl http://localhost:3000/actor -H "Authorization: Bearer $ACTOR_TOKEN"
```
Result: *List of all actors*
```bash
export ACTOR_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWN0b3JfdXNlciJ9.5CSAuJ9P2Q5M1VMhqbSvF69AWETek0MHuJ_xiKsBSoc
curl http://localhost:3000/inventory -H "Authorization: Bearer $ACTOR_TOKEN"
```
Result:
```
{"code":"42501","details":null,"hint":null,"message":"permission denied for table inventory"}
```

Trying to get data from not existing table gives the results:
```bash
curl http://localhost:3000/some_non_existing_table
```
```
{"code":"42P01","details":null,"hint":null,"message":"relation \"public.some_non_existing_table\" does not exist"}
```

## Swagger
PostgREST employs the OpenAPI standard to generate current documentation for its API automatically. Interactive tools like [Swagger Ui](https://swagger.io/tools/swagger-ui/) can then display this documentation, enabling users to send trial requests straight to the functioning API server.

Add following code in docker-compose file to create such documentation:
```yaml
swagger:
  image: swaggerapi/swagger-ui
    ports:
      - "8080:8080"
    expose:
      - "8080"
    environment:
      API_URL: http://localhost:3000/
```

![Swagger screenshot](img/swagger_screenshot.png)

# Questions
1. Are endpoints created for all tables in the database/schema?
Yes, by default all tables have an endpoint created. Access to tables/shemas can be controlled by setting up roles.

2. Are all attributes mapped to proper data types?
Yes, with respect to JSON restrictions (e.g., dates are passed as strings).

3. Is it possible to generate API documentation, e.g. using Swagger?
Yes, there is possiblity to create documentation with a tool such as  Swagger Ui.

4. Is it possible to customise which tables are used to create endpoints?
No, as it was said in the answer to the first question endpoints are created automatically for all tables.

5. Is there support for permissions/scopes?
Yes, permissions and scopes mechanisms are compatibile with PostgreSQL. Access control is based on roles.

6. What authentication/authorisation mechanisms are there?
PostgREST uses JWT (JSON Web Tokens) as an authentication method. 

## Contribution
Most of the time we worked in so called "Pair Programming", more strict division of work was employed just during the creation of the documentation, so given topic were documented by: 
- research - D. Bugajny
- database creating script - D. Bugajny, M. Lechowicz
- permission and authentication - M. Lechowicz
- queries - M. Lechowicz
- swagger - D. Bugajny


## Problems and difficulties encountered
- not all queries are allowed - e.g. distinct, having
- no native GUI

## Future development
- checking out other solutions and comparision
(https://github.com/dbohdan/automatic-api - list of potentially useful tools)
- measuring queries time with API and directly in database
- checking scalability of the solution
- creating unit and integration tests
- provide monitoring to track API health and performance
- develop front-end interface