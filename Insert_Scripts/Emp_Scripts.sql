EXEC mark_in_time(1071);
select * from employee_attendance;
select * from employee;
BEGIN
    mark_in_time(1072); 
    mark_out_time(1072); 
END;

BEGIN
    mark_leave(1073); 
END;

BEGIN
    mark_in_time(1072);
END;

BEGIN
    mark_out_time(1074); 
END;

BEGIN
    mark_absentees;
END;

execute source_requirement.appoint_ceo('Viswanath','Reddy');
select * from leave_balance;

ALTER TABLE Employee DROP COLUMN First_Name;
ALTER TABLE Employee DROP COLUMN Last_Name;
ALTER TABLE Employee DROP COLUMN Gender;