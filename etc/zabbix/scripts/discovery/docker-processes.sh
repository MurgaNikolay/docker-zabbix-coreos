#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/../main"
CTS=$(echo "GET /containers/json?all=1 HTTP/1.0\r\n" | sudo netcat -U "$DOCKER_SOCKET" | tail -n +5)
LEN=$(echo "$CTS" | jq 'length')
for I in $(seq 0 $((LEN-1)))
do
    ID=$(echo "$CTS" | jq ".[$I].Id" | sed -e 's/^"//' -e 's/"$//')
    NAME=$(echo "$CTS" | jq ".[$I].Names[0]" | sed -e 's/^"\//"/')
    CT=$(echo "GET /containers/$ID/json HTTP/1.0\r\n"|sudo netcat -U "$DOCKER_SOCKET" | tail -n +5)
    RUNNING=$(echo "$CT" | jq ".State.Running" | sed -e 's/^"//' -e 's/"$//')
    if [ "$RUNNING" = "true" ]; then
        TOP=$(echo "GET /containers/$ID/top?ps_args=-aux HTTP/1.0\r\n"| sudo netcat -U "$DOCKER_SOCKET" | tail -n +5)
        PS=$(echo "$TOP" | jq ".Processes")
        PS_LEN=$(echo "$PS" | jq "length")

        for J in $(seq 0 $((PS_LEN-1)))
        do
            P=$(echo "$PS" | jq ".[$J]")
            PID=$(echo "$P" | jq ".[1]" | sed -e 's/^"//' -e 's/"$//')
            CMD=$(basename $(echo "$P" | jq ".[10]" | sed -e 's/^"//' -e 's/"$//' | cut -d' ' -f1))
            DATA="$DATA,"'{"{#NAME}":'${NAME}',"{#PID}":'${PID}',"{#CMD}":"'${CMD}'"}'
        done
    fi
done
echo '{"data":['${DATA#,}']}'
