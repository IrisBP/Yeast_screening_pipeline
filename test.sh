#!/bin/bash


job_nb=3
echo "Array task ID: $job_nb"

start=$((job_nb*48))
end=$((start+47))
echo "Starting position: $start"
echo "Ending position: $end"
for line in $(seq $start $end);
do 
    echo "Extracting position from line $line"
   
done


