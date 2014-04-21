drop function if exists upsertism(int);
create function upsertism(int)
returns void
as $$
begin
perform 1 from tbl where a = $1;
if not found then
	insert into tbl (a, b) values ($1, 'abc');
end if;
exception when unique_violation then
end
$$ language plpgsql;
