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
    p_status  IN VARCHAR2 DEFAULT NULL
);

PROCEDURE get_candidate_details (
    p_candidate_id IN candidates.candidate_id%TYPE,
    p_section      IN VARCHAR2
);

PROCEDURE promote_candidate_to_employee (
    p_candidate_id   IN NUMBER,
    p_department_id  IN NUMBER,
    p_salary         IN NUMBER DEFAULT NULL
);
END source_requirement;
/

CREATE OR REPLACE PACKAGE BODY source_requirement AS
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
)
AS
    ln_candidate_id NUMBER;
BEGIN
    ln_candidate_id := seq_candidate_id.NEXTVAL;

    INSERT INTO candidates (
        candidate_id, first_name, last_name, email, phone, dob,
        id_proof_type, id_proof_num, highest_degree, university,
        cgpa, city, country, last_employer, last_salary,
        expected_salary, years_of_experience,skills,gender, role
    ) VALUES (
        ln_candidate_id, p_first_name, p_last_name, p_email, p_phone, p_dob,
        p_id_proof_type, p_id_proof_num, p_highest_degree, p_university,
        p_cgpa, p_city, p_country, p_last_employer, p_last_salary,
        p_expected_salary, p_years_of_experience, p_skills,p_gender, p_role
    );

    DBMS_OUTPUT.PUT_LINE('Candidate inserted successfully with ID: ' || ln_candidate_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting candidate: ' || SQLERRM);
END ADD_CANDIDATE;


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
)
IS
    ln_rows_updated NUMBER;
BEGIN
    UPDATE candidates
    SET
        first_name          = NVL(p_first_name, first_name),
        last_name           = NVL(p_last_name, last_name),
        email               = NVL(p_email, email),
        phone               = NVL(p_phone, phone),
        dob                 = NVL(p_dob, dob),
        id_proof_type       = NVL(p_id_proof_type, id_proof_type),
        id_proof_num        = NVL(p_id_proof_num, id_proof_num),
        highest_degree      = NVL(p_highest_degree, highest_degree),
        university          = NVL(p_university, university),
        cgpa                = NVL(p_cgpa, cgpa),
        city                = NVL(p_city, city),
        country             = NVL(p_country, country),
        last_employer       = NVL(p_last_employer, last_employer),
        last_salary         = NVL(p_last_salary, last_salary),
        expected_salary     = NVL(p_expected_salary, expected_salary),
        years_of_experience = NVL(p_years_of_experience, years_of_experience),
        skills              = NVL(p_skills, skills),
        interview_status    = NVL(p_interview_status, interview_status),
        rejection_reason    = CASE 
                                WHEN p_interview_status = 'Rejected' THEN NVL(p_rejection_reason, rejection_reason)
                                ELSE rejection_reason 
                              END,
        status              = CASE 
                                WHEN p_interview_status = 'Rejected' THEN 'Inactive'
                                WHEN p_interview_status = 'Selected' THEN 'Active'
                                ELSE status 
                              END,
        gender              = NVL(p_gender, gender),
        role                = NVL(p_role, role)
    WHERE candidate_id = p_candidate_id;

    ln_rows_updated := SQL%ROWCOUNT;

    IF ln_rows_updated = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No record found with candidate_id = ' || p_candidate_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE(ln_rows_updated || ' record(s) updated successfully.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END update_candidate;


PROCEDURE remove_candidate (
    p_candidate_id IN NUMBER
) IS
    e_candidate_not_found EXCEPTION;
    ln_count NUMBER;
BEGIN
    -- Check if candidate exists
    SELECT COUNT(*) INTO ln_count
    FROM candidates
    WHERE candidate_id = p_candidate_id;

    IF ln_count = 0 THEN
        RAISE e_candidate_not_found;
    END IF;

    -- Delete candidate
    DELETE FROM candidates
    WHERE candidate_id = p_candidate_id;

    DBMS_OUTPUT.PUT_LINE('Candidate with ID ' || p_candidate_id || ' removed successfully.');

EXCEPTION
    WHEN e_candidate_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Candidate with ID ' || p_candidate_id || ' does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END REMOVE_CANDIDATE;


PROCEDURE list_candidates (
    p_country IN VARCHAR2 DEFAULT NULL,
    p_city    IN VARCHAR2 DEFAULT NULL,
    p_skill   IN VARCHAR2 DEFAULT NULL,
    p_status  IN VARCHAR2 DEFAULT NULL
)
IS
    CURSOR c_cand IS
        SELECT *
        FROM candidates
        WHERE
            (p_country IS NULL OR LOWER(country) = LOWER(p_country))
            AND
            (p_city IS NULL OR LOWER(city) = LOWER(p_city))
            AND
            (p_skill IS NULL OR LOWER(skills) = LOWER(p_skill))
            AND (
                (p_status IS NULL AND LOWER(interview_status) != 'rejected')
                OR (LOWER(interview_status) = LOWER(p_status))
            );

    r_cand c_cand%ROWTYPE;

BEGIN
    OPEN c_cand;
    LOOP
        FETCH c_cand INTO r_cand;
        EXIT WHEN c_cand%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Candidate ID   : ' || r_cand.candidate_id);
        DBMS_OUTPUT.PUT_LINE('Name           : ' || r_cand.first_name|| ' '||r_cand.last_name);
        DBMS_OUTPUT.PUT_LINE('Country        : ' || NVL(r_cand.country, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('City           : ' || NVL(r_cand.city, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('Skill          : ' || r_cand.skills);
        DBMS_OUTPUT.PUT_LINE('Interview Status: ' || r_cand.interview_status);
        DBMS_OUTPUT.PUT_LINE('-----------------------------');
    END LOOP;
    CLOSE c_cand;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;



PROCEDURE get_candidate_details (
    p_candidate_id IN candidates.candidate_id%TYPE,
    p_section      IN VARCHAR2
)
IS
    r_cand candidates%ROWTYPE;
    e_invalid_section EXCEPTION;
BEGIN
    SELECT * INTO r_cand
    FROM candidates
    WHERE candidate_id = p_candidate_id;

    CASE UPPER(p_section)
        WHEN 'PERSONAL' THEN
            DBMS_OUTPUT.PUT_LINE('--- Personal Details ---');
            DBMS_OUTPUT.PUT_LINE('Name: ' || r_cand.first_name ||' '||r_cand.last_name);
            DBMS_OUTPUT.PUT_LINE('ID Proof Type: ' || r_cand.id_proof_type);
            DBMS_OUTPUT.PUT_LINE('ID Proof Number: ' || r_cand.id_proof_num);
            DBMS_OUTPUT.PUT_LINE('Location: ' || r_cand.city);
            DBMS_OUTPUT.PUT_LINE('Country: ' || r_cand.country);

        WHEN 'ACADEMIC' THEN
            DBMS_OUTPUT.PUT_LINE('--- Academic Details ---');
            DBMS_OUTPUT.PUT_LINE('Highest Degree: ' || r_cand.highest_degree);
            DBMS_OUTPUT.PUT_LINE('University: ' || r_cand.university);
            DBMS_OUTPUT.PUT_LINE('CGPA: ' || r_cand.cgpa);

        WHEN 'PROFESSIONAL' THEN
            DBMS_OUTPUT.PUT_LINE('--- Professional Details ---');
            DBMS_OUTPUT.PUT_LINE('Last Employer: ' || r_cand.last_employer);
            DBMS_OUTPUT.PUT_LINE('Last Salary: ' || r_cand.last_salary);
            DBMS_OUTPUT.PUT_LINE('Expected Salary: ' || r_cand.expected_salary);
            DBMS_OUTPUT.PUT_LINE('Years of Experience: ' || r_cand.years_of_experience);
            DBMS_OUTPUT.PUT_LINE('Skill Set: ' || r_cand.skills);

        ELSE
            RAISE e_invalid_section;
    END CASE;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No candidate found with ID ' || p_candidate_id);
    WHEN e_invalid_section THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid section. Use PERSONAL, ACADEMIC, or PROFESSIONAL.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected Error: ' || SQLERRM);
END;

--CANDIDATE TO EMPLOYEE CONVERSION
PROCEDURE promote_candidate_to_employee (
    p_candidate_id   IN NUMBER,
    p_department_id  IN NUMBER,
    p_salary         IN NUMBER DEFAULT NULL
) IS
    v_first_name   candidates.first_name%TYPE;
    v_last_name    candidates.last_name%TYPE;
    v_skill        candidates.skills%TYPE;
    v_exp          candidates.years_of_experience%TYPE;
    v_salary       NUMBER;
    v_band_id      baseline_salary.band_id%TYPE;
    v_new_emp_id   employee.employee_id%TYPE;
    v_gender       candidates.gender%TYPE;
    v_role         candidates.role%TYPE;
    v_manager_id   employee.employee_id%TYPE;
    v_band_found   BOOLEAN := FALSE;
    v_status       candidates.interview_status%TYPE;
BEGIN
    -- Step 1: Fetch candidate details
    SELECT first_name, last_name, skills, years_of_experience,
           COALESCE(p_salary, expected_salary), gender, role,interview_status
    INTO v_first_name, v_last_name, v_skill, v_exp, v_salary, v_gender, v_role,v_status
    FROM candidates
    WHERE candidate_id = p_candidate_id;
    
    IF v_status!='Selected' THEN
        IF v_status='In Progress' THEN
        RAISE_APPLICATION_ERROR(-20101, 'Candidate interview process is still in progress');
        ELSE
        RAISE_APPLICATION_ERROR(-20102, ' Candidate interview status is rejected, cannot promote to employee.');
        END IF;
    END IF;    

    -- Step 2: Try to find matching band (strict experience match)
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
            NULL; -- fall through to fallback logic
    END;

    -- Step 2b: Fallback - if exp > max_exp and other conditions match
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
                RAISE_APPLICATION_ERROR(-20002, ' No suitable band found for candidate.');
        END;
    END IF;

    -- Step 3: Check for department manager
    BEGIN
        SELECT manager_id
        INTO v_manager_id
        FROM department
        WHERE department_id = p_department_id
          AND manager_id IS NOT NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_manager_id := NULL;
    END;

    -- Step 4: Generate new employee ID
    SELECT employee_seq.NEXTVAL INTO v_new_emp_id FROM dual;

    -- Step 5: Insert employee
    INSERT INTO employee (
        employee_id, candidate_id, first_name, last_name,
        salary, department_id, date_of_joining, band_id,
        manager_id, employee_status, leaves_balance, gender, role
    ) VALUES (
        v_new_emp_id, p_candidate_id, v_first_name, v_last_name,
        v_salary, p_department_id, SYSDATE, v_band_id,
        v_manager_id, 'Active', 24, v_gender, v_role
    );

    DBMS_OUTPUT.PUT_LINE('Candidate ' || p_candidate_id || ' promoted to Employee ID ' || v_new_emp_id);
    IF v_manager_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('No department manager assigned.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Assigned Manager ID: ' || v_manager_id);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Candidate ID not found.');
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Duplicate employee ID. Check sequence.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20099, 'Unexpected error: ' || SQLERRM);
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
BEGIN
    IF NOT REGEXP_LIKE(:NEW.email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid email format.');
    END IF;

    IF :NEW.phone IS NULL OR LENGTH(:NEW.phone) != 10 OR SUBSTR(:NEW.phone, 1, 1) NOT IN ('6','7','8','9') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid phone number. Must be 10 digits starting with 6-9.');
    END IF;

    IF :NEW.id_proof_type = 'Aadhar' THEN
        IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[0-9]{12}$') THEN
            RAISE_APPLICATION_ERROR(-20003, 'Invalid Aadhar number. Must be 12 digits.');
        END IF;
    ELSIF :NEW.id_proof_type = 'DL' THEN
        IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Z0-9]{8,15}$') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Invalid DL number. Must be alphanumeric (8-15 characters).');
        END IF;
    ELSIF :NEW.id_proof_type = 'Passport' THEN
        IF NOT REGEXP_LIKE(:NEW.id_proof_num, '^[A-Z][0-9]{7}$') THEN
            RAISE_APPLICATION_ERROR(-20005, 'Invalid Passport number. Format should be like A1234567.');
        END IF;
    END IF;

    IF :NEW.cgpa < 0 OR :NEW.cgpa > 10 THEN
        RAISE_APPLICATION_ERROR(-20006, 'CGPA must be between 0 and 10.');
    END IF;
    
    IF :NEW.last_salary IS NOT NULL AND :NEW.expected_salary IS NOT NULL THEN
        IF :NEW.expected_salary < :NEW.last_salary THEN
            RAISE_APPLICATION_ERROR(-20007, 'Expected salary must be greater than or equal to last salary.');
        END IF;
    END IF;
END;
/
select * from employee;
