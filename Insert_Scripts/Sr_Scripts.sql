BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'aNitha',
    p_last_name => 'kEtha',
    p_email => 'anitha2@gmail.com',
    p_phone => 6962425612,
    p_dob => '13-Jul-2004',
    p_id_proof_type => 'Passport',
    p_id_proof_num => 'A1717569',
    p_highest_degree => 'B.Tech',
    p_university => 'JNTU',
    p_cgpa => 8.9,
    p_city => 'hyderabad',
    p_country => 'india',
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
select * from candidates;
--check dob and parameter size
--do case insensitive
BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'Lahari',
    p_last_name => 'Narravula',
    p_email => 'lahar36@gmail.com',
    p_phone =>9791415601,
    p_dob => '12-Jun-2004',
    p_id_proof_type => 'aadhar',
    p_id_proof_num =>237332211110,
    p_highest_degree => 'b.tech',
    p_university => 'jntu',
    p_cgpa => 9.8,
    p_city => 'hyderabad',
    p_country =>'indIA',
    p_last_employer => Null,
    p_last_salary => Null,
    p_expected_salary =>Null,
    p_years_of_experience => Null,
    p_skills => 'python,sql',
    p_gender => 'F',
    p_role =>'software engineer'
  );
END;
/
ALTER TABLE Candidates DROP CONSTRAINT UNIQ_ID_PROOF;
select * from candidates;
select * from employee;
DELETE FROM Candidates WHERE candidate_id=171;
set serveroutput on;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id =>138,
        p_gender=>'m',
        p_Interview_status=>'rejected',
        p_rejection_reason=>'Poor skills',
        p_role=>'backend developer'
        
    );
END;
/
--check all sensitives in rejection
--check the trigger
--rejected reason is required when rejected
--give valid error msg for email,id_proof_type
set serveroutput on;
select * from candidates;
BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'priya',
    p_last_name => 'gajjala',
    p_email => 'priyanka111@gmail.com',
    p_phone => 9791485612,
    p_dob => TO_DATE('2005-06-13', 'YYYY-MM-DD'),
    p_id_proof_type => 'dl',
    p_id_proof_num => 'ml923802308058',
    p_highest_degree => 'B.Tech',
    p_university => 'JntU',
    p_cgpa => 8.9,
    p_city => 'hyderabad',
    p_country => 'india',
    p_last_employer => 'infosys',
    p_last_salary => 500000,
    p_expected_salary => 600000,
    p_years_of_experience => 2,
    p_skills => 'Python, sql',
    p_gender => 'f',
    p_role => 'BacKEnd Developer'
  );
END;
/
select * from candidates;
--ALTER TABLE candidates DROP CONSTRAINT SYS_C008620;
SET SERVEROUTPUT ON;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id =>2,
        p_interview_status=>'rejected',
        p_rejection_reason=>'rejected'

    );
END;
/
select * from candidates;


EXEC source_requirement.list_candidates;
set serveroutput on;
EXEC source_requirement.list_candidates(p_gender=>'f',p_interview_status=>'rejected');
--name,experience,all mandatory fields(take all parameters)
EXEC source_requirement.list_candidates(p_country => 'India', p_skill => 'Java');
--invlude name,pre_company,status,
EXEC source_requirement.list_candidates(p_cgpa=>9.1);
SET SERVEROUTPUT ON SIZE UNLIMITED;

---inactive the status when selected
EXEC source_requirement.get_candidate_details(p_candidate_id=>1,p_detail_type=>'acadEmic');
--do case insensitive,valid msg for candidate
--valid masg,parameter valid
--check section first then do candiadteid

EXEC source_requirement.promote_candidate_to_employee(54,4,700000);
--it required field(salary)
--once candidate id exists in employee don't add again
set serveroutput on;
--delete from employee where employee_id>1134;
EXEC pkg_emp_ops.add_department(p_department_name=>'pRocurement',p_city_id=>22);

EXEC pkg_emp_ops.update_department(p_department_id=>3,p_manager_id=>1077);

select * from employee;
select * from candidates;
select * from employee;
select * from department;


update candidates set university=upper(university);

set serveroutput on;



BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 2,
        p_years_of_experience=>5,
        p_dob=>'30-July-1998'
        );
END;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 26,
        p_id_proof_num=>456578791123
        );
END;

select * from candidates;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 41,
        p_id_proof_num=>456578791167
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 44,
        p_id_proof_num=>456572791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 47,
        p_id_proof_num=>356578791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 51,
        p_id_proof_num=>356278791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 54,
        p_id_proof_num=>256278791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 57,
        p_id_proof_num=>251278791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 60,
        p_id_proof_num=>556278791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 80,
        p_id_proof_num=>856278791126
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 22,
        p_id_proof_num=>'MH0120031234567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 24,
        p_id_proof_num=>'UP0120031234567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 25,
        p_id_proof_num=>'MH0120031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 28,
        p_email=>'priyanka@gmail.com'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 33,
        p_id_proof_num=>'TG1020031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 38,
        p_id_proof_num=>'MH0120036224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 63,
        p_id_proof_num=>'WB0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 66,
        p_id_proof_num=>'TG0920031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 42,
        p_id_proof_num=>'UP0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 45,
        p_id_proof_num=>'MH0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 48,
        p_id_proof_num=>'KN0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 49,
        p_id_proof_num=>'AM0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 53,
        p_id_proof_num=>'JK0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 55,
        p_id_proof_num=>'UT0320031224567'
        );
END;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 58,
        p_id_proof_num=>'KE0320031224567'
        );
END;

--UPDATE Candidates set Rejection_Reason='Poor communication skills' where candidate_id=111;

ALTER TABLE Candidates DISABLE ALL TRIGGERS;

ALTER TABLE Candidates ENABLE ALL TRIGGERS;
--ALTER TABLE candidates MODIFY phone NUMBER NOT NULL;
--
--UPDATE candidates
--SET phone_str = '+91' || TO_CHAR(phone);
--
--ALTER TABLE candidates DROP COLUMN phone;
--
--ALTER TABLE candidates RENAME COLUMN phone_str TO phone;

SELECT *
FROM candidates
WHERE 
    -- Age must be between 18 and 65
    (TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12) < 18 OR TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12) > 65)
    OR
    -- Experience must be >= 0 and <= (age - 18)
    (years_of_experience < 0 OR years_of_experience > (TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12) - 18))
    OR
    -- Age 18 must have experience = 0
    (TRUNC(MONTHS_BETWEEN(SYSDATE, dob) / 12) = 18 AND years_of_experience != 0)
    OR
    -- Aadhar validation if ID proof type is Aadhar
    (LOWER(id_proof_type) = 'aadhar' AND NOT REGEXP_LIKE(id_proof_num, '^[2-9][0-9]{11}$'));

SELECT *
FROM candidates
WHERE UPPER(id_proof_type) = 'DL'
  AND (
        id_proof_num IS NULL
        OR NOT REGEXP_LIKE(id_proof_num, '^[A-Za-z0-9]{13,15}$')
      );

SELECT *
FROM candidates
WHERE LOWER(interview_status) = 'rejected'
  AND (rejection_reason IS NULL OR TRIM(rejection_reason) = '');

EXEC pkg_emp_ops.update_department(p_department_id=>3,p_manager_id=>1035);
set serveroutput on;
-- All employees
EXEC pkg_emp_ops.list_employees(p_country_id=>100);
set serveroutput on;
--get emp details
EXEC pkg_emp_ops.get_employee_details(10009); 

EXEC pkg_emp_ops.update_employee(p_employee_id=>1037,p_department_id => 1,p_role=>'hr Executive');

set serveroutput on;

select * from master_data;
select * from candidates;
select * from employee;

--DELETE FROM Employee WHERE candidate_id=1;
--drop trigger trg_validate_candidate;
--drop trigger trg_validate_candidates;