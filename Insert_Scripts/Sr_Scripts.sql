
select * from candidates;
select * from employee;
set serveroutput on;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id =>1,
        p_dob=>to_date('01-01-2006','dd-mm-yyyy')
    );
END;
/
set serveroutput on;
select * from candidates;
BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'lahari',
    p_last_name => 'Narravula',
    p_email => 'lahari@gmail.com',
    p_phone => 7701425607,
    p_dob => TO_DATE('2005-06-13', 'YYYY-MM-DD'),
    p_id_proof_type => 'DL',
    p_id_proof_num => 'QL5013700898057',
    p_highest_degree => 'B.Tech',
    p_university => 'JNTU',
    p_cgpa => 8.9,
    p_city => 'Hyderabad',
    p_country => 'India',
    p_last_employer => 'Infosys',
    p_last_salary => 500000,
    p_expected_salary => 600000,
    p_years_of_experience => 2,
    p_skills => 'Python, SQL',
    p_gender => 'F',
    p_role => 'Backend Developer'
  );
END;
/

SET SERVEROUTPUT ON;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 59,
        p_interview_status=>'Selected'

        
    );
END;
/
select * from candidates;


EXEC source_requirement.list_candidates;
set serveroutput on;
EXEC source_requirement.list_candidates(p_status=>'Selected');

EXEC source_requirement.list_candidates(p_country => 'India', p_skill => 'Java');

EXEC source_requirement.list_candidates(p_id_proof_type => 'aadhar');
SET SERVEROUTPUT ON SIZE UNLIMITED;


EXEC source_requirement.get_candidate_details(p_section=>'personal');


EXEC source_requirement.promote_candidate_to_employee(59,4,700000);

set serveroutput on;
EXEC pkg_emp_ops.add_department(p_department_name=>'pRocurement',p_city_id=>22);

EXEC pkg_emp_ops.update_department(p_department_id=>3,p_manager_id=>1035);
set serveroutput on;
-- All employees
EXEC pkg_emp_ops.list_employees(p_country_id=>100);

--get emp details
EXEC pkg_emp_ops.get_employee_details(10009); 

EXEC pkg_emp_ops.update_employee(p_employee_id=>1037,p_department_id => 1,p_role=>'hr Executive');

set serveroutput on;

select * from master_data;
select * from candidates;
select * from employee;




