drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
update tbl set b = 'abc' where a = $1 returning id into _id;
if found then
	return _id;
end if;
insert into tbl (a, b) values ($1, 'abc') returning id into _id;
return _id;
exception when unique_violation then
	update tbl set b = 'abc' where a = $1 returning id into strict _id;
	return _id;
end
$$ language plpgsql;
