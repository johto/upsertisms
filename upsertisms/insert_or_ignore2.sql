drop function if exists upsertism(int);
create function upsertism(int)
returns void
as $$
declare
begin
begin
	insert into tbl (a, b) values ($1, 'abc');
exception when unique_violation then
end;
end
$$ language plpgsql;
