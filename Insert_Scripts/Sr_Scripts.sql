BEGIN
  source_requirement.ADD_CANDIDATE(
    p_first_name => 'Priya',
    p_last_name => 'Narravula',
    p_email => 'Tejaram@gmail.com',
    p_phone => 7702425607,
    p_dob => TO_DATE('2026-06-13', 'YYYY-MM-DD'),
    p_id_proof_type => 'DL',
    p_id_proof_num => '508370080A57',
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


BEGIN
    source_requirement.UPDATE_CANDIDATE(
        p_candidate_id => 102,
        p_interview_status=>'Rejected',
        p_rejection_reason=>'Not Cleared'
    );
END;
/
BEGIN
    source_requirement.REMOVE_CANDIDATE(80); 
END;

EXEC source_requirement.list_candidates;

EXEC source_requirement.list_candidates(p_status=>'Rejected');

EXEC source_requirement.list_candidates(p_country => 'India', p_skill => 'Java');

EXEC source_requirement.list_candidates(p_status => 'Rejected');


BEGIN
    source_requirement.get_candidate_details(102, 'personal');
END;


select * from employee;

EXEC apply_leave(1072, 'Sick', DATE '2025-07-25', DATE '2025-07-27');


select * from employee_leaves;

EXEC process_leave(1072, DATE '2025-07-25',1071,'APPROVE');
