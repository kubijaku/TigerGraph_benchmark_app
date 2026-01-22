FROM tigergraph/community:4.2.2


COPY ./initialization /home/tigergraph/mydata

# Run initial script to create DB schema and load data
RUN ./tigergraph/app/cmd/gadmin start all &&\
    sleep 10 &&\
    ./tigergraph/app/cmd/gadmin status gsql &&\
    ./tigergraph/app/cmd/gsql /home/tigergraph/mydata/import.gsql