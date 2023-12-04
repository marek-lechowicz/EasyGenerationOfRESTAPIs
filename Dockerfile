FROM postgres 

COPY ./backup/dvdrental.tar .
COPY ./backup/restore.sh .

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

CMD ./restore.sh