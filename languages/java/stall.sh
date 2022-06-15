#!/bin/bash
n=1

while [ $n -le 50 ]
do
	echo "Sleeping ${n}"
    sleep 10
	n=$(( n+1 ))	 # increments $n
done
