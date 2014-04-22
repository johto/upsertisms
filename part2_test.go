package main

import (
	_ "github.com/lib/pq"
	"database/sql"
	"fmt"
	"os"
	"testing"
)

const insertOrUpdate1 = `
drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
update tbl set b = 'abc' where a = %d * $1 returning id into _id;
if found then
	return _id;
end if;
begin
	insert into tbl (a, b) values ($1, 'abc') returning id into _id;
	return _id;
exception when unique_violation then
	update tbl set b = 'abc' where a = $1 returning id into strict _id;
	return _id;
end;
end
$$ language plpgsql;
`

const insertOrUpdate2 = `
drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
	insert into tbl (a, b) values ($1, 'abc') returning id into _id;
	return _id;
exception when unique_violation then
	update tbl set b = 'abc' where a = $1 returning id into strict _id;
	return _id;
end
$$ language plpgsql;
`

func initDB(b *testing.B) *sql.DB {
	var conninfo string
	if os.Getenv("PGSSLMODE") == "" {
		conninfo += " sslmode=disable"
	}

	dbh, err := sql.Open("postgres", conninfo)
	if err != nil {
		b.Fatal(err)
	}
	err = dbh.Ping()
	if err != nil {
		b.Fatal(err)
	}
	dbh.SetMaxOpenConns(1)
	_, err = dbh.Exec(`
		drop table if exists tbl;
		create unlogged table tbl (
			id serial unique not null,
			a integer primary key,
			b text not null
		);
	`)
	if err != nil {
		b.Fatal(err)
	}
	return dbh
}

func prepareUpsert(b *testing.B, dbh *sql.DB, createfunc string, args ...interface{}) *sql.Stmt {
	_, err := dbh.Exec(fmt.Sprintf(createfunc, args...))
	if err != nil {
		b.Fatal(err)
	}
	stmt, err := dbh.Prepare("select upsertism($1)")
	if err != nil {
		b.Fatal(err)
	}
	return stmt
}

func BenchmarkInsertOrUpdate1(b *testing.B) {
	dbh := initDB(b)
	defer dbh.Close()
	stmt := prepareUpsert(b, dbh, insertOrUpdate1, 1)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := stmt.Exec(i)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkInsertOrUpdate1RowExists(b *testing.B) {
	dbh := initDB(b)
	defer dbh.Close()
	stmt := prepareUpsert(b, dbh, insertOrUpdate1, 1)
	_, err := stmt.Exec(1)
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := stmt.Exec(1)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkInsertOrUpdate1UnderCongestion(b *testing.B) {
	dbh := initDB(b)
	defer dbh.Close()
	stmt := prepareUpsert(b, dbh, insertOrUpdate1, -1)
	_, err := stmt.Exec(1)
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := stmt.Exec(1)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkInsertOrUpdate2(b *testing.B) {
	dbh := initDB(b)
	defer dbh.Close()
	stmt := prepareUpsert(b, dbh, insertOrUpdate2)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := stmt.Exec(i)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkInsertOrUpdate2RowExists(b *testing.B) {
	dbh := initDB(b)
	defer dbh.Close()
	stmt := prepareUpsert(b, dbh, insertOrUpdate2)
	_, err := stmt.Exec(1)
	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := stmt.Exec(1)
		if err != nil {
			b.Fatal(err)
		}
	}
}
