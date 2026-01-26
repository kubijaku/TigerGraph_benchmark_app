#!/usr/bin/env bash
set -euo pipefail

IMAGE="kubijaku/tigergraph_ads:0.0.1"

CONTAINER_NAME="tigergraph_dbcli"

if docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
  echo "Container '$CONTAINER_NAME' already exists. Skipping docker run."
else
  docker run -d --name "$CONTAINER_NAME" \
    -p 14022:14022 \
    -p 9000:9000 \
    -v $PWD/queries:/home/tigergraph/queries \
    "$IMAGE"
fi


echo "Initializing TigerGraph with gadmin..."
docker exec "$CONTAINER_NAME" bash -c \
    "./tigergraph/app/cmd/gadmin start all"
    
echo "Waiting for TigerGraph to be ready..."
output_info="$(docker exec "$CONTAINER_NAME" bash -c \
"./tigergraph/app/cmd/gadmin status gsql")"
cnt=0
until echo "$output_info" | grep -q "Online"; do
    cnt=$((cnt + 1))
    if (( cnt % 10 == 0 )); then
    echo "TigerGraph did not become ready in time. Starting again"
    docker exec "$CONTAINER_NAME" bash -c \
        "./tigergraph/app/cmd/gadmin start all"
    fi
    echo "Waiting for TigerGraph to be ready...: $output_info"
    sleep 10
    output_info="$(docker exec "$CONTAINER_NAME" bash -c \
    "./tigergraph/app/cmd/gadmin status gsql")"
done            

echo "Change mode of ADS queries..."
docker exec -u root "$CONTAINER_NAME" bash -lc '
  source /home/tigergraph/.bashrc
  for i in $(seq -w 1 18); do
    if [[ ! -f /home/tigergraph/queries/query_${i}.gsql ]]; then
      echo "ERROR: $QUERY_FILE not found"
      exit 1
    fi
    echo "Running query_$i.gsql"
    chmod +x /home/tigergraph/queries/query_${i}.gsql
  done
'

echo "Loading ADS queries into TigerGraph..."
docker exec "$CONTAINER_NAME" bash -lc '
  source /home/tigergraph/.bashrc
  for i in $(seq -w 1 18); do
    if [[ ! -f /home/tigergraph/queries/query_${i}.gsql ]]; then
      echo "ERROR: $QUERY_FILE not found"
      exit 1
    fi
    echo "Running query_$i.gsql"
    ./tigergraph/app/cmd/gsql < /home/tigergraph/queries/query_${i}.gsql
  done
'

# Run query:

if [[ $# -lt 1 ]]; then
  echo "Usage: dbcli <goal_number> [gsql_args...]"
  exit 1
fi

GOAL="$1"
shift || true

# Validate goal is numeric
if ! [[ "$GOAL" =~ ^[0-9]+$ ]]; then
  echo "Error: goal_number must be numeric"
  exit 1
fi

# Zero-pad goal number
QUERY_NUM=$(printf "%02d" "$GOAL")
QUERY_FILE="/home/tigergraph/queries/query_${QUERY_NUM}.gsql"


docker exec "$CONTAINER_NAME" bash -lc "
  source /home/tigergraph/.bashrc
  if [[ ! -f '$QUERY_FILE' ]]; then
    echo 'Error: $QUERY_FILE not found'
    exit 1
  fi
  ./tigergraph/app/cmd/gsql $* < '$QUERY_FILE'
"
