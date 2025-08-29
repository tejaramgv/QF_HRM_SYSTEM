EXEC mark_in_time(1071);
select * from employee_attendance;
truncate table employee_attendance;
select * from employee;
BEGIN
    mark_in_time(1326); 
    mark_out_time(1072); 
END;

BEGIN
    mark_leave(1073); 
END;

BEGIN
    pkg_emp_ops.mark_in_time(1326);
END;

set serveroutput on;
BEGIN
    pkg_emp_ops.mark_out_time(1326); 
END;

BEGIN
    mark_absentees;
END;

execute source_requirement.appoint_ceo('Viswanath','Reddy');
select * from leave_balance;
select * from employee_attendance;
ALTER TABLE Employee_attendance DISABLE ALL TRIGGERS;
--ALTER TABLE Employee DROP COLUMN First_Name;
--ALTER TABLE Employee DROP COLUMN Last_Name;
--ALTER TABLE Employee DROP COLUMN Gender;