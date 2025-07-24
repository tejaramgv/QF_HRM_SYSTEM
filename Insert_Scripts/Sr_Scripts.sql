BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'Priya',
    p_last_name => 'Narravula',
    p_email => 'priya@gmail.com',
    p_phone => 9211212210,
    p_dob => TO_DATE('2002-06-13', 'YYYY-MM-DD'),
    p_id_proof_type => 'Aadhar',
    p_id_proof_num => 543556389012,
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


--DELETE FROM candidates WHERE candidate_id>80;

SET SERVEROUTPUT ON

select * from candidates;

BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 2,
        p_first_name => 'Priya',
        P_Last_name=>'Narravula'
    );
END;

BEGIN
    source_requirement.REMOVE_CANDIDATE(80); 
END;

EXEC source_requirement.list_candidates;

EXEC source_requirement.list_candidates(p_city => 'Hyderabad');

EXEC source_requirement.list_candidates(p_country => 'India', p_skill => 'Java');

EXEC source_requirement.list_candidates(p_status => 'Rejected');


BEGIN
    source_requirement.get_candidate_details(1, 'PROFESsional');
END;


