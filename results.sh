#!/bin/bash

set -e

psql -X -f - <<SQL
	begin;

	drop table if exists results;
	create table results (
		test text,
		iter int,
		fill int,
		result float8,
		primary key (test, iter, fill)
	);

	commit;
SQL


for fill in 0 10 20 30 40 50 60 70 80 90 100; do
	for file in $(ls upsertisms/*.sql); do
		file=$(basename ${file})

		for iter in 1 2 3; do
			data=$(grep -m 1 -Eo 'tps = [0-9.]+ ' results/${file}.f${fill}.${iter} |grep -Eo '[0-9.]+')
			psql -X -f - <<SQL
			insert into results values ('${file}', ${iter}, ${fill}, '${data}');
SQL
		done
	done
done

psql -X -c "\\copy (select fill, max(case when test = 'insert_or_ignore1.sql' then result * 250000 end), max(case when test = 'insert_or_ignore2.sql' then result * 250000 end), max(case when test = 'insert_or_ignore3.sql' then result * 250000 end) from results where test like 'insert_or_ignore%' group by fill order by fill) to 'result.dat' delimiter ' '"
gnuplot -e 'set terminal png; set out "insert_or_ignore.png"; set xlabel "row exists in % of cases"; set ylabel "UPSERTs / sec"; plot "result.dat" using 1:2 title "method 1" with lines, "result.dat" using 1:3 title "method 2" with lines, "result.dat" using 1:4 title "method 3" with lines'
psql -X -c "\\copy (select fill, max(case when test = 'insert_or_select1.sql' then result * 250000 end), max(case when test = 'insert_or_select2.sql' then result * 250000 end), max(case when test = 'insert_or_select3.sql' then result * 250000 end), max(case when test = 'insert_or_select4.sql' then result * 250000 end) from results where test like 'insert_or_select%' group by fill order by fill) to 'result.dat' delimiter ' '"
gnuplot -e 'set terminal png; set out "insert_or_select.png"; set xlabel "row exists in % of cases"; set ylabel "UPSERTs / sec"; plot "result.dat" using 1:2 title "method 1" with lines, "result.dat" using 1:3 title "method 2" with lines, "result.dat" using 1:4 title "method 3" with lines, "result.dat" using 1:5 title "method 4" with lines'
psql -X -c "\\copy (select fill, max(case when test = 'insert_or_update1.sql' then result * 250000 end), max(case when test = 'insert_or_update2.sql' then result * 250000 end), max(case when test = 'insert_or_update3.sql' then result * 250000 end), max(case when test = 'insert_or_update4.sql' then result * 250000 end) from results where test like 'insert_or_update%' group by fill order by fill) to 'result.dat' delimiter ' '"
gnuplot -e 'set terminal png; set out "insert_or_update.png"; set xlabel "row exists in % of cases"; set ylabel "UPSERTs / sec"; plot "result.dat" using 1:2 title "method 1" with lines, "result.dat" using 1:3 title "method 2" with lines, "result.dat" using 1:4 title "method 3" with lines, "result.dat" using 1:5 title "method 4" with lines'
