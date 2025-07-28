BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'Sridhar',
    p_last_name => 'Reddy',
    p_email => 'Tej@gmail.com',
    p_phone => 7702425609,
    p_dob => TO_DATE('2004-06-13', 'YYYY-MM-DD'),
    p_id_proof_type => 'Passport',
    p_id_proof_num => '123456778B',
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
    p_gender => 'dfvgb',
    p_role => 'Backend Developer'
  );
END;
/
select * from candidates;
set serveroutput on;
BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id =>55,
        p_interview_status=>'Selected',
        p_first_name=>'Teja',
        p_last_name=>'ram'
    );
END;
/


EXEC source_requirement.list_candidates;
set serveroutput on;
EXEC source_requirement.list_candidates(p_status=>'Selected');

EXEC source_requirement.list_candidates(p_country => 'India', p_skill => 'Java');

EXEC source_requirement.list_candidates(p_id_proof_type => 'aadhar');
SET SERVEROUTPUT ON SIZE UNLIMITED;


EXEC source_requirement.get_candidate_details(p_candidate_id=>108,p_phone=>7702425607,p_section=>'personal');


EXEC promote_candidate_to_employee(108,4,700000);


select * from candidates;





