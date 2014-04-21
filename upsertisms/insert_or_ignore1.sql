drop function if exists upsertism(int);
create function upsertism(int)
returns void
as $$
begin
perform 1 from tbl where a = $1;
if not found then
	begin
		insert into tbl (a, b) values ($1, 'abc');
	exception when unique_violation then
	end;
end if;
end
$$ language plpgsql;
