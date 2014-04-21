#!/bin/bash

nrows=250000

mkdir -p results
rm -f results/*

for fill in 0 10 20 30 40 50 60 70 80 90 100; do
	psql -X -f - <<SQL
	begin;

	drop table if exists tbl;
	create table tbl (
		id serial unique not null,
		a integer primary key,
		b text not null
	);

	insert into tbl (a, b) select i, 'abc' from generate_series(1, ${nrows}) i order by random() limit ((${fill} / 100.0) * ${nrows})::bigint;

	commit;
SQL

	for file in $(ls upsertisms/*.sql); do
		psql -Xf $file
		file=$(basename ${file})

		for iter in 1 2 3; do
			psql -X -f - <<SQL
			cluster tbl using tbl_pkey;
			checkpoint;
SQL
			echo "file ${file}, iter ${iter}, fill ${fill}%"
			pgbench -h /tmp -c 1 -t 1 -n -f txn.sql > results/${file}.f${fill}.${iter}
		done
	done
done
