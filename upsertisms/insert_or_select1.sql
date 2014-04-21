drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
select id into _id from tbl where a = $1;
if found then
	return _id;
end if;
begin
	insert into tbl (a, b) values ($1, 'abc') returning id into _id;
	return _id;
exception when unique_violation then
	select id into strict _id from tbl where a = $1;
	return _id;
end;
end
$$ language plpgsql;
