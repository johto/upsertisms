drop function if exists upsertism(int);
create function upsertism(int)
returns void
as $$
declare
begin
begin
	insert into tbl (a, b)
		select $1, 'abc'
		where not exists (select 1 from tbl t2 where t2.a = $1)
		;
exception when unique_violation then
end;
end
$$ language plpgsql;
