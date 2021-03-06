drop function if exists upsertism(int);
create function upsertism(int)
returns int
as $$
declare
_id int;
begin
begin
	insert into tbl (a, b)
		select $1, 'abc'
		where not exists (select 1 from tbl t2 where t2.a = $1)
		returning id into _id;
	if found then
		return _id;
	end if;
exception when unique_violation then
end;
update tbl set b = 'abc' where a = $1 returning id into strict _id;
return _id;
end
$$ language plpgsql;
