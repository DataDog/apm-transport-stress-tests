#!/bin/bash
n=1

while [ $n -le 100 ]
do
	echo "Sleeping ${n}"
    sleep 20
	n=$(( n+1 ))
done
