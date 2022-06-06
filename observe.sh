
SPAMMER_STATS_FILE=./results/${TRANSPORT}/spammer-stats.json

echo "" > $SPAMMER_STATS_FILE

echo -ne "GET /containers/$CONTAINER_ID/stats HTTP/1.1\r\n\r\n" >> $SPAMMER_STATS_FILE | sudo nc -U /var/run/docker.sock
