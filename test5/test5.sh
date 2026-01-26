set -euo pipefail

CSV="/home/tigergraph/test5/sample_nodes.csv"
RUNS=5

TIMES=()
MEMS=()

echo "Running query_01 workload $RUNS times"

for RUN in $(seq 1 $RUNS); do
    echo
    echo "Run $RUN/$RUNS"

    START=$(date +%s%N)

    /usr/bin/time -v -o /tmp/time_$RUN.txt bash -c "
    while IFS=, read -r ID _; do
        [ \"\$ID\" = \"id\" ] && continue

        if ./tigergraph/app/cmd/gsql \"USE GRAPH ADS RUN QUERY query_17(\\\"\$ID\\\",3)\" > /dev/null 2>&1; then
        echo -n \".\"
        else
        echo -n \"F\"
        fi
    done < \"$CSV\"
    "

    END=$(date +%s%N)
    DURATION_MS=$(( (END - START) / 1000000 ))

    PEAK_MEM=$(grep "Maximum resident set size" /tmp/time_$RUN.txt | awk "{print \$6}")

    echo
    echo "Run $RUN time : ${DURATION_MS} ms"
    echo "Run $RUN mem  : ${PEAK_MEM} KB"

    TIMES+=("$DURATION_MS")
    MEMS+=("$PEAK_MEM")
done

# ---- sort metrics ----
SORTED_TIMES=($(printf "%s\n" "${TIMES[@]}" | sort -n))
SORTED_MEMS=($(printf "%s\n" "${MEMS[@]}" | sort -n))

# ---- select required stats ----
SECOND_BEST_TIME=${SORTED_TIMES[1]}
SECOND_WORST_MEM=${SORTED_MEMS[$((RUNS - 2))]}

echo
echo "================ FINAL METRICS ================"
echo "Second best execution time : ${SECOND_BEST_TIME} ms"
echo "Second worst memory usage  : ${SECOND_WORST_MEM} KB"
