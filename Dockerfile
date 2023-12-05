FROM postgres 

COPY ./backup/dvdrental.tar ./dvdrental.tar
COPY ./backup/restore.sh ./docker-entrypoint-initdb.d

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres