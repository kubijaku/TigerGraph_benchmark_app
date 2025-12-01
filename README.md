# TigerGraph_benchmark_app

This is the repository for the Advanced Database Systems Project.

## Starting the container

1. Run the following command to start the container with TigerGraph instance (in the directory where the tigergraph{...}.tar.gz is located)

```bash
  docker load -i tigergraph{...}.tar.gz
```

2. Check the name of the image

```bash
  docker image list
```

3. Create directory for TigerGraph
```bash
  mkdir ~/temp_tiger
```

4. Run the image

```bash
  docker run -d --name tgraph -p 14240:14240 -p 9000:9000 -v ~/temp_tiger:/home/tigergraph/mydata \ [image_name]
```

5. Open container terminal 
```bash
  docker exec -it tgraph bash
```

6. Start all services
```bash
  gadmin start all
```


7. Check the status

```bash
  gadmin status
```

Then, your local web ui will be held here: [http://127.0.0.1:14240](http://127.0.0.1:14240)

## Loading the data

1. Copy the file with data to container by copying to mounted volume

```bash
cp ./cskg.tsv ~/temp_tiger
```

2. Log into the container with running TigerGraph instance

```bash
  docker exec -it tgraph bash
```

3. Start the GSQL shell

```bash
  gsql
```

4. Define the schema using import script
*Note: there cannot be tab or space before the word BEGIN or END

```gsql
BEGIN
  CREATE VERTEX Entity(
    PRIMARY_ID id STRING,
    label STRING
  ) WITH primary_id_as_attribute="true"

  CREATE DIRECTED EDGE Relation(
    FROM Entity ,
    TO Entity ,
    id STRING,
    relation STRING,
    label STRING,
    dimension STRING,
    source STRING,
    sentence STRING
  )

  CREATE GRAPH ADS (Entity, Relation)
END
```

5. Create loading job

```gsql
USE GRAPH ADS

/* Loading job - adjust $"..." to your TSV header names */
BEGIN
CREATE LOADING JOB load_relations FOR GRAPH ADS{

DEFINE FILENAME f = "./mydata/cskg.tsv";

LOAD f TO VERTEX Entity VALUES (
$"node1",
$"node1;label"
) USING SEPARATOR="\t", HEADER="true";

LOAD f TO VERTEX Entity VALUES (
$"node2",
$"node2;label"
) USING SEPARATOR="\t", HEADER="true";


LOAD f TO EDGE Relation VALUES (
$"node1",
$"node2",
$"id",
$"relation",
$"relation;label",
$"relation;dimension",
$"source",
$"sentence"
) USING SEPARATOR="\t", HEADER="true";
}

END
```

6. Run the loading job

```gsql
  RUN LOADING JOB load_relations USING f="./mydata/cskg.tsv"
```



