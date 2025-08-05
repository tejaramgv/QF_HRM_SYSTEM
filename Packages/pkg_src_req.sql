    CREATE SEQUENCE employee_seq
START WITH 1001
INCREMENT BY 1
NOCACHE;

CREATE OR REPLACE PACKAGE source_requirement AS

PROCEDURE add_candidate (
    p_first_name          IN VARCHAR2 DEFAULT NULL,
    p_last_name           IN VARCHAR2 DEFAULT NULL,
    p_email               IN VARCHAR2 DEFAULT NULL,
    p_phone               IN NUMBER DEFAULT NULL,
    p_dob                 IN DATE DEFAULT NULL,
    p_id_proof_type       IN VARCHAR2 DEFAULT NULL,
    p_id_proof_num        IN VARCHAR2 DEFAULT NULL,
    p_highest_degree      IN VARCHAR2 DEFAULT NULL,
    p_university          IN VARCHAR2 DEFAULT NULL,
    p_cgpa                IN NUMBER DEFAULT NULL,
    p_city                IN VARCHAR2 DEFAULT NULL,
    p_country             IN VARCHAR2 DEFAULT NULL,
    p_last_employer       IN VARCHAR2 DEFAULT NULL,
    p_last_salary         IN NUMBER DEFAULT NULL,
    p_expected_salary     IN NUMBER DEFAULT NULL,
    p_years_of_experience IN NUMBER DEFAULT NULL,
    p_skills              IN VARCHAR2 DEFAULT NULL,
    p_gender              IN CHAR DEFAULT NULL,
    p_role                IN VARCHAR2 DEFAULT NULL
);

PROCEDURE update_candidate (
    p_candidate_id        IN NUMBER,
    p_first_name          IN VARCHAR2 DEFAULT NULL,
    p_last_name           IN VARCHAR2 DEFAULT NULL,
    p_email               IN VARCHAR2 DEFAULT NULL,
    p_phone               IN NUMBER DEFAULT NULL,
    p_dob                 IN DATE DEFAULT NULL,
    p_id_proof_type       IN VARCHAR2 DEFAULT NULL,
    p_id_proof_num        IN VARCHAR2 DEFAULT NULL,
    p_highest_degree      IN VARCHAR2 DEFAULT NULL,
    p_university          IN VARCHAR2 DEFAULT NULL,
    p_cgpa                IN NUMBER DEFAULT NULL,
    p_city                IN VARCHAR2 DEFAULT NULL,
    p_country             IN VARCHAR2 DEFAULT NULL,
    p_last_employer       IN VARCHAR2 DEFAULT NULL,
    p_last_salary         IN NUMBER DEFAULT NULL,
    p_expected_salary     IN NUMBER DEFAULT NULL,
    p_years_of_experience IN NUMBER DEFAULT NULL,
    p_skills              IN VARCHAR2 DEFAULT NULL,
    p_interview_status    IN VARCHAR2 DEFAULT NULL,
    p_rejection_reason    IN VARCHAR2 DEFAULT NULL,
    p_gender              IN CHAR DEFAULT NULL,
    p_role                IN VARCHAR2 DEFAULT NULL
);



PROCEDURE remove_candidate (
    p_candidate_id IN NUMBER
);

PROCEDURE list_candidates (
    p_country IN VARCHAR2 DEFAULT NULL,
    p_city    IN VARCHAR2 DEFAULT NULL,
    p_skill   IN VARCHAR2 DEFAULT NULL,
    p_interview_status  IN VARCHAR2 DEFAULT NULL,
    p_id_proof_type IN VARCHAR2 DEFAULT NULL,
    p_degree IN VARCHAR2 DEFAULT NULL,
    p_status IN VARCHAR2 DEFAULT NULL,
    p_role IN VARCHAR2 DEFAULT NULL,
    p_university        IN VARCHAR2 DEFAULT NULL,
    p_first_name        IN VARCHAR2 DEFAULT NULL,
    p_last_name         IN VARCHAR2 DEFAULT NULL,    
    p_exp               IN NUMBER DEFAULT NULL,
    p_last_employer     IN VARCHAR2 DEFAULT NULL,
    p_last_salary       IN NUMBER DEFAULT NULL,
    p_expected_salary    IN NUMBER DEFAULT NULL,
    p_cgpa              IN NUMBER DEFAULT NULL,
    p_dob    IN DATE DEFAULT NULL,
    p_rejection_reason    IN VARCHAR2 DEFAULT NULL,
    p_gender              IN VARCHAR2 DEFAULT NULL
    
);

PROCEDURE get_candidate_details (
    p_candidate_id IN candidates.candidate_id%TYPE DEFAULT NULL,
    p_email        IN candidates.email%TYPE DEFAULT NULL,
    p_phone        IN candidates.phone%TYPE DEFAULT NULL,
    p_id_proof_num IN candidates.id_proof_num%TYPE DEFAULT NULL,    
    p_detail_type      IN VARCHAR2 DEFAULT NULL
);

PROCEDURE promote_candidate_to_employee (
    p_candidate_id   IN NUMBER,
    p_department_id  IN NUMBER,
    p_salary         IN NUMBER DEFAULT NULL,
    p_role           IN VARCHAR2 DEFAULT NULL
);
END source_requirement;
/

CREATE OR REPLACE PACKAGE BODY source_requirement AS
PROCEDURE add_candidate (
    p_first_name          IN VARCHAR2 DEFAULT NULL,
    p_last_name           IN VARCHAR2 DEFAULT NULL,
    p_email               IN VARCHAR2 DEFAULT NULL,
    p_phone               IN NUMBER   DEFAULT NULL,
    p_dob                 IN DATE     DEFAULT NULL,
    p_id_proof_type       IN VARCHAR2 DEFAULT NULL,
    p_id_proof_num        IN VARCHAR2 DEFAULT NULL,
    p_highest_degree      IN VARCHAR2 DEFAULT NULL,
    p_university          IN VARCHAR2 DEFAULT NULL,
    p_cgpa                IN NUMBER   DEFAULT NULL,
    p_city                IN VARCHAR2 DEFAULT NULL,
    p_country             IN VARCHAR2 DEFAULT NULL,
    p_last_employer       IN VARCHAR2 DEFAULT NULL,
    p_last_salary         IN NUMBER   DEFAULT NULL,
    p_expected_salary     IN NUMBER   DEFAULT NULL,
    p_years_of_experience IN NUMBER   DEFAULT NULL,
    p_skills              IN VARCHAR2 DEFAULT NULL,
    p_gender              IN CHAR     DEFAULT NULL,
    p_role                IN VARCHAR2 DEFAULT NULL
)
AS
    ln_candidate_id NUMBER;
    v_id_proof_type VARCHAR2(200);
    v_formatted_skills VARCHAR2(1000);
    v_item VARCHAR2(1000);


BEGIN
    ln_candidate_id := seq_candidate_id.NEXTVAL;
     IF UPPER(p_id_proof_type) = 'DL' THEN
        v_id_proof_type := 'DL';
    ELSE
        v_id_proof_type := INITCAP(p_id_proof_type);
    END IF;
        v_formatted_skills := '';
    IF p_skills IS NOT NULL THEN

        FOR i IN 1 .. REGEXP_COUNT(p_skills, '[^,]+') LOOP
            v_item := TRIM(REGEXP_SUBSTR(p_skills, '[^,]+', 1, i));
    
            -- Normalize and format known skills
            IF LOWER(v_item) IN ('deveop', 'deveops', 'devops') THEN
                v_item := 'DevOps';
            ELSIF LOWER(v_item) = 'js' THEN
                v_item := 'JavaScript';
            ELSIF LOWER(v_item) = 'ml' THEN
                v_item := 'ML';
            ELSIF LOWER(v_item) = 'ai' THEN
                v_item := 'AI';
            ELSIF LOWER(v_item) = 'dbms' THEN
                v_item := 'DBMS';
            ELSIF LOWER(v_item) = 'c' THEN
                v_item := 'C';
            ELSIF LOWER(v_item) = 'sql' THEN
                v_item := 'SQL';
            ELSIF LOWER(v_item) = 'html' THEN
                v_item := 'HTML';
            ELSIF LOWER(v_item) = 'css' THEN
                v_item := 'CSS';
            ELSIF LOWER(v_item) = 'hr' THEN
                v_item := 'HR';
            ELSIF LOWER(v_item) IN ('pl/sql', 'plsql') THEN
                v_item := 'PL/SQL';
            ELSE
                v_item := INITCAP(v_item);
            END IF;
    
            -- Rebuild final skills string
            IF i > 1 THEN
                v_formatted_skills := v_formatted_skills || ' ,' || v_item;
            ELSE
                v_formatted_skills := v_item;
            END IF;
        END LOOP;
    END IF;
    INSERT INTO candidates (
        candidate_id, first_name, last_name, email, phone, dob,
        id_proof_type, id_proof_num, highest_degree, university,
        cgpa, city, country, last_employer, last_salary,
        expected_salary, years_of_experience, skills, gender, role
    ) VALUES (
        ln_candidate_id, INITCAP(p_first_name),INITCAP( p_last_name), LOWER(p_email), p_phone, p_dob,
        v_id_proof_type,UPPER( p_id_proof_num),UPPER( p_highest_degree),UPPER( p_university),
        p_cgpa, INITCAP(p_city), INITCAP(p_country), INITCAP(p_last_employer), p_last_salary,
        p_expected_salary, p_years_of_experience,v_formatted_skills, initcap(p_gender), INITCAP(p_role)
    );

    DBMS_OUTPUT.PUT_LINE('Success: Candidate added with ID ' || ln_candidate_id);

EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -12899 THEN
            -- Extract column name from SQLERRM
            DECLARE
                v_err_col VARCHAR2(1000);
            BEGIN
                v_err_col := REGEXP_SUBSTR(SQLERRM, '"[^"]+"\."[^"]+"\."([^"]+)"', 1, 1, NULL, 1);
                DBMS_OUTPUT.PUT_LINE('Error: The value you entered for "' || INITCAP(v_err_col) || '" is too long. Please enter a shorter value.');
            END;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        END IF;
END add_candidate;


PROCEDURE update_candidate (
    p_candidate_id        IN NUMBER,
    p_first_name          IN VARCHAR2 DEFAULT NULL,
    p_last_name           IN VARCHAR2 DEFAULT NULL,
    p_email               IN VARCHAR2 DEFAULT NULL,
    p_phone               IN NUMBER   DEFAULT NULL,
    p_dob                 IN DATE     DEFAULT NULL,
    p_id_proof_type       IN VARCHAR2 DEFAULT NULL,
    p_id_proof_num        IN VARCHAR2 DEFAULT NULL,
    p_highest_degree      IN VARCHAR2 DEFAULT NULL,
    p_university          IN VARCHAR2 DEFAULT NULL,
    p_cgpa                IN NUMBER   DEFAULT NULL,
    p_city                IN VARCHAR2 DEFAULT NULL,
    p_country             IN VARCHAR2 DEFAULT NULL,
    p_last_employer       IN VARCHAR2 DEFAULT NULL,
    p_last_salary         IN NUMBER   DEFAULT NULL,
    p_expected_salary     IN NUMBER   DEFAULT NULL,
    p_years_of_experience IN NUMBER   DEFAULT NULL,
    p_skills              IN VARCHAR2 DEFAULT NULL,
    p_interview_status    IN VARCHAR2 DEFAULT NULL,
    p_rejection_reason    IN VARCHAR2 DEFAULT NULL,
    p_gender              IN CHAR     DEFAULT NULL,
    p_role                IN VARCHAR2 DEFAULT NULL
)
IS
    -- Old values
    old_row candidates%ROWTYPE;

    change_summary VARCHAR2(4000) := '';
    ln_rows_updated NUMBER;
    v_id_proof_type VARCHAR2(30);
    v_formatted_skills VARCHAR2(1000);
    v_item VARCHAR2(100);
    ln_status VARCHAR2(20);

    value_too_large EXCEPTION;
    PRAGMA EXCEPTION_INIT(value_too_large, -12899);
BEGIN
    -- Fetch original row for comparison
    SELECT status into ln_status FROM CANDIDATES WHERE CANDIDATE_ID=p_candidate_id;
    IF  ln_status='Inactive' THEN
    DBMS_OUTPUT.PUT_LINE('Cannot update the candidate details.Candidate Status is inactive');
    RETURN;
    END IF;
    SELECT * INTO old_row FROM candidates WHERE candidate_id = p_candidate_id;
      IF p_id_proof_type IS NOT NULL THEN
        IF UPPER(p_id_proof_type) IN ('DL', 'PAN') THEN
            v_id_proof_type := UPPER(p_id_proof_type);
        ELSIF LOWER(p_id_proof_type) = 'aadhar' THEN
            v_id_proof_type := 'Aadhar';
        ELSE
            v_id_proof_type := INITCAP(p_id_proof_type);
        END IF;
    END IF;

    -- === Format skills ===
    IF p_skills IS NOT NULL THEN
        v_formatted_skills := '';
        FOR i IN 1 .. REGEXP_COUNT(p_skills, '[^,]+') LOOP
            v_item := TRIM(REGEXP_SUBSTR(p_skills, '[^,]+', 1, i));

            IF LOWER(v_item) IN ('deveop', 'deveops', 'devops') THEN
                v_item := 'DevOps';
            ELSIF LOWER(v_item) = 'js' THEN
                v_item := 'JavaScript';
            ELSIF LOWER(v_item) = 'ml' THEN
                v_item := 'ML';
            ELSIF LOWER(v_item) = 'ai' THEN
                v_item := 'AI';
            ELSIF LOWER(v_item) = 'dbms' THEN
                v_item := 'DBMS';
            ELSIF LOWER(v_item) = 'c' THEN
                v_item := 'C';
            ELSIF LOWER(v_item) = 'sql' THEN
                v_item := 'SQL';
            ELSIF LOWER(v_item) = 'html' THEN
                v_item := 'HTML';
            ELSIF LOWER(v_item) = 'css' THEN
                v_item := 'CSS';
            ELSIF LOWER(v_item) = 'hr' THEN
                v_item := 'HR';
            ELSIF LOWER(v_item) IN ('pl/sql', 'plsql') THEN
                v_item := 'PL/SQL';
            ELSE
                v_item := INITCAP(v_item);
            END IF;

            -- Append to skill list
            IF i > 1 THEN
                v_formatted_skills := v_formatted_skills || ' ,' || v_item;
            ELSE
                v_formatted_skills := v_item;
            END IF;
        END LOOP;
    END IF;
    -- Perform update
    
    UPDATE candidates
    SET
        first_name          = NVL(INITCAP(p_first_name), first_name),
        last_name           = NVL(INITCAP(p_last_name), last_name),
        email               = NVL(LOWER(p_email), email),
        phone               = NVL(p_phone, phone),
        dob                 = NVL(p_dob, dob),
        id_proof_type       = NVL(v_id_proof_type, id_proof_type),
        id_proof_num        = NVL(UPPER(p_id_proof_num), id_proof_num),
        highest_degree      = NVL(UPPER(p_highest_degree), highest_degree),
        university          = NVL(UPPER(p_university), university),
        cgpa                = NVL(p_cgpa, cgpa),
        city                = NVL(INITCAP(p_city), city),
        country             = NVL(INITCAP(p_country), country),
        last_employer       = NVL(INITCAP(p_last_employer), last_employer),
        last_salary         = NVL(p_last_salary, last_salary),
        expected_salary     = NVL(p_expected_salary, expected_salary),
        years_of_experience = NVL(p_years_of_experience, years_of_experience),
        skills              = NVL(v_formatted_skills, skills),
        interview_status    = NVL(INITCAP(p_interview_status), interview_status),
        rejection_reason    = CASE 
                                WHEN LOWER(p_interview_status) = 'rejected' THEN NVL(INITCAP(p_rejection_reason), rejection_reason)
                                ELSE rejection_reason 
                              END,
        status = CASE 
            WHEN p_interview_status IS NOT NULL AND LOWER(p_interview_status) IN ('selected', 'rejected') THEN 'Inactive'
            WHEN p_interview_status IS NOT NULL AND LOWER(p_interview_status) = 'in progress' THEN 'Active'
            ELSE status
        END,
        gender              = NVL(initcap(p_gender), gender),
        role                = NVL(INITCAP(p_role), role)
    WHERE candidate_id = p_candidate_id;

    ln_rows_updated := SQL%ROWCOUNT;

    IF ln_rows_updated = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No candidate found with ID ' || p_candidate_id || '.');
    ELSE
        -- Build change message
        IF p_first_name IS NOT NULL AND p_first_name != old_row.first_name THEN
            change_summary := change_summary || 'First name changed to "' || p_first_name || '". ';
        END IF;
        IF p_last_name IS NOT NULL AND p_last_name != old_row.last_name THEN
            change_summary := change_summary || 'Last name changed to "' || p_last_name || '". ';
        END IF;
        IF p_email IS NOT NULL AND p_email != old_row.email THEN
            change_summary := change_summary || 'Email changed to "' || p_email || '". ';
        END IF;
        IF p_phone IS NOT NULL AND p_phone != old_row.phone THEN
            change_summary := change_summary || 'Phone changed to "' || p_phone || '". ';
        END IF;
        IF p_dob IS NOT NULL AND p_dob != old_row.dob THEN
            change_summary := change_summary || 'Date of birth updated to "' || TO_CHAR(p_dob, 'YYYY-MM-DD') || '". ';
        END IF;
        IF p_id_proof_type IS NOT NULL AND initcap(p_id_proof_type) != old_row.id_proof_type THEN
            change_summary := change_summary || 'ID proof type updated to "' || p_id_proof_type || '". ';
        END IF;
        IF p_id_proof_num IS NOT NULL AND p_id_proof_num != old_row.id_proof_num THEN
            change_summary := change_summary || 'ID proof number updated to "' || p_id_proof_num || '". ';
        END IF;
        IF p_highest_degree IS NOT NULL AND p_highest_degree != old_row.highest_degree THEN
            change_summary := change_summary || 'Degree updated to "' || p_highest_degree || '". ';
        END IF;
        IF p_university IS NOT NULL AND p_university != old_row.university THEN
            change_summary := change_summary || 'University updated to "' || p_university || '". ';
        END IF;
        IF p_cgpa IS NOT NULL AND p_cgpa != old_row.cgpa THEN
            change_summary := change_summary || 'CGPA updated to "' || p_cgpa || '". ';
        END IF;
        IF p_city IS NOT NULL AND p_city != old_row.city THEN
            change_summary := change_summary || 'City updated to "' || p_city || '". ';
        END IF;
        IF p_country IS NOT NULL AND p_country != old_row.country THEN
            change_summary := change_summary || 'Country updated to "' || p_country || '". ';
        END IF;
        IF p_last_employer IS NOT NULL AND p_last_employer != old_row.last_employer THEN
            change_summary := change_summary || 'Last employer updated to "' || p_last_employer || '". ';
        END IF;
        IF p_last_salary IS NOT NULL AND p_last_salary != old_row.last_salary THEN
            change_summary := change_summary || 'Last salary updated to "' || p_last_salary || '". ';
        END IF;
        IF p_expected_salary IS NOT NULL AND p_expected_salary != old_row.expected_salary THEN
            change_summary := change_summary || 'Expected salary updated to "' || p_expected_salary || '". ';
        END IF;
        IF p_years_of_experience IS NOT NULL AND p_years_of_experience != old_row.years_of_experience THEN
            change_summary := change_summary || 'Experience updated to "' || p_years_of_experience || '" years. ';
        END IF;
        IF p_skills IS NOT NULL AND p_skills != old_row.skills THEN
            change_summary := change_summary || 'Skills updated to "' || p_skills || '". ';
        END IF;
        IF p_interview_status IS NOT NULL AND p_interview_status != old_row.interview_status THEN
            change_summary := change_summary || 'Interview status changed to "' || p_interview_status || '". ';
        END IF;
        IF p_rejection_reason IS NOT NULL AND p_rejection_reason != old_row.rejection_reason THEN
            change_summary := change_summary || 'Rejection reason updated to "' || p_rejection_reason || '". ';
        END IF;
        IF p_gender IS NOT NULL AND upper(p_gender) != upper(old_row.gender) THEN
            change_summary := change_summary || 'Gender updated to "' || p_gender || '". ';
        END IF;
        IF p_role IS NOT NULL AND p_role != old_row.role THEN
            change_summary := change_summary || 'Role updated to "' || p_role || '". ';
        END IF;

        -- Final Output
        IF change_summary IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Success: Candidate "' || old_row.first_name || ' ' || old_row.last_name || '" (ID: ' || p_candidate_id || ') has been updated.');
            DBMS_OUTPUT.PUT_LINE('Changes: ' || change_summary);
        ELSE
            DBMS_OUTPUT.PUT_LINE('No changes were made.');    
        END IF;
    END IF;

EXCEPTION
    
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No candidate found with ID ' || p_candidate_id || '.');
    WHEN OTHERS THEN
        IF SQLCODE = -12899 THEN
            -- Extract column name from SQLERRM
            DECLARE
                v_err_col VARCHAR2(100);
            BEGIN
                v_err_col := REGEXP_SUBSTR(SQLERRM, '"[^"]+"\."[^"]+"\."([^"]+)"', 1, 1, NULL, 1);
                DBMS_OUTPUT.PUT_LINE('Error: The value you entered for "' || INITCAP(v_err_col) || '" is too long. Please enter a shorter value.');
            END;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        END IF;
END update_candidate;



PROCEDURE remove_candidate (
    p_candidate_id IN NUMBER
) IS
    e_candidate_not_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_candidate_not_found, -20001);

    ln_count NUMBER;
BEGIN
    -- Check existence
    SELECT COUNT(*) INTO ln_count
    FROM candidates
    WHERE candidate_id = p_candidate_id;

    IF ln_count = 0 THEN
        RAISE e_candidate_not_found;
    END IF;

    -- Delete
--    DELETE FROM candidates
--    WHERE candidate_id = p_candidate_id;

    DBMS_OUTPUT.PUT_LINE('Success: Candidate with ID ' || p_candidate_id || ' was removed.');

EXCEPTION
    WHEN e_candidate_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No candidate found with ID ' || p_candidate_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error while removing candidate: ' || SQLERRM);
END remove_candidate;

PROCEDURE list_candidates (
    p_country           IN VARCHAR2 DEFAULT NULL,
    p_city              IN VARCHAR2 DEFAULT NULL,
    p_skill             IN VARCHAR2 DEFAULT NULL,
    p_interview_status  IN VARCHAR2 DEFAULT NULL,
    p_id_proof_type     IN VARCHAR2 DEFAULT NULL,
    p_degree            IN VARCHAR2 DEFAULT NULL,
    p_status            IN VARCHAR2 DEFAULT NULL,
    p_role              IN VARCHAR2 DEFAULT NULL,
    p_university        IN VARCHAR2 DEFAULT NULL,
    p_first_name        IN VARCHAR2 DEFAULT NULL,
    p_last_name         IN VARCHAR2 DEFAULT NULL,
    p_exp               IN NUMBER DEFAULT NULL,
    p_last_employer     IN VARCHAR2 DEFAULT NULL,
    p_last_salary       IN NUMBER DEFAULT NULL,
    p_expected_salary    IN NUMBER DEFAULT NULL,
    p_cgpa              IN NUMBER DEFAULT NULL,
    p_dob    IN DATE DEFAULT NULL,
    p_rejection_reason    IN VARCHAR2 DEFAULT NULL,
    p_gender           IN VARCHAR2 DEFAULT NULL
    
)
IS
    CURSOR c_cand IS
        SELECT *
        FROM candidates
        WHERE
            (p_country IS NULL OR LOWER(country) LIKE '%'||LOWER(p_country)||'%') AND
            (p_city IS NULL OR LOWER(city) LIKE '%'||LOWER(p_city)||'%') AND
            (p_skill IS NULL OR LOWER(skills) LIKE '%' || LOWER(p_skill) || '%') AND
            (
                (p_interview_status IS NULL AND LOWER(interview_status) != 'rejected') OR
                (p_interview_status IS NOT NULL AND LOWER(interview_status) = LOWER(p_interview_status))
            )
            AND
            (p_id_proof_type IS NULL OR LOWER(id_proof_type) = LOWER(p_id_proof_type)) AND
            (p_degree IS NULL OR LOWER(highest_degree) LIKE '%'||LOWER(p_degree)||'%') AND
            (p_status IS NULL OR LOWER(status) = LOWER(p_status)) AND
            (p_role IS NULL OR LOWER(role) LIKE '%'||LOWER(p_role)||'%') AND
            (p_university IS NULL OR LOWER(university) LIKE '%' || LOWER(p_university)||'%') AND
            (p_first_name IS NULL OR LOWER(first_name) LIKE   '%'||LOWER(p_first_name)||'%') AND
            (p_last_name IS NULL OR LOWER(last_name) LIKE  '%'||LOWER(p_role)||'%')AND
            (p_exp IS NULL OR years_of_experience = p_exp) AND
            (p_last_employer IS NULL OR LOWER(last_employer) LIKE '%'|| LOWER(p_last_employer)||'%') AND
            (p_last_salary IS NULL OR last_salary = p_last_salary) AND
            (p_cgpa IS NULL OR cgpa= p_cgpa) AND            
            (p_expected_salary IS NULL OR expected_salary = p_expected_salary) AND
            (p_dob IS NULL OR dob = p_dob) AND
            (p_rejection_reason IS NULL OR LOWER(rejection_reason) LIKE '%'||LOWER(p_rejection_reason)||'%') AND
            (p_gender IS NULL OR upper(gender) = upper(p_gender));

    r c_cand%ROWTYPE;
    v_count NUMBER := 0;

    line_separator CONSTANT VARCHAR2(2000) :=
'+--------------+--------------+-------------+--------------------------+------------+------------+--------------------+--------------------------+--------------------+----------------------+--------+----------------+----------------+--------------------------+----------------+------------------+--------------------------+--------------------------+----------------------------+----------------------------+----------------+------------------------+-----------------------';

    header CONSTANT VARCHAR2(2000) :=
'| Candidate ID | First Name   | Last Name   | Email                    | Phone      | DOB        | ID Proof Type      | ID Proof Number          | Highest Degree     | University           | CGPA   | City           | Country        | Last Employer            | Last Salary    | Expected Salary  | Years of Experience      | Skills                   | Interview Status           | Rejection Reason           | Status         | role                   | gender                |';

BEGIN
    OPEN c_cand;
    LOOP
        FETCH c_cand INTO r;
        EXIT WHEN c_cand%NOTFOUND;

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE(line_separator);
            DBMS_OUTPUT.PUT_LINE(header);
            DBMS_OUTPUT.PUT_LINE(line_separator);
        END IF;

        v_count := v_count + 1;

        DBMS_OUTPUT.PUT_LINE(
            '| ' ||
            LPAD(r.candidate_id, 12) || ' | ' ||
            RPAD(r.first_name, 12) || ' | ' ||
            RPAD(r.last_name, 11) || ' | ' ||
            RPAD(SUBSTR(r.email, 1, 24), 24) || ' | ' ||
            LPAD(NVL(TO_CHAR(r.phone), 'N/A'), 10) || ' | ' ||
            NVL(TO_CHAR(r.dob, 'YYYY-MM-DD'), '          ') || ' | ' ||
            RPAD(NVL(r.id_proof_type, 'N/A'), 18) || ' | ' ||
            RPAD(NVL(r.id_proof_num, 'N/A'), 24) || ' | ' ||
            RPAD(r.highest_degree, 19) || ' | ' ||
            RPAD(r.university, 19) || ' | ' ||
            LPAD(TO_CHAR(r.cgpa, '0.0'), 5) || '  | ' ||
            RPAD(NVL(r.city, 'N/A'), 13) || '  | ' ||
            RPAD(NVL(r.country, 'N/A'), 14) || '  | ' ||
            RPAD(NVL(r.last_employer, 'N/A'), 24) || '| ' ||
            LPAD(NVL(TO_CHAR(r.last_salary), 'N/A'), 14) || ' | ' ||
            LPAD(NVL(TO_CHAR(r.expected_salary), 'N/A'), 16) || ' | ' ||
            LPAD(NVL(TO_CHAR(r.years_of_experience), '0'), 24) || ' | ' ||
            RPAD(SUBSTR(r.skills, 1, 26), 24) || ' | ' ||
            RPAD(NVL(r.interview_status, 'N/A'), 26) || ' | ' ||
            RPAD(NVL(r.rejection_reason, '-'), 26) || ' | ' ||            
            RPAD(NVL(r.status, 'N/A'), 15) || '|'||
            RPAD(NVL(r.role, 'N/A'), 23) || ' | ' ||
            RPAD(NVL(r.gender, 'N/A'), 23) || ' | '


        );
    END LOOP;
    CLOSE c_cand;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE(line_separator);
        DBMS_OUTPUT.PUT_LINE(v_count || ' candidate(s) listed.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('No candidates found matching the given criteria.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred while listing candidates: ' || SQLERRM);
END;

--PROCEDURE get_candidate_details (
--    p_candidate_id IN candidates.candidate_id%TYPE DEFAULT NULL,
--    p_email        IN candidates.email%TYPE DEFAULT NULL,
--    p_phone        IN candidates.phone%TYPE DEFAULT NULL,
--    p_id_proof_num IN candidates.id_proof_num%TYPE DEFAULT NULL,
--    p_section      IN VARCHAR2 DEFAULT NULL
--)
--IS
--    r_cand candidates%ROWTYPE;
--    e_invalid_section EXCEPTION;
--
--BEGIN
--    -- Step 1: Fetch candidate based on any identifier
--    SELECT *
--INTO r_cand
--FROM candidates
--WHERE
--    (p_candidate_id IS NULL OR candidate_id = p_candidate_id) AND
--    (p_email IS NULL OR LOWER(email) = LOWER(p_email)) AND
--    (p_phone IS NULL OR phone = p_phone) AND
--    (p_id_proof_num IS NULL OR id_proof_num = p_id_proof_num);
--
--
--    -- Step 2: Display details based on section
--    IF p_section IS NULL THEN
--        DBMS_OUTPUT.PUT_LINE('======================= CANDIDATE FULL DETAILS =======================');
--        
--        -- PERSONAL
--        DBMS_OUTPUT.PUT_LINE('PERSONAL INFORMATION');
--        DBMS_OUTPUT.PUT_LINE('Name            : ' || r_cand.first_name || ' ' || r_cand.last_name);
--        DBMS_OUTPUT.PUT_LINE('DOB             : ' || TO_CHAR(r_cand.dob, 'YYYY-MM-DD'));
--        DBMS_OUTPUT.PUT_LINE('Gender          : ' || NVL(r_cand.gender, 'N/A'));
--        DBMS_OUTPUT.PUT_LINE('Email           : ' || r_cand.email);
--        DBMS_OUTPUT.PUT_LINE('Phone           : ' || r_cand.phone);
--        DBMS_OUTPUT.PUT_LINE('Location        : ' || NVL(r_cand.city, 'N/A') || ', ' || NVL(r_cand.country, 'N/A'));
--        DBMS_OUTPUT.PUT_LINE('ID Proof        : ' || r_cand.id_proof_type || ' - ' || r_cand.id_proof_num);
--        
--        -- ACADEMIC
--        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ACADEMIC INFORMATION');
--        DBMS_OUTPUT.PUT_LINE('Highest Degree  : ' || r_cand.highest_degree);
--        DBMS_OUTPUT.PUT_LINE('University      : ' || r_cand.university);
--        DBMS_OUTPUT.PUT_LINE('CGPA            : ' || r_cand.cgpa);
--
--        -- PROFESSIONAL
--        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'PROFESSIONAL INFORMATION');
--        DBMS_OUTPUT.PUT_LINE('Last Employer   : ' || NVL(r_cand.last_employer, 'N/A'));
--        DBMS_OUTPUT.PUT_LINE('Last Salary     : ' || NVL(TO_CHAR(r_cand.last_salary), 'N/A'));
--        DBMS_OUTPUT.PUT_LINE('Expected Salary : ' || NVL(TO_CHAR(r_cand.expected_salary), 'N/A'));
--        DBMS_OUTPUT.PUT_LINE('Experience (yrs): ' || r_cand.years_of_experience);
--        DBMS_OUTPUT.PUT_LINE('Skill Set       : ' || r_cand.skills);
--        DBMS_OUTPUT.PUT_LINE('Interview Status: ' || r_cand.interview_status);
--        DBMS_OUTPUT.PUT_LINE('Status          : ' || r_cand.status);
--        DBMS_OUTPUT.PUT_LINE('======================================================================');
--
--    ELSE
--        CASE UPPER(TRIM(p_section))
--            WHEN 'PERSONAL' THEN
--                DBMS_OUTPUT.PUT_LINE('PERSONAL INFORMATION');
--                DBMS_OUTPUT.PUT_LINE('Name            : ' || r_cand.first_name || ' ' || r_cand.last_name);
--                DBMS_OUTPUT.PUT_LINE('DOB             : ' || TO_CHAR(r_cand.dob, 'YYYY-MM-DD'));
--                DBMS_OUTPUT.PUT_LINE('Gender          : ' || NVL(r_cand.gender, 'N/A'));
--                DBMS_OUTPUT.PUT_LINE('Email           : ' || r_cand.email);
--                DBMS_OUTPUT.PUT_LINE('Phone           : ' || r_cand.phone);
--                DBMS_OUTPUT.PUT_LINE('Location        : ' || NVL(r_cand.city, 'N/A') || ', ' || NVL(r_cand.country, 'N/A'));
--                DBMS_OUTPUT.PUT_LINE('ID Proof        : ' || r_cand.id_proof_type || ' - ' || r_cand.id_proof_num);
--
--            WHEN 'ACADEMIC' THEN
--                DBMS_OUTPUT.PUT_LINE(' ACADEMIC INFORMATION');
--                DBMS_OUTPUT.PUT_LINE('Highest Degree  : ' || r_cand.highest_degree);
--                DBMS_OUTPUT.PUT_LINE('University      : ' || r_cand.university);
--                DBMS_OUTPUT.PUT_LINE('CGPA            : ' || r_cand.cgpa);
--
--            WHEN 'PROFESSIONAL' THEN
--                DBMS_OUTPUT.PUT_LINE('PROFESSIONAL INFORMATION');
--                DBMS_OUTPUT.PUT_LINE('Last Employer   : ' || NVL(r_cand.last_employer, 'N/A'));
--                DBMS_OUTPUT.PUT_LINE('Last Salary     : ' || NVL(TO_CHAR(r_cand.last_salary), 'N/A'));
--                DBMS_OUTPUT.PUT_LINE('Expected Salary : ' || NVL(TO_CHAR(r_cand.expected_salary), 'N/A'));
--                DBMS_OUTPUT.PUT_LINE('Experience (yrs): ' || r_cand.years_of_experience);
--                DBMS_OUTPUT.PUT_LINE('Skill Set       : ' || r_cand.skills);
--                DBMS_OUTPUT.PUT_LINE('Interview Status: ' || r_cand.interview_status);
--                DBMS_OUTPUT.PUT_LINE('Status          : ' || r_cand.status);
--
--            ELSE
--                RAISE e_invalid_section;
--        END CASE;
--    END IF;
--
--EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--        DBMS_OUTPUT.PUT_LINE('No candidate found matching the given ID/email/phone/proof number.');
--
--    WHEN e_invalid_section THEN
--        DBMS_OUTPUT.PUT_LINE('Invalid section "' || p_section || '". Use PERSONAL, ACADEMIC, or PROFESSIONAL.');
--
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
--END;

PROCEDURE get_candidate_details (
    p_candidate_id IN candidates.candidate_id%TYPE DEFAULT NULL,
    p_email        IN candidates.email%TYPE DEFAULT NULL,
    p_phone        IN candidates.phone%TYPE DEFAULT NULL,
    p_id_proof_num IN candidates.id_proof_num%TYPE DEFAULT NULL,
   p_detail_type     IN VARCHAR2 DEFAULT NULL
)
IS
    r_cand candidates%ROWTYPE;
    e_invalid_section EXCEPTION;
    valid_section BOOLEAN := TRUE;

BEGIN
    ------------------------------------------------------------------
    -- Step 1: Validate Section First
    ------------------------------------------------------------------
    IF p_detail_type IS NOT NULL THEN
        CASE UPPER(TRIM(p_detail_type))
            WHEN 'PERSONAL' THEN NULL;
            WHEN 'ACADEMIC' THEN NULL;
            WHEN 'PROFESSIONAL' THEN NULL;
            ELSE
                valid_section := FALSE;
                RAISE e_invalid_section;
        END CASE;
    END IF;

    ------------------------------------------------------------------
    -- Step 2: Fetch candidate based on any identifier
    ------------------------------------------------------------------
    BEGIN
        SELECT *
        INTO r_cand
        FROM candidates
        WHERE
            (p_candidate_id IS NULL OR candidate_id = p_candidate_id) AND
            (p_email IS NULL OR LOWER(email) = LOWER(p_email)) AND
            (p_phone IS NULL OR phone = p_phone) AND
            (p_id_proof_num IS NULL OR LOWER(id_proof_num) = LOWER(p_id_proof_num));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF NOT valid_section THEN
                DBMS_OUTPUT.PUT_LINE('Invalid section "' || p_detail_type || '". Use PERSONAL, ACADEMIC, or PROFESSIONAL.');
            END IF;
            DBMS_OUTPUT.PUT_LINE('No candidate found for the given details. Please check candidate ID, email, phone, or ID proof number.');
            RETURN;
    END;

    ------------------------------------------------------------------
    -- Step 3: Display Details
    ------------------------------------------------------------------
    IF p_detail_type IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('======================= CANDIDATE FULL DETAILS =======================');
        
        -- PERSONAL
        DBMS_OUTPUT.PUT_LINE('PERSONAL INFORMATION');
        DBMS_OUTPUT.PUT_LINE('Name            : ' || r_cand.first_name || ' ' || r_cand.last_name);
        DBMS_OUTPUT.PUT_LINE('DOB             : ' || TO_CHAR(r_cand.dob, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Gender          : ' || NVL(r_cand.gender, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('Email           : ' || r_cand.email);
        DBMS_OUTPUT.PUT_LINE('Phone           : ' || r_cand.phone);
        DBMS_OUTPUT.PUT_LINE('Location        : ' || NVL(r_cand.city, 'N/A') || ', ' || NVL(r_cand.country, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('ID Proof        : ' || r_cand.id_proof_type || ' - ' || r_cand.id_proof_num);
        
        -- ACADEMIC
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'ACADEMIC INFORMATION');
        DBMS_OUTPUT.PUT_LINE('Highest Degree  : ' || r_cand.highest_degree);
        DBMS_OUTPUT.PUT_LINE('University      : ' || r_cand.university);
        DBMS_OUTPUT.PUT_LINE('CGPA            : ' || r_cand.cgpa);

        -- PROFESSIONAL
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'PROFESSIONAL INFORMATION');
        DBMS_OUTPUT.PUT_LINE('Last Employer   : ' || NVL(r_cand.last_employer, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('Last Salary     : ' || NVL(TO_CHAR(r_cand.last_salary), 'N/A'));
        DBMS_OUTPUT.PUT_LINE('Expected Salary : ' || NVL(TO_CHAR(r_cand.expected_salary), 'N/A'));
        DBMS_OUTPUT.PUT_LINE('Experience (yrs): ' || r_cand.years_of_experience);
        DBMS_OUTPUT.PUT_LINE('Skill Set       : ' || r_cand.skills);
        DBMS_OUTPUT.PUT_LINE('Interview Status: ' || r_cand.interview_status);
        DBMS_OUTPUT.PUT_LINE('Status          : ' || r_cand.status);
        DBMS_OUTPUT.PUT_LINE('======================================================================');

    ELSE
        CASE UPPER(TRIM(p_detail_type))
            WHEN 'PERSONAL' THEN
                DBMS_OUTPUT.PUT_LINE('PERSONAL INFORMATION');
                DBMS_OUTPUT.PUT_LINE('Name            : ' || r_cand.first_name || ' ' || r_cand.last_name);
                DBMS_OUTPUT.PUT_LINE('DOB             : ' || TO_CHAR(r_cand.dob, 'YYYY-MM-DD'));
                DBMS_OUTPUT.PUT_LINE('Gender          : ' || NVL(r_cand.gender, 'N/A'));
                DBMS_OUTPUT.PUT_LINE('Email           : ' || r_cand.email);
                DBMS_OUTPUT.PUT_LINE('Phone           : ' || r_cand.phone);
                DBMS_OUTPUT.PUT_LINE('Location        : ' || NVL(r_cand.city, 'N/A') || ', ' || NVL(r_cand.country, 'N/A'));
                DBMS_OUTPUT.PUT_LINE('ID Proof        : ' || r_cand.id_proof_type || ' - ' || r_cand.id_proof_num);

            WHEN 'ACADEMIC' THEN
                DBMS_OUTPUT.PUT_LINE('ACADEMIC INFORMATION');
                DBMS_OUTPUT.PUT_LINE('Highest Degree  : ' || r_cand.highest_degree);
                DBMS_OUTPUT.PUT_LINE('University      : ' || r_cand.university);
                DBMS_OUTPUT.PUT_LINE('CGPA            : ' || r_cand.cgpa);

            WHEN 'PROFESSIONAL' THEN
                DBMS_OUTPUT.PUT_LINE('PROFESSIONAL INFORMATION');
                DBMS_OUTPUT.PUT_LINE('Last Employer   : ' || NVL(r_cand.last_employer, 'N/A'));
                DBMS_OUTPUT.PUT_LINE('Last Salary     : ' || NVL(TO_CHAR(r_cand.last_salary), 'N/A'));
                DBMS_OUTPUT.PUT_LINE('Expected Salary : ' || NVL(TO_CHAR(r_cand.expected_salary), 'N/A'));
                DBMS_OUTPUT.PUT_LINE('Experience (yrs): ' || r_cand.years_of_experience);
                DBMS_OUTPUT.PUT_LINE('Skill Set       : ' || r_cand.skills);
                DBMS_OUTPUT.PUT_LINE('Interview Status: ' || r_cand.interview_status);
                DBMS_OUTPUT.PUT_LINE('Status          : ' || r_cand.status);
        END CASE;
    END IF;

EXCEPTION
    WHEN e_invalid_section THEN
        DBMS_OUTPUT.PUT_LINE('Invalid section "' || p_detail_type || '". Use PERSONAL, ACADEMIC, or PROFESSIONAL.');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;

-- Promote a selected candidate to employee
PROCEDURE promote_candidate_to_employee (
    p_candidate_id   IN NUMBER,
    p_department_id  IN NUMBER,
    p_salary         IN NUMBER DEFAULT NULL,
    p_role           IN VARCHAR2 DEFAULT NULL

) IS
    
    v_skill        candidates.skills%TYPE;
    v_exp          candidates.years_of_experience%TYPE;
    v_salary       NUMBER;
    v_band_id      baseline_salary.band_id%TYPE;
    v_new_emp_id   employee.employee_id%TYPE;
    v_role         candidates.role%TYPE;
    v_manager_id   employee.employee_id%TYPE;
    v_band_found   BOOLEAN := FALSE;
    v_status       candidates.interview_status%TYPE;
    ln_exists      NUMBER;  
BEGIN
    -- Step 1: Fetch candidate details
    BEGIN
    SELECT 1 INTO ln_exists
    FROM employee
    WHERE candidate_id = p_candidate_id;
    -- If found, candidate already promoted
    DBMS_OUTPUT.PUT_LINE('Candidate is already an employee.');
    RETURN;
    EXCEPTION
            WHEN no_data_found THEN
            NULL;
   END;
    
    SELECT skills, years_of_experience,
           COALESCE(p_salary, expected_salary), role, interview_status
    INTO  v_skill, v_exp, v_salary,  v_role, v_status
    FROM candidates
    WHERE candidate_id = p_candidate_id;
    
    v_role:=NVL(p_role,v_role);

    -- Step 1b: Validate interview status
    IF v_status != 'Selected' THEN
        IF v_status = 'In Progress' THEN
            DBMS_OUTPUT.PUT_LINE('Cannot promote: Candidate interview is still in progress.');
            RETURN;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Cannot promote: Candidate interview was not successful.');
            RETURN;
        END IF;
    END IF;

    -- Step 2: Try to find a suitable band based on salary and experience
    BEGIN
        SELECT band_id
        INTO v_band_id
        FROM baseline_salary
        WHERE job_title = v_role
          AND v_salary BETWEEN min_salary AND max_salary
          AND v_exp BETWEEN min_exp AND max_exp
        ORDER BY min_exp DESC
        FETCH FIRST 1 ROWS ONLY;

        v_band_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- Try fallback logic
    END;

    -- Step 2b: Fallback - if experience is beyond defined range
    IF NOT v_band_found THEN
        BEGIN
            SELECT band_id
            INTO v_band_id
            FROM baseline_salary
            WHERE job_title = v_role
              AND v_salary BETWEEN min_salary AND max_salary
              AND max_exp = (
                SELECT MAX(max_exp)
                FROM baseline_salary
                WHERE job_title = v_role
              );
            v_band_found := TRUE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No suitable salary band found for the candidate''s role, experience, and salary.');
            RETURN;
        END;
    END IF;

    -- Step 3: Fetch department manager, if available
    BEGIN
        SELECT manager_id
        INTO v_manager_id
        FROM department
        WHERE department_id = p_department_id
          AND manager_id IS NOT NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_manager_id := NULL; -- Proceed without manager
    END;

    -- Step 4: Generate new employee ID
    SELECT employee_seq.NEXTVAL INTO v_new_emp_id FROM dual;

    -- Step 5: Insert new employee record
    INSERT INTO employee (
        employee_id, candidate_id, 
        salary, department_id, date_of_joining, band_id,
        manager_id, employee_status, leaves_balance, role
    ) VALUES (
        v_new_emp_id, p_candidate_id,
        v_salary, p_department_id, SYSDATE, v_band_id,
        v_manager_id, 'Active', (12 - EXTRACT(MONTH FROM sysdate) + 1) * 2,  INITCAP(v_role)
    );

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Candidate ID ' || p_candidate_id || ' has been successfully promoted to Employee ID ' || v_new_emp_id || '.');
    
    IF v_manager_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Note: No department manager was assigned for department ID ' || p_department_id || '.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Assigned Manager ID: ' || v_manager_id);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Candidate not found. Please check the Candidate ID.');        
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Candidate already promoted to employee.');        
    WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unexpected error occurred: ' || SQLERRM);        
END;
END;
/
--DROP SEQUENCE seq_candidate_id;

CREATE SEQUENCE seq_candidate_id
START WITH 81
INCREMENT BY 1
NOCACHE;

CREATE OR REPLACE TRIGGER trg_validate_candidates
BEFORE INSERT OR UPDATE ON candidates
FOR EACH ROW
DECLARE
    lv2_type VARCHAR2(200);
    ln_age NUMBER;
    lv_error_msgs VARCHAR2(4000);
    l_count NUMBER;

BEGIN
    -------------------------------------------------------------------
    -- Mandatory Fields Validation: Collect all missing ones
    -------------------------------------------------------------------
    lv_error_msgs := '';
    IF INSERTING OR UPDATING('first_name') THEN
        IF :NEW.first_name IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- First name is missing.' || CHR(10);
        ELSIF LENGTH(:NEW.first_name) < 2 OR NOT REGEXP_LIKE(:NEW.first_name, '^[A-Za-z]+$') THEN
            lv_error_msgs := lv_error_msgs || '- First name must be at least 2 alphabetic characters.' || CHR(10);
        END IF;
    END IF;
        -------------------------------------------------------------------
    -- Last Name
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('last_name') THEN
        IF :NEW.last_name IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Last name is missing.' || CHR(10);
        ELSIF LENGTH(:NEW.last_name) < 2 OR NOT REGEXP_LIKE(:NEW.last_name, '^[A-Za-z]+$') THEN
            lv_error_msgs := lv_error_msgs || '- Last name must be at least 2 alphabetic characters.' || CHR(10);
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- Email
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('email') THEN
        IF :NEW.email IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Email is missing.' || CHR(10);
        ELSIF NOT REGEXP_LIKE(:NEW.email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            lv_error_msgs := lv_error_msgs || '- Invalid email format and a valid email address like user@example.com' || CHR(10);
        END IF;
    END IF;
        -------------------------------------------------------------------
    -- Phone
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('Phone') THEN
        IF :NEW.phone IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Phone number is missing.' || CHR(10);
        ELSIF :NEW.phone IS NOT NULL THEN
            IF LENGTH(:NEW.phone) != 10 OR SUBSTR(:NEW.phone, 1, 1) NOT IN ('6','7','8','9') THEN
                lv_error_msgs := lv_error_msgs ||'- Phone must be 10 digits and start with 6-9.'|| CHR(10);
            END IF;
        END IF;
    END IF;

    -------------------------------------------------------------------

   -------------------------------------------------------------------
    -- DOB + Age Check
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('dob') THEN
        IF :NEW.dob IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Date of birth is missing.' || CHR(10);
        ELSE
            SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, :NEW.dob)/12) INTO ln_age FROM DUAL;
            IF ln_age < 18 OR ln_age > 65 THEN
                lv_error_msgs := lv_error_msgs || '- Age must be between 18 and 65.' || CHR(10);
            END IF;

            IF :NEW.years_of_experience IS NOT NULL THEN
                IF :NEW.years_of_experience < 0 THEN
                    lv_error_msgs := lv_error_msgs || '- Experience cannot be negative.' || CHR(10);
                ELSIF :NEW.years_of_experience > (ln_age - 18) THEN
                    lv_error_msgs := lv_error_msgs || '- Experience too high for your age.' || CHR(10);
                ELSIF ln_age = 18 AND :NEW.years_of_experience != 0 THEN
                    lv_error_msgs := lv_error_msgs || '- Experience must be 0 if age is 18.' || CHR(10);
                END IF;
            END IF;
        END IF;
    END IF;
      -------------------------------------------------------------------
    -- Gender
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('gender') THEN
        IF :NEW.gender IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Gender is missing.' || CHR(10);
        ELSIF LOWER(:NEW.gender) NOT IN ('m', 'f') THEN
            lv_error_msgs := lv_error_msgs || '- Gender must be "M" or "F".' || CHR(10);
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- ID Proof Type
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('id_proof_type') THEN
        IF :NEW.id_proof_type IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- ID proof type is required.' || CHR(10);
        ELSIF :NEW.id_proof_type IS NOT NULL THEN
            lv2_type := UPPER(:NEW.id_proof_type);
            IF lv2_type NOT IN ('AADHAR', 'PASSPORT', 'DL') THEN
                lv_error_msgs := lv_error_msgs || '- ID proof type must be Aadhar, Passport, or DL.' || CHR(10);
            END IF;
        ELSE
            SELECT id_proof_type INTO lv2_type FROM candidates WHERE candidate_id = :NEW.candidate_id;
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- ID Proof Number
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('id_proof_num') THEN
        IF :NEW.id_proof_num IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- ID proof number is required.' || CHR(10);
        ELSIF lv2_type IS NOT NULL THEN
            IF UPPER(lv2_type) = 'AADHAR' AND NOT REGEXP_LIKE(:NEW.id_proof_num, '^[2-9][0-9]{11}$') THEN
                lv_error_msgs := lv_error_msgs || '- Invalid Aadhar number. Must be 12 digits starting from 2�9.' || CHR(10);
            ELSIF UPPER(lv2_type) = 'PASSPORT' AND NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Za-z][0-9]{7}$') THEN
                lv_error_msgs := lv_error_msgs || '- Invalid Passport number. Format: A1234567.' || CHR(10);
            ELSIF UPPER(lv2_type) = 'DL' AND NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Za-z0-9]{13,15}$') THEN
                lv_error_msgs := lv_error_msgs || '- Invalid DL number. Must be 13�15 alphanumeric characters.' || CHR(10);
            END IF;
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- City
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('city') THEN
        IF :NEW.city IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- City is required.' || CHR(10);
        ELSIF NOT REGEXP_LIKE(:NEW.city, '^[A-Za-z ]+$') THEN
            lv_error_msgs := lv_error_msgs || '- City must contain only letters and spaces.' || CHR(10);
        END IF;
    END IF;
       -------------------------------------------------------------------
    -- Country
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('country') THEN
        IF :NEW.country IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Country is required.' || CHR(10);
        ELSIF NOT REGEXP_LIKE(:NEW.country, '^[A-Za-z ]+$') THEN
            lv_error_msgs := lv_error_msgs || '- Country must contain only letters and spaces.' || CHR(10);
        END IF;
    END IF;

    -------------------------------------------------------------------
    -- Highest Degree
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('highest_degree') THEN
        IF :NEW.highest_degree IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Highest degree is required.' || CHR(10);
        ELSIF LENGTH(:NEW.highest_degree) < 2 THEN
            lv_error_msgs := lv_error_msgs || '- Highest degree must be at least 2 characters.' || CHR(10);
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- University
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('university') THEN
        IF :NEW.university IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- University is required.' || CHR(10);
        ELSIF LENGTH(:NEW.university) < 2 THEN
            lv_error_msgs := lv_error_msgs || '- University must be at least 2 characters.' || CHR(10);
        END IF;
    END IF;

    -------------------------------------------------------------------
    -- CGPA
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('cgpa') THEN
        IF :NEW.cgpa IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- CGPA is required.' || CHR(10);
        ELSIF :NEW.cgpa < 0 OR :NEW.cgpa > 10 THEN
            lv_error_msgs := lv_error_msgs || '- CGPA must be between 0 and 10.' || CHR(10);
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- Skills
    -------------------------------------------------------------------
    IF INSERTING OR UPDATING('skills') THEN
        IF :NEW.skills IS NULL THEN
            lv_error_msgs := lv_error_msgs || '- Skills are required.' || CHR(10);
        ELSIF :NEW.skills IS NOT NULL THEN
            IF LENGTH(:NEW.skills) < 1 THEN
               lv_error_msgs := lv_error_msgs ||'- Skills must be at least 1 characters.'||CHR(10);
            END IF;
        END IF;
    END IF;
 -------------------------------------------------------------------
    -- Salary Comparison
    -------------------------------------------------------------------
    IF :NEW.last_salary IS NOT NULL AND :NEW.expected_salary IS NOT NULL THEN
        IF :NEW.expected_salary < :NEW.last_salary THEN
            lv_error_msgs := lv_error_msgs || '- Expected salary must be >= last salary.' || CHR(10);
        END IF;
    END IF;
    -------------------------------------------------------------------
    -- Status
    -------------------------------------------------------------------
    IF :NEW.status IS NOT NULL THEN
        IF LOWER(:NEW.status) NOT IN ('active', 'inactive') THEN
            lv_error_msgs := lv_error_msgs || '- Status must be either "active" or "inactive".' || CHR(10);
        END IF;
    END IF;
    --------------------------------------------------------------------
    ---ROLE
    ---------------------------------------------------------------------
    IF INSERTING OR UPDATING('role') THEN
       IF :NEW.role IS NULL THEN
        lv_error_msgs := lv_error_msgs || '- Role is required.' || CHR(10);
        ELSIF NOT REGEXP_LIKE(:NEW.role, '^[A-Za-z ]+$') THEN
            lv_error_msgs := lv_error_msgs || '- Role must contain only letters and spaces.' || CHR(10);
        END IF;
    END IF;


-- Validate 'interview_status' if provided
    IF :NEW.interview_status IS NOT NULL THEN
        IF LOWER(:NEW.interview_status) NOT IN ('selected', 'rejected', 'in progress') THEN
            lv_error_msgs := lv_error_msgs || '- Interview status must be "selected", "rejected", or "in progress".' || CHR(10);
        END IF;
    
        -- If interview_status is rejected, rejection_reason must be provided
        IF LOWER(:NEW.interview_status) = 'rejected' AND (:NEW.rejection_reason IS NULL OR TRIM(:NEW.rejection_reason) = '') THEN
            lv_error_msgs := lv_error_msgs || '- Rejection reason is required when interview status is "rejected".' || CHR(10);
        END IF;
    END IF;

    IF lv_error_msgs IS NOT NULL THEN
            
             RAISE_APPLICATION_ERROR(-20001,'Your input could not be saved due to the following issues:' || CHR(10) || lv_error_msgs);
          
    END IF;

END;
/
--  IF INSERTING THEN
--    lv_error_msgs := '';
--
--    IF :NEW.first_name IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'First name is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.last_name IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Last name is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.email IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Email address is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.phone IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Phone number is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.dob IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Date of birth is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.gender IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Gender is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.id_proof_type IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'ID proof type is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.id_proof_num IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'ID proof number is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.city IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'City is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.country IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Country is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.highest_degree IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Highest degree is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.university IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'University name is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.cgpa IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'CGPA is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.skills IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Skills field is missing.' || CHR(10);
--    END IF;
--
--    IF :NEW.role IS NULL THEN 
--        lv_error_msgs := lv_error_msgs || 'Role is missing.' || CHR(10);
--    END IF;
--
--    -- Raise error if anything missing
--    IF lv_error_msgs IS NOT NULL THEN
--        RAISE_APPLICATION_ERROR(-20100,
--            'Please correct the following issues before submitting:' || CHR(10) || lv_error_msgs);
--    END IF;
--END IF;

--    -------------------------------------------------------------------
--    -- First Name
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.first_name IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20001, 'First name is required.');
--    ELSIF :NEW.first_name IS NOT NULL THEN
--        IF LENGTH(:NEW.first_name) < 2 OR NOT REGEXP_LIKE(:NEW.first_name, '^[A-Za-z]+$') THEN
--            RAISE_APPLICATION_ERROR(-20002, 'First name must be at least 2 alphabetic characters.');
--        END IF;
--    END IF;
--
--    -------------------------------------------------------------------
--    -- Last Name
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.last_name IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20003, 'Last name is required.');
--    ELSIF :NEW.last_name IS NOT NULL THEN
--        IF LENGTH(:NEW.last_name) < 2 OR NOT REGEXP_LIKE(:NEW.last_name, '^[A-Za-z]+$') THEN
--            RAISE_APPLICATION_ERROR(-20004, 'Last name must be at least 2 alphabetic characters.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- Email
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.email IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20005, 'Email is required.');
--    ELSIF :NEW.email IS NOT NULL THEN
--        IF NOT REGEXP_LIKE(:NEW.email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
--            RAISE_APPLICATION_ERROR(-20006, 'Please enter a valid email address like user@example.com.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- Phone
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.phone IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20007, 'Phone number is required.');
--    ELSIF :NEW.phone IS NOT NULL THEN
--        IF LENGTH(:NEW.phone) != 10 OR SUBSTR(:NEW.phone, 1, 1) NOT IN ('6','7','8','9') THEN
--            RAISE_APPLICATION_ERROR(-20008, 'Phone must be 10 digits and start with 6-9.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- DOB
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.dob IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20009, 'Date of birth is required.');
--    ELSIF :NEW.dob IS NOT NULL THEN
--        SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, :NEW.dob)/12) INTO ln_age FROM DUAL;
--        IF ln_age < 18 OR ln_age > 65 THEN
--            RAISE_APPLICATION_ERROR(-20010, 'Age must be between 18 and 65.');
--        END IF;
--        IF :NEW.years_of_experience IS NOT NULL THEN
--            IF :NEW.years_of_experience < 0 THEN
--                RAISE_APPLICATION_ERROR(-20006, 'Experience cannot be negative.');
--            ELSIF :NEW.years_of_experience > (ln_age - 18) THEN
--                RAISE_APPLICATION_ERROR(-20007, 'Experience is too high for your age. Please verify.');
--            ELSIF ln_age = 18 AND :NEW.years_of_experience != 0 THEN
--                RAISE_APPLICATION_ERROR(-20008, 'If your age is 18, your experience must be 0.');
--            END IF;
--        END IF;
--
--    END IF;

--    -------------------------------------------------------------------
--    -- Gender
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.gender IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20011, 'Gender is required.');
--    ELSIF :NEW.gender IS NOT NULL THEN
--        IF UPPER(:NEW.gender) NOT IN ('M', 'F') THEN
--            RAISE_APPLICATION_ERROR(-20012, 'Gender must be either M or F.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- ID Proof Type
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.id_proof_type IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20013, 'ID proof type is required.');
--    ELSIF :NEW.id_proof_type IS NOT NULL THEN
--        lv2_type := UPPER(:NEW.id_proof_type);
--        IF lv2_type NOT IN ('AADHAR', 'PASSPORT', 'DL') THEN
--            RAISE_APPLICATION_ERROR(-20014, 'ID proof type must be Aadhar, Passport, or DL.');
--        END IF;
--    ELSE
--        SELECT id_proof_type INTO lv2_type FROM candidates WHERE candidate_id = :NEW.candidate_id;
--    END IF;

--    -------------------------------------------------------------------
--    -- ID Proof Number
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.id_proof_num IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20015, 'ID proof number is required.');
--    ELSIF :NEW.id_proof_num IS NOT NULL THEN
--       IF lv2_type = 'AADHAR' THEN
--            IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[2-9][0-9]{11}$') THEN
--                RAISE_APPLICATION_ERROR(-20016, 'Invalid Aadhar number. It must be 12 digits and start with a digit from 2 to 9.');
--            END IF;
--        ELSIF lv2_type = 'PASSPORT' THEN
--            IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Za-z][0-9]{7}$') THEN
--                RAISE_APPLICATION_ERROR(-20017, 'Invalid Passport number. Format: A1234567.');
--            END IF;
--        ELSIF lv2_type = 'DL' THEN
--            IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Za-z0-9]{13,15}$') THEN
--                RAISE_APPLICATION_ERROR(-20018, 'Invalid DL number. Must be alphanumeric (13-15 characters).');
--            END IF;
--
--        END IF;
--    END IF;
--
--    -------------------------------------------------------------------
--    -- City
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.city IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20019, 'City is required.');
--    ELSIF :NEW.city IS NOT NULL THEN
--        IF NOT REGEXP_LIKE(:NEW.city, '^[A-Za-z ]+$') THEN
--            RAISE_APPLICATION_ERROR(-20020, 'City name must contain only spaces and alphabetic characters.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- Country
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.country IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20021, 'Country is required.');
--    ELSIF :NEW.country IS NOT NULL THEN
--        IF NOT REGEXP_LIKE(:NEW.country, '^[A-Za-z ]+$') THEN
--            RAISE_APPLICATION_ERROR(-20022, 'Country name must contain only spaces and alphabetic characters.');
--        END IF;
--    END IF;
--
--    -------------------------------------------------------------------
--    -- Highest Degree
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.highest_degree IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20023, 'Highest degree is required.');
--    ELSIF :NEW.highest_degree IS NOT NULL THEN
--        IF LENGTH(:NEW.highest_degree) < 2 THEN
--            RAISE_APPLICATION_ERROR(-20024, 'Highest degree must be at least 2 characters.');
--        END IF;
--    END IF;
--
--    -------------------------------------------------------------------
--    -- University
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.university IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20025, 'University is required.');
--    ELSIF :NEW.university IS NOT NULL THEN
--        IF LENGTH(:NEW.university) < 2 THEN
--            RAISE_APPLICATION_ERROR(-20026, 'University must be at least 2 characters.');
--        END IF;
--    END IF;
--
--    -------------------------------------------------------------------
--    -- CGPA
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.cgpa IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20027, 'CGPA is required.');
--    ELSIF :NEW.cgpa IS NOT NULL THEN
--        IF :NEW.cgpa < 0 OR :NEW.cgpa > 10 THEN
--            RAISE_APPLICATION_ERROR(-20028, 'CGPA must be between 0 and 10.');
--        END IF;
--    END IF;

--    -------------------------------------------------------------------
--    -- Skills
--    -------------------------------------------------------------------
--    IF INSERTING AND :NEW.skills IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20029, 'Skills are required.');
--    ELSIF :NEW.skills IS NOT NULL THEN
--        IF LENGTH(:NEW.skills) < 1 THEN
--            RAISE_APPLICATION_ERROR(-20030, 'Skills must be at least 1 characters.');
--        END IF;
--    END IF;
    
--    IF :NEW.last_salary IS NOT NULL AND :NEW.expected_salary IS NOT NULL THEN
--        IF :NEW.expected_salary < :NEW.last_salary THEN
--            RAISE_APPLICATION_ERROR(-20031, 'Expected salary must be greater than or equal to last salary.');
--        END IF;
--    END IF;
    
--    IF :new.status IS NOT NULL THEN
--        IF LOWER(:new.status) NOT IN ('active', 'inactive') THEN
--            RAISE_APPLICATION_ERROR(-20032,'Status must be either "active" or "inactive". ');
--        END IF;
--    END IF;
--
--    -- Validate 'interview_status' if provided
--    IF :new.interview_status IS NOT NULL THEN
--        IF LOWER(:new.interview_status) NOT IN ('selected', 'rejected', 'in progress') THEN
--           RAISE_APPLICATION_ERROR(-20033, 'Interview status must be "selected", "rejected", or "in progress".') ;
--        END IF;
--
--        -- If interview_status is rejected, rejection_reason must be given
--        IF LOWER(:new.interview_status) = 'rejected' AND (:new.rejection_reason IS NULL OR TRIM(:new.rejection_reason) = '') THEN
--           RAISE_APPLICATION_ERROR(-20034,'Rejection reason is required when interview status is "rejected". ');
--        END IF;
--    END IF;

    ----------------------------------------------------------------------
    -- Raise All Collected Errors at Once
    ----------------------------------------------------------------------

--    IF lv_error_msgs IS NOT NULL THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Validation failed for the following reason(s):' || CHR(10) || lv_error_msgs);
--    END IF;
--
--END;
--
--/

CREATE OR REPLACE TRIGGER trg_check_candidate_duplicates
FOR INSERT OR UPDATE ON candidates
COMPOUND TRIGGER

    TYPE candidate_rec IS RECORD (
        email          candidates.email%TYPE,
        phone          candidates.phone%TYPE,
        id_proof_num   candidates.id_proof_num%TYPE,
        candidate_id   candidates.candidate_id%TYPE
    );

    TYPE candidate_tab IS TABLE OF candidate_rec INDEX BY PLS_INTEGER;

    v_new_candidates candidate_tab;
    ln_idx PLS_INTEGER := 0;
    lv_error_msgs VARCHAR2(1000) := '';


AFTER EACH ROW IS
BEGIN
    ln_idx := ln_idx + 1;
    v_new_candidates(ln_idx).email := LOWER(:NEW.email);
    v_new_candidates(ln_idx).phone := :NEW.phone;
    v_new_candidates(ln_idx).id_proof_num :=UPPER( :NEW.id_proof_num);
    v_new_candidates(ln_idx).candidate_id := :NEW.candidate_id;
END AFTER EACH ROW;

AFTER STATEMENT IS
    ln_count NUMBER;
BEGIN
--    FOR i IN 1 .. v_new_candidates.COUNT LOOP
--        -- Check for duplicate email
--        IF v_new_candidates(i).email IS NOT NULL THEN
--            SELECT COUNT(*) INTO ln_count
--            FROM candidates
--            WHERE LOWER(email) = v_new_candidates(i).email
--              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);
--
--            IF ln_count > 0 THEN
--                RAISE_APPLICATION_ERROR(-20040, 'The email address "' || v_new_candidates(i).email || '" is already registered. Please use a different email.');
--            END IF;
--        END IF;
--
--        -- Check for duplicate phone
--        IF v_new_candidates(i).phone IS NOT NULL THEN
--            SELECT COUNT(*) INTO ln_count
--            FROM candidates
--            WHERE phone = v_new_candidates(i).phone
--              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);
--
--            IF ln_count > 0 THEN
--                RAISE_APPLICATION_ERROR(-20041, 'The phone number "' || v_new_candidates(i).phone || '" is already registered. Please use a different phone number.');
--            END IF;
--        END IF;
--
--        -- Check for duplicate ID proof
--        IF v_new_candidates(i).id_proof_num IS NOT NULL THEN
--            SELECT COUNT(*) INTO ln_count
--            FROM candidates
--            WHERE id_proof_num = v_new_candidates(i).id_proof_num
--              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);
--
--            IF ln_count > 0 THEN
--                RAISE_APPLICATION_ERROR(-20042, 'The ID proof number "' || v_new_candidates(i).id_proof_num || '" is already registered. Please use a different ID proof.');
--            END IF;
--        END IF;
--    END LOOP;
    FOR i IN 1 .. v_new_candidates.COUNT LOOP
        -- Check for duplicate email
        IF v_new_candidates(i).email IS NOT NULL THEN
            SELECT COUNT(*) INTO ln_count
            FROM candidates
            WHERE LOWER(email) = v_new_candidates(i).email
              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);

            IF ln_count > 0 THEN
                lv_error_msgs := lv_error_msgs || '- The email "' || v_new_candidates(i).email || '" is already registered.' || CHR(10);
            END IF;
        END IF;

        -- Check for duplicate phone
        IF v_new_candidates(i).phone IS NOT NULL THEN
            SELECT COUNT(*) INTO ln_count
            FROM candidates
            WHERE phone = v_new_candidates(i).phone
              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);

            IF ln_count > 0 THEN
                lv_error_msgs := lv_error_msgs || '- The phone number "' || v_new_candidates(i).phone || '" is already registered.' || CHR(10);
            END IF;
        END IF;

        -- Check for duplicate ID proof
        IF v_new_candidates(i).id_proof_num IS NOT NULL THEN
            SELECT COUNT(*) INTO ln_count
            FROM candidates
            WHERE UPPER(id_proof_num) = v_new_candidates(i).id_proof_num
              AND (candidate_id != v_new_candidates(i).candidate_id OR v_new_candidates(i).candidate_id IS NULL);

            IF ln_count > 0 THEN
                lv_error_msgs := lv_error_msgs || '- The ID proof number "' || v_new_candidates(i).id_proof_num || '" is already registered.' || CHR(10);
            END IF;
        END IF;
    END LOOP;
    IF lv_error_msgs IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20002,'Please fix the following issues:' || CHR(10) || lv_error_msgs);
    END IF;

END AFTER STATEMENT;

END trg_check_candidate_duplicates;
/

select * from candidates;
