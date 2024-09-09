-- COMP3311 23T1 Final Exam
-- Q4: Check whether account balance is consistent with transactions

-- replace this line with any helper views or functions --

create or replace function q4(_acctID integer)
	returns text
as $$
declare
	_balance integer := 0;
	_stored integer := 0;
	_tup record;
begin
	select balance into _stored from accounts where id = _acctID;
	if (not found) then
	return 'No such account';
	end if;
	for _tup in
		select * from transactions where source = _acctID or dest = _acctID
	loop
		if _tup.ttype = 'deposit' then
			_balance := _balance + _tup.amount;
		elsif _tup.ttype = 'withdrawal' then
			_balance := _balance - _tup.amount;
		else -- _tup.ttype = 'transfer' then
			if _tup.source = _acctID then
				_balance := _balance - _tup.amount;
			else
				_balance := _balance + _tup.amount;
			end if;
		end if;
	end loop;
	if _balance = _stored then
		return 'OK';
	else
		return 'Mismatch: calculated balance '||_balance::text||', stored balance '|| _stored::text;
	end if;
end;
-- replace this line with your PLpgSQL code --
$$ language plpgsql;
