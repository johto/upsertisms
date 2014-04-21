drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
loop
	select id into _id from tbl where a = $1;
	if found then
		return _id;
	end if;
	begin
		insert into tbl (a, b) values ($1, 'abc') returning id into _id;
		return _id;
	exception when unique_violation then
		-- loop again
	end;
end loop;
end
$$ language plpgsql;
