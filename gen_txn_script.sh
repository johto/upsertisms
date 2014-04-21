#!/bin/bash

echo "begin;"

for ((i=1;i<=250000;i++)); do
	echo "select upsertism(${i});"
done

echo "rollback;"
