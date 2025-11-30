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

3. Run the image

```bash
  docker run -d --name tgraph -p 14240:14240 -p 9000:9000 [image_name]
```

4. Start all services

```bash
  docker exec -it tgraph bash
  gadmin start all
```

5. Check the status

```bash
  gadmin status
```

Then, your local web ui will be held here: [http://127.0.0.1:14240](http://127.0.0.1:14240)

## Loading the data

1. Copy the file with data to container with TigerGraph

```bash
  docker cp ./cskg.tsv tgraph:/home/tigergraph/data
```

2. Log into the container with running TigerGraph instance

```bash
  docker exec -it -u tigergraph tgraph bash
```

3. Start the GSQL shell

```bash
  gsql
```

4. Define the schema

```gsql
  USE GLOBAL
  DROP ALL

  CREATE VERTEX Concept (PRIMARY_ID id STRING, label STRING) WITH primary_id_as_attribute="true"

  CREATE DIRECTED EDGE RELATION (FROM Concept, TO Concept, rel_type STRING, label STRING, sentence STRING) WITH REVERSE_EDGE="RELATION_REV"

  CREATE GRAPH ConceptGraph (Concept, RELATION) 
```

5. Create loading job

```gsql
  USE GRAPH ConceptGraph

  BEGIN
    CREATE LOADING JOB load_concepts FOR GRAPH ConceptGraph {
      DEFINE FILENAME f1 = "/home/tigergraph/data.tsv";

    -- Map the file columns. 
    -- 0=id, 1=node1, 2=relation, 3=node2, 4=node1;label, 5=node2;label, 
    -- 6=relation;label, 7=relation;dimension, 8=source, 9=sentence
    
      LOAD f1 TO VERTEX Concept VALUES ($1, $4) USING SEPARATOR="\t", HEADER="true";
      LOAD f1 TO VERTEX Concept VALUES ($3, $5) USING SEPARATOR="\t", HEADER="true";
    
    -- Load the edge. Note: $1 is Source, $3 is Target
      LOAD f1 TO EDGE RELATION VALUES ($1, $3, $2, $6, $9) USING SEPARATOR="\t", HEADER="true";
    }
  END
```

6. Run the loading job

```gsql
  RUN LOADING JOB load_concepts
```
