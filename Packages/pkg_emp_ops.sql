CREATE SEQUENCE department_seq
START WITH 10
INCREMENT BY 1
NOCACHE;

CREATE SEQUENCE seq_attendance_id
START WITH 1
INCREMENT BY 1
NOCACHE;


CREATE OR REPLACE PACKAGE pkg_emp_ops AS
PROCEDURE list_employees (
    p_department_name  IN VARCHAR2 DEFAULT NULL,
    p_role             IN VARCHAR2 DEFAULT NULL,
    p_status           IN VARCHAR2 DEFAULT NULL,
    p_band_name        IN VARCHAR2 DEFAULT NULL,
    p_city_name        IN VARCHAR2 DEFAULT NULL,
    p_country_name     IN VARCHAR2 DEFAULT NULL,
    p_manager_name     IN VARCHAR2 DEFAULT NULL,
    p_first_name       IN VARCHAR2 DEFAULT NULL,
    p_last_name        IN VARCHAR2 DEFAULT NULL,
    p_gender           IN VARCHAR2 DEFAULT NULL,
    p_base_experience  IN NUMBER   DEFAULT NULL,  -- years_of_experience from candidates
    p_total_experience IN NUMBER   DEFAULT NULL   -- base + since joining
);
    
    PROCEDURE get_employee_details (
    p_employee_id IN NUMBER
) ;

PROCEDURE update_employee (
    p_employee_id     IN NUMBER,
    p_salary          IN NUMBER DEFAULT NULL,
    p_role            IN VARCHAR2 DEFAULT NULL,
    p_department_id   IN NUMBER DEFAULT NULL,
    p_first_name      IN VARCHAR2 DEFAULT NULL,
    p_last_name       IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_phone           IN NUMBER DEFAULT NULL,
    p_id_proof_type   IN VARCHAR2 DEFAULT NULL,
    p_id_proof_number IN VARCHAR2 DEFAULT NULL,
    p_dob             IN DATE DEFAULT NULL,
    p_city            IN VARCHAR2 DEFAULT NULL,
    p_country           IN VARCHAR2 DEFAULT NULL    
) ;

    PROCEDURE add_department (
    p_department_name IN VARCHAR2,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
    );

    PROCEDURE update_department (
        p_department_id   IN NUMBER,
    p_department_name IN VARCHAR2 DEFAULT NULL,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
    );
    
    

PROCEDURE mark_in_time (
    p_employee_id IN NUMBER
);
    
PROCEDURE mark_out_time (
    p_employee_id IN NUMBER
);

PROCEDURE mark_leave (
    ln_employee_id IN NUMBER
);

PROCEDURE mark_absentees;

PROCEDURE process_leave (
    p_leave_id         IN NUMBER,
    p_action           IN VARCHAR2,       -- 'Approved' or 'Rejected'
    p_approved_by      IN NUMBER          -- manager's employee_id
);
PROCEDURE apply_leave (
    p_employee_id   IN NUMBER,
    p_leave_type    IN VARCHAR2,  -- e.g., 'Casual'
    p_start_date    IN DATE,
    p_end_date      IN DATE,
    p_reason        IN VARCHAR2
);
END pkg_emp_ops;
/   


CREATE OR REPLACE PACKAGE BODY pkg_emp_ops AS
-- PROCEDURE list_employees (
--    p_department_id   IN NUMBER DEFAULT NULL,
--    p_role            IN VARCHAR2 DEFAULT NULL,
--    p_status          IN VARCHAR2 DEFAULT NULL,
--    p_band_id         IN NUMBER DEFAULT NULL,
--    p_city_id         IN NUMBER DEFAULT NULL,
--    p_country_id      IN NUMBER DEFAULT NULL,
--    p_manager_id      IN NUMBER DEFAULT NULL
--) IS
--    v_found BOOLEAN := FALSE;
--BEGIN
--    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------');
--    DBMS_OUTPUT.PUT_LINE(' EMP_ID | CAND_ID |   NAME    | ROLE               | BAND  | STATUS   | EXP_YEARS | SALARY   | DEPT_ID | MANAGER_ID | COUNTRY  | CITY |' );
--    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------');
--
--    FOR emp_rec IN (
--        SELECT 
--            e.employee_id,
--            e.candidate_id,
--            INITCAP(c.first_name || ' ' || c.last_name) AS full_name,
--            e.role,
--            b.band,
--            e.employee_status,
--            ROUND(c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12, 1) AS total_exp,
--            e.salary,
--            e.department_id,
--            e.manager_id,
--            city_md.masterdata_value as city,
--            country_md.masterdata_value as country
--        FROM employee e
--        JOIN candidates c ON e.candidate_id = c.candidate_id
--        LEFT JOIN baseline_salary b ON b.band_id = e.band_id
--        JOIN department d ON d.department_id = e.department_id
--        JOIN master_data city_md ON d.city_id = city_md.masterdata_id
--        LEFT JOIN master_data country_md ON city_md.parent_id = country_md.masterdata_id
--        WHERE (p_department_id IS NULL OR e.department_id = p_department_id)
--          AND (p_role IS NULL OR e.role = p_role)
--          AND (p_status IS NULL OR e.employee_status = p_status)
--          AND (p_band_id IS NULL OR e.band_id = p_band_id)
--          AND (p_manager_id IS NULL OR e.manager_id = p_manager_id)
--          AND (p_city_id IS NULL OR d.city_id = p_city_id)
--          AND (p_country_id IS NULL OR city_md.parent_id = p_country_id)
--          AND e.employee_status='Active'
--        ORDER BY e.employee_id
--    ) LOOP
--        v_found := TRUE;
--        DBMS_OUTPUT.PUT_LINE(
--            RPAD(emp_rec.employee_id, 8) || '|' ||
--            RPAD(emp_rec.candidate_id, 9) || '|' ||
--            RPAD(emp_rec.full_name, 11) || '|' ||
--            RPAD(emp_rec.role, 20) || '|' ||
--            RPAD(NVL(emp_rec.band, '-'), 7) || '|' ||
--            RPAD(emp_rec.employee_status, 11) || '|' ||
--            RPAD(emp_rec.total_exp, 10) || '|' ||
--            RPAD(emp_rec.salary, 10) || '|' ||
--            RPAD(emp_rec.department_id, 9) || '|' ||
--            RPAD(nvl(to_char(emp_rec.manager_id),'-'), 12) || '|' ||
--            RPAD(emp_rec.country, 10) || '|' ||
--            RPAD(emp_rec.city, 9)
--        );
--    END LOOP;
--
--    IF NOT v_found THEN
--        DBMS_OUTPUT.PUT_LINE(' No employees found with the specified criteria.');
--    END IF;
--
--EXCEPTION
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
--END;
PROCEDURE list_employees (
    p_department_name  IN VARCHAR2 DEFAULT NULL,
    p_role             IN VARCHAR2 DEFAULT NULL,
    p_status           IN VARCHAR2 DEFAULT NULL,
    p_band_name        IN VARCHAR2 DEFAULT NULL,
    p_city_name        IN VARCHAR2 DEFAULT NULL,
    p_country_name     IN VARCHAR2 DEFAULT NULL,
    p_manager_name     IN VARCHAR2 DEFAULT NULL,
    p_first_name       IN VARCHAR2 DEFAULT NULL,
    p_last_name        IN VARCHAR2 DEFAULT NULL,
    p_gender           IN VARCHAR2 DEFAULT NULL,
    p_base_experience  IN NUMBER   DEFAULT NULL,  -- years_of_experience from candidates
    p_total_experience IN NUMBER   DEFAULT NULL   -- base + since joining
) IS
    v_found BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(' EMP_ID | CAND_ID | FIRST_NAME | LAST_NAME  | FULL_NAME     | GENDER | ROLE              | BAND  | STATUS   | BASE_EXP | TOTAL_EXP     | SALARY   | DEPARTMENT      | MANAGER         | COUNTRY     | CITY      |');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');

    FOR emp_rec IN (
        SELECT 
            e.employee_id,
            e.candidate_id,
            INITCAP(c.first_name) AS first_name,
            INITCAP(c.last_name) AS last_name,
            INITCAP(c.first_name || ' ' || c.last_name) AS full_name,
            INITCAP(c.gender) AS gender,
            e.role,
            NVL(b.band, '-') AS band,
            e.employee_status,
            c.years_of_experience AS base_experience,
            ROUND(c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12, 1) AS total_exp,
            e.salary,
            d.department_name,
            NVL(mgr.first_name || ' ' || mgr.last_name, '-') AS manager_name,
            country_md.masterdata_value AS country,
            city_md.masterdata_value AS city
        FROM employee e
        JOIN candidates c ON e.candidate_id = c.candidate_id
        LEFT JOIN baseline_salary b ON b.band_id = e.band_id
        JOIN department d ON d.department_id = e.department_id
        JOIN master_data city_md ON d.city_id = city_md.masterdata_id
        LEFT JOIN master_data country_md ON city_md.parent_id = country_md.masterdata_id
        LEFT JOIN employee mgr_e ON e.manager_id = mgr_e.employee_id
        LEFT JOIN candidates mgr ON mgr_e.candidate_id = mgr.candidate_id
        WHERE (p_department_name IS NULL OR UPPER(d.department_name) = UPPER(p_department_name))
          AND (p_role IS NULL OR UPPER(e.role) = UPPER(p_role))
          AND (p_status IS NULL OR UPPER(e.employee_status) = UPPER(p_status))
          AND (p_band_name IS NULL OR UPPER(b.band) = UPPER(p_band_name))
          AND (p_manager_name IS NULL OR UPPER(mgr.first_name || ' ' || mgr.last_name) = UPPER(p_manager_name))
          AND (p_city_name IS NULL OR UPPER(city_md.masterdata_value) = UPPER(p_city_name))
          AND (p_country_name IS NULL OR UPPER(country_md.masterdata_value) = UPPER(p_country_name))
          AND (p_first_name IS NULL OR UPPER(c.first_name) = UPPER(p_first_name))
          AND (p_last_name IS NULL OR UPPER(c.last_name) = UPPER(p_last_name))
          AND (p_gender IS NULL OR UPPER(c.gender) = UPPER(p_gender))
          AND (p_base_experience IS NULL OR c.years_of_experience >= p_base_experience)
          AND (p_total_experience IS NULL OR 
               ROUND(c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12, 1) >= p_total_experience)
          AND e.employee_status = 'Active'
        ORDER BY e.employee_id
    ) LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(emp_rec.employee_id, 8) || '|' ||
            RPAD(emp_rec.candidate_id, 9) || '|' ||
            RPAD(emp_rec.first_name, 12) || '|' ||
            RPAD(emp_rec.last_name, 13) || '|' ||
            RPAD(emp_rec.full_name, 14) || '|' ||
            RPAD(emp_rec.gender, 8) || '|' ||
            RPAD(emp_rec.role, 20) || '|' ||
            RPAD(emp_rec.band, 7) || '|' ||
            RPAD(emp_rec.employee_status, 9) || '|' ||
            RPAD(emp_rec.base_experience, 10) || '|' ||
            RPAD(emp_rec.total_exp, 16) || '|' ||
            RPAD(emp_rec.salary, 11) || '|' ||
            RPAD(emp_rec.department_name, 16) || '|' ||
            RPAD(emp_rec.manager_name, 15) || '|' ||
            RPAD(emp_rec.country, 14) || '|' ||
            RPAD(emp_rec.city, 10)
        );
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE(' No employees found with the specified criteria.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

 PROCEDURE get_employee_details (
    p_employee_id IN NUMBER
) IS
    v_full_name         VARCHAR2(100);
    v_gender            VARCHAR2(10);
    v_dob               DATE;
    v_email             VARCHAR2(100);
    v_contact           NUMBER;
    v_id_proof_type     VARCHAR2(20);
    v_id_proof_number   VARCHAR2(50);
    v_degree            VARCHAR2(50);
    v_college           VARCHAR2(100);
    v_experience        NUMBER;

    v_role              VARCHAR2(100);
    v_status            VARCHAR2(15);
    v_salary            NUMBER;
    v_band              VARCHAR2(20);
    v_doj               DATE;
    v_leave_balance     NUMBER;

    v_department        VARCHAR2(100);
    v_city              VARCHAR2(50);
    v_country           VARCHAR2(50);
    v_manager_name      VARCHAR2(100);
BEGIN
    SELECT INITCAP(c.first_name || ' ' || c.last_name),
           c.gender,
           c.dob,
           c.email,
           c.phone,
           c.id_proof_type,
           c.id_proof_num,
           c.highest_degree,
           c.university,
           ROUND(c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12, 1),

           e.role,
           e.employee_status,
           e.salary,
           b.band,
           e.date_of_joining,


           d.department_name,
           city_md.masterdata_value,
           country_md.masterdata_value,

           (SELECT INITCAP(c.first_name || ' ' || c.last_name)
            FROM employee m
            JOIN candidates mc ON mc.candidate_id = m.candidate_id
            WHERE m.employee_id = e.manager_id)
    INTO v_full_name, v_gender, v_dob, v_email, v_contact, v_id_proof_type,
         v_id_proof_number, v_degree, v_college, v_experience,
         v_role, v_status, v_salary, v_band, v_doj,
         v_department, v_city, v_country, v_manager_name
    FROM employee e
    JOIN candidates c ON c.candidate_id = e.candidate_id
    LEFT JOIN baseline_salary b ON b.band_id = e.band_id
    LEFT JOIN department d ON d.department_id = e.department_id
    LEFT JOIN master_data city_md ON d.city_id = city_md.masterdata_id
    LEFT JOIN master_data country_md ON city_md.parent_id = country_md.masterdata_id
    WHERE e.employee_id = p_employee_id;

    -- Personal Details
DBMS_OUTPUT.PUT_LINE('==================== PERSONAL DETAILS ====================');
DBMS_OUTPUT.PUT_LINE('Full Name        : ' || v_full_name);
DBMS_OUTPUT.PUT_LINE('Gender           : ' || v_gender);
DBMS_OUTPUT.PUT_LINE('Date of Birth    : ' || TO_CHAR(v_dob, 'DD-MON-YYYY'));
DBMS_OUTPUT.PUT_LINE('Email            : ' || v_email);
DBMS_OUTPUT.PUT_LINE('Contact No.      : ' || v_contact);
DBMS_OUTPUT.PUT_LINE('ID Proof         : ' || v_id_proof_type || ' - ' || v_id_proof_number);
DBMS_OUTPUT.PUT_LINE('Qualification    : ' || v_degree || ' from ' || v_college);
DBMS_OUTPUT.PUT_LINE('Experience       : ' || v_experience || ' years');

-- Professional Details
DBMS_OUTPUT.PUT_LINE('==================== PROFESSIONAL DETAILS =================');
DBMS_OUTPUT.PUT_LINE('Role             : ' || v_role);
DBMS_OUTPUT.PUT_LINE('Status           : ' || v_status);
DBMS_OUTPUT.PUT_LINE('Salary           : ₹' || v_salary);
DBMS_OUTPUT.PUT_LINE('Band             : ' || NVL(v_band, '-'));
DBMS_OUTPUT.PUT_LINE('Date of Joining  : ' || TO_CHAR(v_doj, 'DD-MON-YYYY'));
DBMS_OUTPUT.PUT_LINE('Leave Balance    : ' || v_leave_balance || ' days');

-- Department & Location Details
DBMS_OUTPUT.PUT_LINE('==================== DEPARTMENT DETAILS ===================');
DBMS_OUTPUT.PUT_LINE('Department       : ' || NVL(v_department, '-'));
DBMS_OUTPUT.PUT_LINE('Location         : ' || NVL(v_city, '-') || ', ' || NVL(v_country, '-'));
DBMS_OUTPUT.PUT_LINE('Manager          : ' || NVL(v_manager_name, '-'));


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee with ID ' || p_employee_id || ' not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('error: ' || SQLERRM);
END;

 PROCEDURE update_employee (
    p_employee_id     IN NUMBER,
    p_salary          IN NUMBER DEFAULT NULL,
    p_role            IN VARCHAR2 DEFAULT NULL,
    p_department_id   IN NUMBER DEFAULT NULL,
    p_first_name      IN VARCHAR2 DEFAULT NULL,
    p_last_name       IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_phone           IN NUMBER DEFAULT NULL,
    p_id_proof_type   IN VARCHAR2 DEFAULT NULL,
    p_id_proof_number IN VARCHAR2 DEFAULT NULL,
    p_dob             IN DATE DEFAULT NULL,
    p_city            IN VARCHAR2 DEFAULT NULL,
    p_country           IN VARCHAR2 DEFAULT NULL

) IS
    v_salary        employee.salary%TYPE;
    v_role          employee.role%TYPE;
    v_band_id       employee.band_id%TYPE;
    v_old_dept      employee.department_id%TYPE;
    v_exp           NUMBER;
    v_band_found    BOOLEAN := FALSE;
    v_is_manager    NUMBER := 0;
    v_cand_id       NUMBER;
    v_dept_name     VARCHAR2(100);
    v_role_dept_id  NUMBER;
    v_role_name     VARCHAR2(100);
    v_band_name     VARCHAR2(100);
    v_dept_master_id NUMBER;
    v_role_parent    NUMBER;
BEGIN
    -- Fetch current salary, role, department, candidate_id
    SELECT 
        NVL(p_salary, salary),
        NVL(p_role, role),
        department_id,
        candidate_id
    INTO 
        v_salary, v_role, v_old_dept, v_cand_id
    FROM employee
    WHERE employee_id = p_employee_id;

    v_role := INITCAP(v_role); -- Normalize role

-- Step 3: Validate role-department mapping
DECLARE
    v_existing_dept_id        department.department_id%TYPE;
    v_existing_role           employee.role%TYPE;
    v_existing_dept_master_id master_data.masterdata_id%TYPE;
    v_input_dept_master_id    master_data.masterdata_id%TYPE;
    v_role_parent_id          master_data.parent_id%TYPE;
    v_wrong_dept_name         master_data.masterdata_value%TYPE;
BEGIN
    -- Get employee's current department and role
    BEGIN
        SELECT department_id, role
        INTO v_existing_dept_id, v_existing_role
        FROM employee
        WHERE employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('�?� Employee with ID ' || p_employee_id || ' not found.');
            RETURN;
    END;

    -- CASE 1: Only role is being updated
    IF p_role IS NOT NULL AND p_department_id IS NULL THEN
        BEGIN
            SELECT md.masterdata_id
            INTO v_existing_dept_master_id
            FROM department d
            JOIN master_data md ON md.masterdata_value = d.department_name
            WHERE d.department_id = v_existing_dept_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Existing department ID ' || v_existing_dept_id || ' not found in master data.');
                RETURN;
        END;

        BEGIN
            SELECT parent_id
            INTO v_role_parent_id
            FROM master_data
            WHERE masterdata_type = 'JOB_TITLE'
              AND UPPER(masterdata_value) = UPPER(p_role);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" not found in master data.');
                RETURN;
        END;

        -- Compare
        IF v_existing_dept_master_id != v_role_parent_id THEN
            BEGIN
                SELECT masterdata_value INTO v_wrong_dept_name
                FROM master_data
                WHERE masterdata_id = v_role_parent_id;
                DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" does not belong to employee''s current department.');
                DBMS_OUTPUT.PUT_LINE('🔎 This role belongs to department: "' || v_wrong_dept_name || '".');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" has no associated department in master data.');
            END;
            RETURN;
        END IF;
    END IF;

    -- CASE 2: Only department is being updated
    IF p_department_id IS NOT NULL AND p_role IS NULL THEN
        BEGIN
            SELECT md.masterdata_id
            INTO v_input_dept_master_id
            FROM department d
            JOIN master_data md ON md.masterdata_value = d.department_name
            WHERE d.department_id = p_department_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Provided department ID ' || p_department_id || ' not found in master data.');

                RETURN;
        END;

        BEGIN
            SELECT parent_id
            INTO v_role_parent_id
            FROM master_data
            WHERE masterdata_type = 'JOB_TITLE'
              AND UPPER(masterdata_value) = UPPER(v_existing_role);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Current role "' || INITCAP(v_existing_role) || '" not found in master data.');

                RETURN;
        END;

        -- Compare
        IF v_input_dept_master_id != v_role_parent_id THEN
            BEGIN
                SELECT masterdata_value INTO v_wrong_dept_name
                FROM master_data
                WHERE masterdata_id = v_role_parent_id;
                DBMS_OUTPUT.PUT_LINE('�?� Current role "' || INITCAP(v_existing_role) || '" does not match the new department.');
                DBMS_OUTPUT.PUT_LINE('🔎 This role belongs to department: "' || v_wrong_dept_name || '".');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(v_existing_role) || '" has no associated department in master data.');
            END;
            RETURN;
        END IF;
    END IF;

    -- CASE 3: Both role and department are being updated
    IF p_role IS NOT NULL AND p_department_id IS NOT NULL THEN
        BEGIN
            SELECT md.masterdata_id
            INTO v_input_dept_master_id
            FROM department d
            JOIN master_data md ON md.masterdata_value = d.department_name
            WHERE d.department_id = p_department_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Department ID ' || p_department_id || ' not found in master data.');
                RETURN;
        END;

        BEGIN
            SELECT parent_id
            INTO v_role_parent_id
            FROM master_data
            WHERE masterdata_type = 'JOB_TITLE'
              AND UPPER(masterdata_value) = UPPER(p_role);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" not found in master data.');
                RETURN;
        END;

        -- Compare
        IF v_input_dept_master_id != v_role_parent_id THEN
            BEGIN
                SELECT masterdata_value INTO v_wrong_dept_name
                FROM master_data
                WHERE masterdata_id = v_role_parent_id;
                DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" does not belong to the selected department.');
                DBMS_OUTPUT.PUT_LINE('🔎 This role belongs to department: "' || v_wrong_dept_name || '".');
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('�?� Role "' || INITCAP(p_role) || '" has no associated department in master data.');
            END;
            RETURN;
        END IF;
    END IF;
END;

 -- Update candidate personal details
IF p_first_name IS NOT NULL OR p_last_name IS NOT NULL OR
   p_email IS NOT NULL OR p_phone IS NOT NULL OR
   p_id_proof_type IS NOT NULL OR p_id_proof_number IS NOT NULL OR
   p_dob IS NOT NULL OR p_city IS NOT NULL OR p_country IS NOT NULL THEN

    DECLARE
        v_old_first_name     candidates.first_name%TYPE;
        v_old_last_name      candidates.last_name%TYPE;
        v_old_email          candidates.email%TYPE;
        v_old_phone          candidates.phone%TYPE;
        v_old_id_type        candidates.id_proof_type%TYPE;
        v_old_id_num         candidates.id_proof_num%TYPE;
        v_old_dob            candidates.dob%TYPE;
        v_city               candidates.city%TYPE;
        v_country            candidates.country%TYPE;
    BEGIN
        -- Fetch existing values
        SELECT first_name, last_name, email, phone, id_proof_type, id_proof_num, dob,city,country
        INTO v_old_first_name, v_old_last_name, v_old_email,
             v_old_phone, v_old_id_type, v_old_id_num, v_old_dob,v_city,v_country
        FROM candidates
        WHERE candidate_id = v_cand_id;

        -- Update
        UPDATE candidates
        SET first_name      = INITCAP(COALESCE(p_first_name, first_name)),
            last_name       = INITCAP(COALESCE(p_last_name, last_name)),
            email           = LOWER(COALESCE(p_email, email)),
            phone           = COALESCE(p_phone, phone),
            id_proof_type   = COALESCE(p_id_proof_type, id_proof_type),
            id_proof_num    = UPPER(COALESCE(p_id_proof_number, id_proof_num)),
            dob             = COALESCE(p_dob, dob),
            city           =INITCAP(COALESCE(p_city,city)),
            country           =INITCAP(COALESCE(p_country,country))

        WHERE candidate_id = v_cand_id;

        DBMS_OUTPUT.PUT_LINE('✅ Personal details updated for employee ID ' || p_employee_id || ':');

        IF p_first_name IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? First Name: ' || v_old_first_name || ' → ' || INITCAP(p_first_name));
        END IF;

        IF p_last_name IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? Last Name: ' || v_old_last_name || ' → ' || INITCAP(p_last_name));
        END IF;

        IF p_email IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? Email: ' || v_old_email || ' → ' || LOWER(p_email));
        END IF;

        IF p_phone IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? Phone: ' || v_old_phone || ' → ' || p_phone);
        END IF;

        IF p_id_proof_type IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? ID Proof Type: ' || v_old_id_type || ' → ' || p_id_proof_type);
        END IF;

        IF p_id_proof_number IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? ID Proof Number: ' || v_old_id_num || ' → ' || UPPER(p_id_proof_number));
        END IF;

        IF p_dob IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? DOB: ' || TO_CHAR(v_old_dob, 'DD-Mon-YYYY') || ' → ' || TO_CHAR(p_dob, 'DD-Mon-YYYY'));
        END IF;
        
        IF p_city IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? City: ' || v_city || ' → ' || p_city);
        END IF;        
        
        IF p_country IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   �? Country: ' || v_country || ' → ' || p_country);
        END IF;        

    END;
END IF;

    -- Get experience
    SELECT ROUND(
        c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining) / 12, 1)
    INTO v_exp
    FROM employee e
    JOIN candidates c ON e.candidate_id = c.candidate_id
    WHERE e.employee_id = p_employee_id;

    -- Determine band based on role/salary/experience
    BEGIN
        SELECT band_id INTO v_band_id
        FROM baseline_salary
        WHERE upper(job_title) = upper(v_role)
          AND v_salary BETWEEN min_salary AND max_salary
          AND v_exp BETWEEN min_exp AND max_exp
        ORDER BY min_exp DESC FETCH FIRST 1 ROWS ONLY;
        v_band_found := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;

    IF NOT v_band_found THEN
        BEGIN
            SELECT band_id
            INTO v_band_id
            FROM baseline_salary
            WHERE upper(job_title) = upper(v_role)
              AND v_salary BETWEEN min_salary AND max_salary
              AND max_exp = (
                  SELECT MAX(max_exp)
                  FROM baseline_salary
                  WHERE upper(job_title) = upper(v_role)
              );
            v_band_found := TRUE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� No suitable band found for role "' || v_role || '" with salary ' || v_salary || ' and experience ' || v_exp);
  RETURN;      
        END;
    END IF;

    -- Update salary
    IF p_salary IS NOT NULL THEN
        UPDATE employee
        SET salary = p_salary
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('✅ Salary updated to ₹' || p_salary);
    END IF;

    -- Update role
    IF p_role IS NOT NULL THEN
        UPDATE employee
        SET role = v_role
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('✅ Role updated to "' || v_role || '"');
    END IF;

    -- Update band
    IF p_role IS NOT NULL OR p_salary IS NOT NULL THEN
        UPDATE employee
        SET band_id = v_band_id
        WHERE employee_id = p_employee_id;

        SELECT band INTO v_band_name FROM baseline_salary WHERE band_id = v_band_id;
        DBMS_OUTPUT.PUT_LINE('✅ Band updated to "' || v_band_name || '"');
    END IF;

    -- Update department and manager logic
    IF p_department_id IS NOT NULL THEN
        UPDATE employee
        SET department_id = p_department_id
        WHERE employee_id = p_employee_id;

       SELECT md.masterdata_value
INTO v_dept_name
FROM department d
JOIN master_data md ON d.department_name = md.masterdata_value AND upper(md.masterdata_type)='DEPARTMENT'
WHERE d.department_id = p_department_id;


        DBMS_OUTPUT.PUT_LINE('✅ Department updated to "' || v_dept_name || '"');

        DECLARE
            v_mgr_id department.manager_id%TYPE;
        BEGIN
            SELECT manager_id INTO v_mgr_id
            FROM department WHERE department_id = p_department_id;

            IF v_mgr_id IS NOT NULL AND v_mgr_id != p_employee_id THEN
                UPDATE employee
                SET manager_id = v_mgr_id
                WHERE employee_id = p_employee_id;
                DBMS_OUTPUT.PUT_LINE('✅ Assigned manager ID: ' || v_mgr_id);
            ELSE
                UPDATE employee SET manager_id = NULL
                WHERE employee_id = p_employee_id;
                DBMS_OUTPUT.PUT_LINE('�? No manager assigned.');
            END IF;
        END;

        -- Clear manager role if employee was manager of old department
        UPDATE department SET manager_id = NULL
        WHERE manager_id = p_employee_id AND department_id = v_old_dept;

        UPDATE employee
        SET manager_id = NULL
        WHERE manager_id = p_employee_id AND department_id = v_old_dept;
    END IF;

    -- Ensure managers don't report to anyone
    SELECT COUNT(*) INTO v_is_manager
    FROM department WHERE manager_id = p_employee_id;

    IF v_is_manager > 0 THEN
        UPDATE employee SET manager_id = NULL
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('✅ Manager privileges enforced: self-report removed');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('�?� Employee not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('�?� Unexpected error: ' || SQLERRM);
END;



PROCEDURE add_department (
    p_department_name IN VARCHAR2,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
) IS
    ln_dept_id       NUMBER := department_seq.NEXTVAL;
    v_exists         NUMBER := 0;
    v_city_name      master_data.masterdata_value%TYPE;
    v_manager_name   VARCHAR2(200);
BEGIN
    -- Check if department already exists with same name and city
    SELECT COUNT(*)
    INTO v_exists
    FROM department
    WHERE UPPER(department_name) = UPPER(p_department_name)
      AND city_id = p_city_id;

    IF v_exists > 0 THEN
        BEGIN
            SELECT masterdata_value INTO v_city_name
            FROM master_data
            WHERE masterdata_id = p_city_id AND UPPER(masterdata_type) = 'CITY';

            DBMS_OUTPUT.PUT_LINE('�?� Department "' || INITCAP(p_department_name) || '" already exists in city "' || v_city_name || '".');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Department "' || INITCAP(p_department_name) || '" already exists in an unknown city (ID: ' || p_city_id || ').');
        END;
        RETURN;
    END IF;

    -- Insert new department
    INSERT INTO department (
        department_id,
        department_name,
        manager_id,
        city_id
    ) VALUES (
        ln_dept_id,
        INITCAP(p_department_name),
        p_manager_id,
        p_city_id
    );

    -- Fetch city name from master_data
    IF p_city_id IS NOT NULL THEN
        BEGIN
            SELECT masterdata_value INTO v_city_name
            FROM master_data
            WHERE masterdata_id = p_city_id AND UPPER(masterdata_type) = 'CITY';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_city_name := 'Unknown City';
        END;
    ELSE
        v_city_name := 'Not specified';
    END IF;

    -- Fetch manager name
    IF p_manager_id IS NOT NULL THEN
        BEGIN
            SELECT INITCAP(c.first_name || ' ' || c.last_name)
            INTO v_manager_name
            FROM employee e
            JOIN candidates c ON e.candidate_id = c.candidate_id
            WHERE e.employee_id = p_manager_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_manager_name := 'Unknown Manager';
        END;
    ELSE
        v_manager_name := 'Not assigned';
    END IF;

    -- Final Output
    DBMS_OUTPUT.PUT_LINE('✅ Department inserted successfully:');
    DBMS_OUTPUT.PUT_LINE('  ➤ ID       : ' || ln_dept_id);
    DBMS_OUTPUT.PUT_LINE('  ➤ Name     : ' || INITCAP(p_department_name));
    DBMS_OUTPUT.PUT_LINE('  ➤ City     : ' || v_city_name);
    DBMS_OUTPUT.PUT_LINE('  ➤ Manager  : ' || v_manager_name);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('�?� Unexpected error during department insertion: ' || SQLERRM);
END;



-- PROCEDURE update_department (
--    p_department_id   IN NUMBER,
--    p_department_name IN VARCHAR2 DEFAULT NULL,
--    p_manager_id      IN NUMBER DEFAULT NULL,
--    p_city_id         IN NUMBER DEFAULT NULL
--) IS
--    v_new_name   VARCHAR2(100);
--    v_new_city   NUMBER;
--    v_count      NUMBER;
--BEGIN
--    -- Step 1: Fetch current values if not provided
--    SELECT department_name, city_id
--    INTO v_new_name, v_new_city
--    FROM department
--    WHERE department_id = p_department_id;
--
--    -- Override only if parameters are provided
--    IF p_department_name IS NOT NULL THEN
--        v_new_name := p_department_name;
--    END IF;
--
--    IF p_city_id IS NOT NULL THEN
--        v_new_city := p_city_id;
--    END IF;
--
--    -- Step 2: Check uniqueness for (name, city) combination
--    SELECT COUNT(*)
--    INTO v_count
--    FROM department
--    WHERE UPPER(department_name) = UPPER(v_new_name)
--      AND city_id = v_new_city
--      AND department_id != p_department_id;
--
--    IF v_count > 0 THEN
--        DBMS_OUTPUT.PUT_LINE(' Department name "' || v_new_name || '" already exists in city ID ' || v_new_city || '.');
--        RETURN;
--    END IF;
--
--    -- Step 3: Update department_name and/or city_id
--    IF p_department_name IS NOT NULL OR p_city_id IS NOT NULL THEN
--        UPDATE department
--        SET department_name = v_new_name,
--            city_id = v_new_city
--        WHERE department_id = p_department_id;
--
--        DBMS_OUTPUT.PUT_LINE('✅ Updated department name/city to "' || v_new_name || '", City ID: ' || v_new_city || ' for department_id = ' || p_department_id);
--    END IF;
--
--    -- Step 4: Update manager_id if given
--    IF p_manager_id IS NOT NULL THEN
--        SELECT COUNT(*)
--        INTO v_count
--        FROM employee
--        WHERE employee_id = p_manager_id
--          AND department_id = p_department_id;
--
--        IF v_count = 0 THEN
--            RAISE_APPLICATION_ERROR(-20010, 'Manager must belong to the same department.');
--        END IF;
--
--        -- Assign manager to department
--        UPDATE department
--        SET manager_id = p_manager_id
--        WHERE department_id = p_department_id;
--
--        -- Set manager_id to all employees (except manager himself)
--        UPDATE employee
--        SET manager_id = p_manager_id
--        WHERE department_id = p_department_id
--          AND employee_id != p_manager_id;
--
--        -- Ensure manager himself has NULL as manager
--        UPDATE employee
--        SET manager_id = NULL
--        WHERE employee_id = p_manager_id;
--
--        DBMS_OUTPUT.PUT_LINE('✅ Updated manager_id to ' || p_manager_id || ' for department_id = ' || p_department_id);
--    END IF;
--
--EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--        DBMS_OUTPUT.PUT_LINE('�?� Department with ID ' || p_department_id || ' not found.');
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('�?� Unexpected error: ' || SQLERRM);
--END;

 PROCEDURE update_department (
    p_department_id   IN NUMBER,
    p_department_name IN VARCHAR2 DEFAULT NULL,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
) IS
    v_new_name      VARCHAR2(100);
    v_new_city      NUMBER;
    v_count         NUMBER;
    v_city_name     master_data.masterdata_value%TYPE;
    v_mgr_name      VARCHAR2(200);
    v_dept_name     department.department_name%TYPE;
BEGIN
    -- Step 1: Fetch current department name and city if not provided
    SELECT department_name, city_id
    INTO v_new_name, v_new_city
    FROM department
    WHERE department_id = p_department_id;

    -- Override with new values if provided
    IF p_department_name IS NOT NULL THEN
        v_new_name := INITCAP(p_department_name);
    END IF;

    IF p_city_id IS NOT NULL THEN
        v_new_city := p_city_id;
    END IF;

    -- Step 2: Check if another department with same name & city exists
    SELECT COUNT(*)
    INTO v_count
    FROM department
    WHERE UPPER(department_name) = UPPER(v_new_name)
      AND city_id = v_new_city
      AND department_id != p_department_id;

    IF v_count > 0 THEN
        BEGIN
            SELECT masterdata_value INTO v_city_name
            FROM master_data
            WHERE masterdata_id = v_new_city AND UPPER(masterdata_type) = 'CITY';

            DBMS_OUTPUT.PUT_LINE('�?� Department "' || v_new_name || '" already exists in city "' || v_city_name || '".');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('�?� Department "' || v_new_name || '" already exists in unknown city (ID: ' || v_new_city || ').');
        END;
        RETURN;
    END IF;

    -- Step 3: Update department name and/or city
    IF p_department_name IS NOT NULL OR p_city_id IS NOT NULL THEN
        UPDATE department
        SET department_name = v_new_name,
            city_id = v_new_city
        WHERE department_id = p_department_id;

        BEGIN
            SELECT masterdata_value INTO v_city_name
            FROM master_data
            WHERE masterdata_id = v_new_city AND UPPER(masterdata_type) = 'CITY';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_city_name := 'Unknown';
        END;

        DBMS_OUTPUT.PUT_LINE('Department updated:');
        DBMS_OUTPUT.PUT_LINE('    Name : ' || v_new_name);
        DBMS_OUTPUT.PUT_LINE('    City : ' || v_city_name);
    END IF;

    -- Step 4: Update manager assignment
--    IF p_manager_id IS NOT NULL THEN
--        SELECT COUNT(*) INTO v_count
--        FROM employee
--        WHERE employee_id = p_manager_id AND department_id = p_department_id;
--
--        IF v_count = 0 THEN
--            DBMS_OUTPUT.PUT_LINE('�?� Manager (ID: ' || p_manager_id || ') does not belong to this department.');
--            RETURN;
--        END IF;
--
--        -- Update manager in department
--        UPDATE department
--        SET manager_id = p_manager_id
--        WHERE department_id = p_department_id;
--
--        -- Update all other employees to report to manager
--        UPDATE employee
--        SET manager_id = p_manager_id
--        WHERE department_id = p_department_id
--          AND employee_id != p_manager_id;
--
--        -- Ensure manager has no manager
--        UPDATE employee
--        SET manager_id = NULL
--        WHERE employee_id = p_manager_id;
--
--        -- Get manager and department name
--        SELECT INITCAP(c.first_name || ' ' || c.last_name), d.department_name
--        INTO v_mgr_name, v_dept_name
--        FROM employee e
--        JOIN candidates c ON e.candidate_id = c.candidate_id
--        JOIN department d ON d.department_id = e.department_id
--        WHERE e.employee_id = p_manager_id;
--
--        DBMS_OUTPUT.PUT_LINE('✅ "' || v_mgr_name || '" is now the manager of the "' || v_dept_name || '" department.');
--
--        -- Print team members reporting to the manager
--        DBMS_OUTPUT.PUT_LINE('👥 Employees now reporting to ' || v_mgr_name || ':');
--        FOR rec IN (
--            SELECT INITCAP(c.first_name || ' ' || c.last_name) AS emp_name
--            FROM employee e
--            JOIN candidates c ON e.candidate_id = c.candidate_id
--            WHERE e.department_id = p_department_id
--              AND e.employee_id != p_manager_id
--              AND e.manager_id = p_manager_id
--        ) LOOP
--            DBMS_OUTPUT.PUT_LINE('   ➤ ' || rec.emp_name);
--        END LOOP;
--    END IF;
-- Step 4: Update manager assignment
IF p_manager_id IS NOT NULL THEN
    -- Check if the manager belongs to this department
    SELECT COUNT(*) INTO v_count
    FROM employee
    WHERE employee_id = p_manager_id
      AND department_id = p_department_id;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: The selected manager (Employee ID: ' || p_manager_id || ') does not belong to this department. Assignment aborted.');
        RETURN;
    END IF;

    -- Find active CEO
    DECLARE
        v_ceo_id employee.employee_id%TYPE;
    BEGIN
        SELECT employee_id INTO v_ceo_id
        FROM employee
        WHERE UPPER(role) = 'CEO'
          AND employee_status = 'Active';

        -- Set department manager's manager_id to CEO
        UPDATE employee
        SET manager_id = v_ceo_id
        WHERE employee_id = p_manager_id;

        DBMS_OUTPUT.PUT_LINE('INFO: Manager (Employee ID: ' || p_manager_id || ') will report to the active CEO (Employee ID: ' || v_ceo_id || ').');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_ceo_id := NULL;
            DBMS_OUTPUT.PUT_LINE('INFO: No active CEO found. Manager will not have a manager.');
    END;

    -- Update all employees in the department to report to the manager
    UPDATE employee
    SET manager_id = p_manager_id
    WHERE department_id = p_department_id
      AND employee_id != p_manager_id;

    -- Update department table with manager assignment
    UPDATE department
    SET manager_id = p_manager_id
    WHERE department_id = p_department_id;

    -- Get manager and department name for output
    SELECT INITCAP(c.first_name || ' ' || c.last_name), d.department_name
    INTO v_mgr_name, v_dept_name
    FROM employee e
    JOIN candidates c ON e.candidate_id = c.candidate_id
    JOIN department d ON d.department_id = e.department_id
    WHERE e.employee_id = p_manager_id;

    DBMS_OUTPUT.PUT_LINE('SUCCESS: "' || v_mgr_name || '" has been assigned as the manager of the "' || v_dept_name || '" department.');

    -- List employees reporting to the manager
    DBMS_OUTPUT.PUT_LINE('Employees now reporting to "' || v_mgr_name || '":');
    FOR rec IN (
        SELECT INITCAP(c.first_name || ' ' || c.last_name) AS emp_name
        FROM employee e
        JOIN candidates c ON e.candidate_id = c.candidate_id
        WHERE e.department_id = p_department_id
          AND e.employee_id != p_manager_id
          AND e.manager_id = p_manager_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   - ' || rec.emp_name);
    END LOOP;
END IF;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('�?� Department with ID ' || p_department_id || ' not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('�?� Unexpected error: ' || SQLERRM);
END;


--PROCEDURE apply_leave (
--    p_employee_id IN NUMBER,
--    p_leave_type  IN VARCHAR2,
--    p_start_date  IN DATE,
--    p_end_date    IN DATE
--) AS
--ln_exists NUMBER;
--BEGIN
--    SELECT COUNT(*) INTO ln_exists
--    FROM employee
--    WHERE employee_id = p_employee_id;
--
--    IF ln_exists = 0 THEN
--        RAISE_APPLICATION_ERROR(-20010, 'Employee does not exist with employee_id '||p_employee_id);
--    END IF;
--    
--    IF LOWER(p_leave_type) NOT IN ('sick', 'casual', 'annual', 'maternity', 'paternity', 'unpaid') THEN
--        RAISE_APPLICATION_ERROR(-20011, 'Invalid leave type.Please check the leave type');
--    END IF;
--
--
--    INSERT INTO employee_leaves (
--        employee_id, leaves_type, start_date, end_date, status, approved_by
--    ) VALUES (
--        p_employee_id, p_leave_type, p_start_date, p_end_date, 'Pending', NULL
--    );
--
--    DBMS_OUTPUT.PUT_LINE('Leave request submitted successfully for employee_id'||P_employee_id);
--EXCEPTION
--    WHEN OTHERS THEN
--        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
--END;
--
--PROCEDURE process_leave (
--    p_employee_id IN NUMBER,
--    p_start_date  IN DATE,
--    p_approved_by IN NUMBER DEFAULT NULL,
--    p_action      IN VARCHAR2  -- 'APPROVE' or 'REJECT'
--) AS
--    Ln_days        NUMBER := 0;
--    Ln_balance     NUMBER;
--    Ld_date        DATE;
--    Ld_end_date    DATE;
--    lv2_status     VARCHAR2(20);
--    ln_managerid  NUMBER;
--
--BEGIN
--    -- Get the end_date for this leave request
--    SELECT status,end_date INTO Ld_end_date,lv2_status
--    FROM employee_leaves
--    WHERE employee_id = p_employee_id AND start_date = p_start_date;
--
--    IF LOWER(lv2_status) != 'pending' THEN
--        RAISE_APPLICATION_ERROR(-20007, 'Leave already processed.');
--    END IF;
--    SELECT manager_id INTO ln_managerid
--    FROM employee
--    WHERE employee_id = p_employee_id;
--
--    IF ln_managerid IS NULL THEN
--        RAISE_APPLICATION_ERROR(-20008, 'Employee has no assigned manager.');
--    END IF;
--
--    IF ln_managerid != p_approved_by THEN
--        RAISE_APPLICATION_ERROR(-20009, 'Only the assigned manager can approve/reject this leave.');
--    END IF;
--
--    -- Count only weekdays between start_date and end_date
--    Ld_date := p_start_date;
--    WHILE Ld_date <= Ld_end_date LOOP
--        -- Exclude Saturday (7) and Sunday (1)
--        IF TO_CHAR(Ld_date, 'D') NOT IN ('1','7') THEN
--            Ln_days := Ln_days + 1;
--        END IF;
--        Ld_date := Ld_date + 1;
--    END LOOP;
--
--    IF UPPER(p_action) = 'APPROVE' THEN
--        -- Check leave balance
--        SELECT Leaves_Balance INTO Ln_balance
--        FROM employee
--        WHERE employee_id = p_employee_id;
--
--        IF Ln_days > Ln_balance THEN
--            RAISE_APPLICATION_ERROR(-20003, 'Not enough leave balance.');
--        END IF;
--
--        -- Update leave status to Approved and record approver
--        UPDATE employee_leaves
--        SET status = 'Approved',
--            approved_by = p_approved_by
--        WHERE employee_id = p_employee_id AND start_date = p_start_date;
--
--        -- Deduct leave days from total balance
--        UPDATE employee
--        SET Leaves_Balance = Leaves_Balance - Ln_days
--        WHERE employee_id = p_employee_id;
--
--        DBMS_OUTPUT.PUT_LINE('Leave approved for  '||P_Employee_id||' and ' || Ln_days || ' working days deducted.');
--
--    ELSIF UPPER(p_action) = 'REJECT' THEN
--        -- Just update status to Rejected
--        UPDATE employee_leaves
--        SET status = 'Rejected',
--            approved_by = p_approved_by
--        WHERE employee_id = p_employee_id AND start_date = p_start_date;
--
--        DBMS_OUTPUT.PUT_LINE('Leave rejected for '||P_employee_id);
--
--    ELSE
--        RAISE_APPLICATION_ERROR(-20004, 'Invalid action. Use APPROVE or REJECT.');
--    END IF;
--END;
--PROCEDURE apply_leave (
--    p_employee_id   IN NUMBER,
--    p_leave_type    IN VARCHAR2,  -- e.g., 'Casual'
--    p_start_date    IN DATE,
--    p_end_date      IN DATE,
--    p_reason        IN VARCHAR2
--)
--IS
--    v_leave_type_id leave_type_master.leave_type_id%TYPE;
--    v_is_paid       CHAR(1);
--    v_gender        VARCHAR2(10);
--    v_errors        VARCHAR2(4000) := '';
--    v_overlap_count NUMBER;
--    v_leave_days    NUMBER;
--BEGIN
--    -- 1. Validate leave type exists and get ID, is_paid
--    BEGIN
--        SELECT leave_type_id, is_paid
--        INTO v_leave_type_id, v_is_paid
--        FROM leave_type_master
--        WHERE UPPER(leave_type) = UPPER(p_leave_type);
--    EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            v_errors := v_errors || 'Leave type "' || p_leave_type || '" does not exist. ';
--    END;
--
--    -- 2. Validate employee exists and get gender (to check gender_allowed)
--     BEGIN
--        SELECT c.gender
--        INTO v_gender
--        FROM employee e
--        JOIN candidates c ON e.candidate_id = c.candidate_id
--        WHERE e.employee_id = p_employee_id;
--    EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--            v_errors := v_errors || 'Employee ID ' || p_employee_id || ' not found. ';
--    END;
--    -- 3. If leave type found, check gender allowed for this leave type
--    IF v_leave_type_id IS NOT NULL THEN
--        DECLARE
--            v_allowed_gender VARCHAR2(10);
--        BEGIN
--            SELECT gender_allowed INTO v_allowed_gender FROM leave_type_master WHERE leave_type_id = v_leave_type_id;
--            IF v_allowed_gender <> 'All' AND UPPER(v_allowed_gender) <> UPPER(v_gender) THEN
--                v_errors := v_errors || 'Leave type "' || p_leave_type || '" is not allowed for your gender (' || v_gender || '). ';
--            END IF;
--        END;
--    END IF;
--
--    -- 4. Validate dates
--    IF p_start_date > p_end_date THEN
--        v_errors := v_errors || 'Start date cannot be after end date. ';
--    END IF;
--    IF p_start_date < TRUNC(SYSDATE) THEN
--        v_errors := v_errors || 'Start date cannot be in the past. ';
--    END IF;
--
--    -- 5. Validate no overlapping leaves for this employee (any leave type)
--    IF v_leave_type_id IS NOT NULL THEN
--        SELECT COUNT(*)
--        INTO v_overlap_count
--        FROM leave_application
--        WHERE employee_id = p_employee_id
--          AND status IN ('Pending', 'Approved')
--          AND (
--              (p_start_date BETWEEN start_date AND end_date)
--              OR (p_end_date BETWEEN start_date AND end_date)
--              OR (start_date BETWEEN p_start_date AND p_end_date)
--              OR (end_date BETWEEN p_start_date AND p_end_date)
--          );
--        IF v_overlap_count > 0 THEN
--            v_errors := v_errors || 'You already have an overlapping leave for these dates. ';
--        END IF;
--    END IF;
--
--    -- 6. If errors exist, raise all at once
--    IF v_errors IS NOT NULL AND LENGTH(TRIM(v_errors)) > 0 THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Please correct the following: ' || v_errors);
--    END IF;
--
--    -- 7. Insert leave application with status 'Pending'
--    INSERT INTO leave_application (
--        leave_id, employee_id, leave_type_id, start_date, end_date, status, reason, applied_date
--    ) VALUES (
--        seq_leave_id.NEXTVAL, p_employee_id, v_leave_type_id, p_start_date, p_end_date, 'Pending',initcap( p_reason), SYSDATE
--    );
--
--    COMMIT;
--
--    DBMS_OUTPUT.PUT_LINE('Leave application submitted successfully.');
--
--EXCEPTION
--    WHEN OTHERS THEN
--        RAISE;
--END apply_leave;
--/
 PROCEDURE apply_leave (
    p_employee_id   IN NUMBER,
    p_leave_type    IN VARCHAR2,  -- e.g., 'Casual'
    p_start_date    IN DATE,
    p_end_date      IN DATE,
    p_reason        IN VARCHAR2
)
IS
    v_leave_type_id   leave_type_master.leave_type_id%TYPE;
    v_is_paid         CHAR(1);
    v_gender          VARCHAR2(10);
    v_employee_status VARCHAR2(15);
    v_errors          VARCHAR2(4000) := '';
    v_overlap_count   NUMBER;
BEGIN
    ----------------------------------------------------------------
    -- 1. Check if leave type exists
    ----------------------------------------------------------------
    BEGIN
        SELECT leave_type_id, is_paid
        INTO v_leave_type_id, v_is_paid
        FROM leave_type_master
        WHERE UPPER(leave_type) = UPPER(p_leave_type);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errors := v_errors || '- The leave type "' || p_leave_type || '" is not available. Please choose a valid leave type.' || CHR(10);
    END;

    ----------------------------------------------------------------
    -- 2. Check if employee exists and is active
    ----------------------------------------------------------------
    BEGIN
        SELECT c.gender, e.employee_status
        INTO v_gender, v_employee_status
        FROM employee e
        JOIN candidates c ON e.candidate_id = c.candidate_id
        WHERE e.employee_id = p_employee_id;

        IF v_employee_status <> 'Active' THEN
            v_errors := v_errors || '- Your employment status is "' || v_employee_status || '". Only active employees can apply for leave.' || CHR(10);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errors := v_errors || '- Your employee profile could not be found. Please contact HR.' || CHR(10);
    END;

    ----------------------------------------------------------------
    -- 3. Check gender restrictions for the leave type
    ----------------------------------------------------------------
    IF v_leave_type_id IS NOT NULL THEN
        DECLARE
            v_allowed_gender VARCHAR2(10);
        BEGIN
            SELECT gender_allowed
            INTO v_allowed_gender
            FROM leave_type_master
            WHERE leave_type_id = v_leave_type_id;

            IF v_allowed_gender <> 'All' 
               AND UPPER(v_allowed_gender) <> UPPER(v_gender) THEN
                v_errors := v_errors || '- The "' || p_leave_type || '" leave is available only to ' || v_allowed_gender || ' employees.' || CHR(10);
            END IF;
        END;
    END IF;

    ----------------------------------------------------------------
    -- 4. Validate dates
    ----------------------------------------------------------------
    IF p_start_date > p_end_date THEN
        v_errors := v_errors || '- The start date cannot be after the end date.' || CHR(10);
    END IF;

    IF p_start_date < TRUNC(SYSDATE) THEN
        v_errors := v_errors || '- The start date cannot be in the past. Please choose today or a future date.' || CHR(10);
    END IF;
    
    -- 4. Restrict weekends for non-maternity/paternity leaves
    IF p_leave_type NOT IN ('Maternity', 'Paternity') THEN
        IF TO_CHAR(p_start_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT', 'SUN') THEN
            v_errors := v_errors || '- The start date for "' || p_leave_type || '" leave falls on a weekend. Please select a weekday.' || CHR(10);
        END IF;
    END IF;


    ----------------------------------------------------------------
    -- 5. Check overlapping leaves
    ----------------------------------------------------------------
    IF v_leave_type_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_overlap_count
        FROM leave_application
        WHERE employee_id = p_employee_id
          AND status IN ('Pending', 'Approved')
          AND (
              (p_start_date BETWEEN start_date AND end_date)
              OR (p_end_date BETWEEN start_date AND end_date)
              OR (start_date BETWEEN p_start_date AND p_end_date)
              OR (end_date BETWEEN p_start_date AND p_end_date)
          );

        IF v_overlap_count > 0 THEN
            v_errors := v_errors || '- You already have another leave request during these dates.' || CHR(10);
        END IF;
    END IF;

    ----------------------------------------------------------------
    -- 6. Show all messages together
    ----------------------------------------------------------------
    IF v_errors IS NOT NULL AND LENGTH(TRIM(v_errors)) > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'We could not submit your leave request for the following reason(s):' || CHR(10) || v_errors
        );
    END IF;

    ----------------------------------------------------------------
    -- 7. Submit leave request
    ----------------------------------------------------------------
    INSERT INTO leave_application (
        leave_id, employee_id, leave_type_id, start_date, end_date, status, reason, applied_date
    ) VALUES (
        (SELECT NVL(MAX(leave_id), 0) + 1 FROM leave_application), p_employee_id, v_leave_type_id, p_start_date, p_end_date, 'Pending', INITCAP(p_reason), SYSDATE
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Your leave request has been submitted successfully. It is now pending approval.');
END apply_leave;




--PROCEDURE process_leave (
--    p_leave_id         IN NUMBER,
--    p_action           IN VARCHAR2,       -- 'Approved' or 'Rejected'
--    p_approved_by      IN NUMBER          -- manager's employee_id
--)
--IS
--    -- Variables to hold data from the database
--    v_status            VARCHAR2(20);
--    v_employee_id       NUMBER;
--    v_leave_type_id     NUMBER;
--    v_start_date        DATE;
--    v_end_date          DATE;
--    v_days              NUMBER := 0;
--    v_balance           NUMBER;
--    v_leave_paid        CHAR(1);
--    v_manager_id        NUMBER;
--    v_errors            VARCHAR2(4000) := '';
--
--    -- Leave type IDs for Casual, Sick, and Loss of Pay (LOP)
--    v_casual_id         NUMBER;
--    v_sick_id           NUMBER;
--    v_lop_id            NUMBER;
--    v_casual_balance    NUMBER := 0;
--    v_sick_balance      NUMBER := 0;
--    v_lop_balance       NUMBER := 0;
--    v_remaining_days    NUMBER;
--
--    -- Function to count only weekdays (Mon-Fri) between start and end dates
--    FUNCTION count_weekdays(start_date DATE, end_date DATE) RETURN NUMBER IS
--        v_count NUMBER := 0;
--        v_curr DATE := start_date;
--        v_day NUMBER;
--    BEGIN
--        WHILE v_curr <= end_date LOOP
--            v_day := TO_CHAR(v_curr, 'D'); -- Get day of week (Sunday=1)
--            IF v_day BETWEEN 2 AND 6 THEN  -- Monday to Friday
--                v_count := v_count + 1;
--            END IF;
--            v_curr := v_curr + 1;
--        END LOOP;
--        RETURN v_count;
--    END;
--
--BEGIN
--    -- Step 1: Check if the leave request exists and is still waiting for approval
--    SELECT status, employee_id, leave_type_id, start_date, end_date
--    INTO v_status, v_employee_id, v_leave_type_id, v_start_date, v_end_date
--    FROM leave_application
--    WHERE leave_id = p_leave_id;
--
--    IF v_status != 'Pending' THEN
--        v_errors := v_errors || 'This leave has already been processed. ';
--    END IF;
--
--    -- Step 2: Make sure the action is either "Approved" or "Rejected"
--    IF UPPER(p_action) NOT IN ('APPROVED', 'REJECTED') THEN
--        v_errors := v_errors || 'Action must be "Approved" or "Rejected". ';
--    END IF;
--
--    -- Step 3: Confirm that the person approving is the employee�s manager
--    SELECT manager_id
--    INTO v_manager_id
--    FROM employee
--    WHERE employee_id = v_employee_id;
--
--    IF v_manager_id IS NULL THEN
--        v_errors := v_errors || 'This employee has no manager assigned. ';
--    ELSIF v_manager_id != p_approved_by THEN
--        v_errors := v_errors || 'You are not authorized to approve this leave. ';
--    END IF;
--
--    -- Step 4: If approving, calculate number of working days (weekdays only) in leave
--    IF UPPER(p_action) = 'APPROVED' THEN
--        v_days := count_weekdays(v_start_date, v_end_date);
--        IF v_days <= 0 THEN
--            v_errors := v_errors || 'Leave must be for at least 1 working day. ';
--        END IF;
--    END IF;
--
--    -- Step 5: Cannot approve leave starting in the past
--    IF UPPER(p_action) = 'APPROVED' AND v_start_date < TRUNC(SYSDATE) THEN
--        v_errors := v_errors || 'Leave cannot start in the past. ';
--    END IF;
--
--    -- Step 6: Find leave type IDs for Casual, Sick, and Loss of Pay
--    SELECT leave_type_id INTO v_casual_id FROM leave_type_master WHERE UPPER(leave_type) = 'CASUAL';
--    SELECT leave_type_id INTO v_sick_id FROM leave_type_master WHERE UPPER(leave_type) = 'SICK';
--    SELECT leave_type_id INTO v_lop_id FROM leave_type_master WHERE UPPER(leave_type) = 'LOSS OF PAY';
--
--    -- Step 7: If approving, check leave balances and adjust accordingly
--    IF UPPER(p_action) = 'APPROVED' THEN
--
--        -- Get the employee�s balance and whether leave is paid for the requested leave type
--        BEGIN
--            SELECT NVL(lb.balance_days,0), ltm.is_paid
--            INTO v_balance, v_leave_paid
--            FROM leave_balance lb
--            JOIN leave_type_master ltm ON lb.leave_type_id = ltm.leave_type_id
--            WHERE lb.employee_id = v_employee_id
--              AND lb.leave_type_id = v_leave_type_id
--              AND lb.leave_year = EXTRACT(YEAR FROM v_start_date);
--        EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--                v_balance := 0;
--                v_leave_paid := 'Y'; -- Assume paid if unknown
--        END;
--
--        -- If leave is paid leave, check balance and deduct leave days
--        IF v_leave_paid = 'Y' THEN
--            IF v_balance >= v_days THEN
--                -- Enough leave balance, deduct directly
--                UPDATE leave_balance
--                SET balance_days = balance_days - v_days,
--                    last_updated = SYSDATE
--                WHERE employee_id = v_employee_id
--                  AND leave_type_id = v_leave_type_id
--                  AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--            ELSE
--                -- Not enough balance, apply fallback rules
--
--                v_remaining_days := v_days;
--
--                -- Use up requested leave type balance first
--                IF v_balance > 0 THEN
--                    UPDATE leave_balance
--                    SET balance_days = 0,
--                        last_updated = SYSDATE
--                    WHERE employee_id = v_employee_id
--                      AND leave_type_id = v_leave_type_id
--                      AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                    v_remaining_days := v_remaining_days - v_balance;
--                END IF;
--
--                -- Fallback logic depending on leave type requested
--
--                IF v_leave_type_id = v_sick_id THEN
--                    -- Sick leave requested: fallback Sick ? Casual ? LOP
--
--                    IF v_remaining_days > 0 THEN
--                        SELECT NVL(balance_days,0) INTO v_casual_balance
--                        FROM leave_balance
--                        WHERE employee_id = v_employee_id
--                          AND leave_type_id = v_casual_id
--                          AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                        IF v_casual_balance >= v_remaining_days THEN
--                            UPDATE leave_balance
--                            SET balance_days = balance_days - v_remaining_days,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_casual_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := 0;
--                        ELSE
--                            UPDATE leave_balance
--                            SET balance_days = 0,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_casual_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := v_remaining_days - v_casual_balance;
--                        END IF;
--                    END IF;
--
--                ELSIF v_leave_type_id = v_casual_id THEN
--                    -- Casual leave requested: fallback Casual ? Sick ? LOP
--
--                    IF v_remaining_days > 0 THEN
--                        SELECT NVL(balance_days,0) INTO v_sick_balance
--                        FROM leave_balance
--                        WHERE employee_id = v_employee_id
--                          AND leave_type_id = v_sick_id
--                          AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                        IF v_sick_balance >= v_remaining_days THEN
--                            UPDATE leave_balance
--                            SET balance_days = balance_days - v_remaining_days,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_sick_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := 0;
--                        ELSE
--                            UPDATE leave_balance
--                            SET balance_days = 0,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_sick_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := v_remaining_days - v_sick_balance;
--                        END IF;
--                    END IF;
--
--                ELSE
--                    -- Other leave types: fallback Requested ? Casual ? Sick ? LOP
--
--                    IF v_casual_id != v_leave_type_id AND v_remaining_days > 0 THEN
--                        SELECT NVL(balance_days,0) INTO v_casual_balance
--                        FROM leave_balance
--                        WHERE employee_id = v_employee_id
--                          AND leave_type_id = v_casual_id
--                          AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                        IF v_casual_balance >= v_remaining_days THEN
--                            UPDATE leave_balance
--                            SET balance_days = balance_days - v_remaining_days,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_casual_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := 0;
--                        ELSE
--                            UPDATE leave_balance
--                            SET balance_days = 0,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_casual_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := v_remaining_days - v_casual_balance;
--                        END IF;
--                    END IF;
--
--                    IF v_sick_id NOT IN (v_leave_type_id, v_casual_id) AND v_remaining_days > 0 THEN
--                        SELECT NVL(balance_days,0) INTO v_sick_balance
--                        FROM leave_balance
--                        WHERE employee_id = v_employee_id
--                          AND leave_type_id = v_sick_id
--                          AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                        IF v_sick_balance >= v_remaining_days THEN
--                            UPDATE leave_balance
--                            SET balance_days = balance_days - v_remaining_days,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_sick_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := 0;
--                        ELSE
--                            UPDATE leave_balance
--                            SET balance_days = 0,
--                                last_updated = SYSDATE
--                            WHERE employee_id = v_employee_id
--                              AND leave_type_id = v_sick_id
--                              AND leave_year = EXTRACT(YEAR FROM v_start_date);
--
--                            v_remaining_days := v_remaining_days - v_sick_balance;
--                        END IF;
--                    END IF;
--                END IF;
--
--                -- Finally, remaining days become Loss of Pay (LOP)
--                IF v_remaining_days > 0 THEN
--                    BEGIN
--                        SELECT balance_days INTO v_lop_balance
--                        FROM leave_balance
--                        WHERE employee_id = v_employee_id
--                          AND leave_type_id = v_lop_id
--                          AND leave_year = EXTRACT(YEAR FROM v_start_date);
--                    EXCEPTION
--                        WHEN NO_DATA_FOUND THEN
--                            INSERT INTO leave_balance (employee_id, leave_type_id, leave_year, balance_days, last_updated)
--                            VALUES (v_employee_id, v_lop_id, EXTRACT(YEAR FROM v_start_date), 0, SYSDATE);
--
--                            v_lop_balance := 0;
--                    END;
--
--                    UPDATE leave_balance
--                    SET balance_days = balance_days + v_remaining_days,
--                        last_updated = SYSDATE
--                    WHERE employee_id = v_employee_id
--                      AND leave_type_id = v_lop_id
--                      AND leave_year = EXTRACT(YEAR FROM v_start_date);
--                END IF;
--
--            END IF;
--
--        ELSE
--            -- Leave is unpaid, no deduction needed
--            NULL;
--        END IF;
--
--        -- Mark leave application approved
--        UPDATE leave_application
--        SET status = 'Approved',
--            approved_by = p_approved_by
--        WHERE leave_id = p_leave_id;
--
--    ELSIF UPPER(p_action) = 'REJECTED' THEN
--        -- Mark leave application rejected
--        UPDATE leave_application
--        SET status = 'Rejected',
--            approved_by = p_approved_by
--        WHERE leave_id = p_leave_id;
--    END IF;
--
--    -- Raise errors if any
--    IF v_errors IS NOT NULL AND LENGTH(TRIM(v_errors)) > 0 THEN
--        RAISE_APPLICATION_ERROR(-20011, RTRIM(v_errors));
--    END IF;
--
--    COMMIT;
--
--    DBMS_OUTPUT.PUT_LINE('Leave ' || p_action || ' successfully.');
--
--EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--        RAISE_APPLICATION_ERROR(-20012, 'Leave application or manager data not found.');
--    WHEN OTHERS THEN
--        RAISE;
--END process_leave;
--
PROCEDURE process_leave (
    p_leave_id    IN NUMBER,
    p_action      IN VARCHAR2,   -- 'Approved' or 'Rejected'
    p_approved_by IN NUMBER      -- manager's employee_id
)
IS
    v_status         VARCHAR2(20);
    v_employee_id    NUMBER;
    v_leave_type_id  NUMBER;
    v_start_date     DATE;
    v_end_date       DATE;
    v_days           NUMBER := 0;
    v_manager_id     NUMBER;

    -- Leave type IDs
    v_casual_id      NUMBER;
    v_sick_id        NUMBER;
    v_lop_id         NUMBER;
    v_maternity_id   NUMBER;
    v_paternity_id   NUMBER;

    -- Annual limit for leave types
    v_annual_limit   NUMBER := 0;

    -- Balances
    v_balance        NUMBER := 0;
    v_leave_paid     CHAR(1);
    v_casual_used    NUMBER := 0;
    v_sick_used      NUMBER := 0;
    v_lop_used       NUMBER := 0;

v_maternity_used   NUMBER := 0;
v_paternity_used   NUMBER := 0;

v_casual_balance   NUMBER := 0;
v_sick_balance     NUMBER := 0;
v_maternity_balance NUMBER := 0;
v_paternity_balance NUMBER := 0;

v_leave_type       VARCHAR2(20);

        v_manager_name VARCHAR2(100);
        v_candidate_id NUMBER;

    v_remaining_days NUMBER := 0;

    -- Function to count weekdays (Monday to Friday)
    FUNCTION count_weekdays(start_date DATE, end_date DATE) RETURN NUMBER IS
        v_count NUMBER := 0;
        v_curr DATE := start_date;
        v_day NUMBER;
    BEGIN
        WHILE v_curr <= end_date LOOP
            v_day := TO_CHAR(v_curr,'D');
            IF v_day BETWEEN 2 AND 6 THEN
                v_count := v_count + 1;
            END IF;
            v_curr := v_curr + 1;
        END LOOP;
        RETURN v_count;
    END;

    -- Function to count all days including weekends
    FUNCTION count_all_days(start_date DATE, end_date DATE) RETURN NUMBER IS
    BEGIN
        RETURN end_date - start_date + 1;
    END;

    -- Deduct leave logic with fallback to other leave types
PROCEDURE deduct_leave(p_type IN NUMBER, p_days IN NUMBER) IS
    v_balance_type NUMBER := 0;
    v_days_left    NUMBER := p_days;
    v_curr_type    NUMBER := p_type;
BEGIN
    WHILE v_days_left > 0 LOOP
        -- Get balance for current type
        BEGIN
            SELECT NVL(balance_days, 0)
            INTO v_balance_type
            FROM leave_balance
            WHERE employee_id = v_employee_id
              AND leave_type_id = v_curr_type
              AND leave_year = EXTRACT(YEAR FROM v_start_date);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_balance_type := 0;
        END;

        IF v_balance_type >= v_days_left THEN
            -- Deduct fully
            UPDATE leave_balance
            SET balance_days = balance_days - v_days_left,
                last_updated = SYSDATE
            WHERE employee_id = v_employee_id
              AND leave_type_id = v_curr_type
              AND leave_year = EXTRACT(YEAR FROM v_start_date);

            IF v_curr_type = v_casual_id THEN v_casual_used := v_casual_used + v_days_left;
            ELSIF v_curr_type = v_sick_id THEN v_sick_used := v_sick_used + v_days_left;
            ELSIF v_curr_type = v_lop_id THEN v_lop_used := v_lop_used + v_days_left;
            END IF;

            v_days_left := 0; -- all allocated
        ELSE
            -- Use whatever is left, move on
            UPDATE leave_balance
            SET balance_days = 0,
                last_updated = SYSDATE
            WHERE employee_id = v_employee_id
              AND leave_type_id = v_curr_type
              AND leave_year = EXTRACT(YEAR FROM v_start_date);

            IF v_curr_type = v_casual_id THEN v_casual_used := v_casual_used + v_balance_type;
            ELSIF v_curr_type = v_sick_id THEN v_sick_used := v_sick_used + v_balance_type;
            ELSIF v_curr_type = v_lop_id THEN v_lop_used := v_lop_used + v_balance_type;
            END IF;

            v_days_left := v_days_left - v_balance_type;
        END IF;

        -- If still days left, move to next type
        IF v_days_left > 0 THEN
            IF v_curr_type = v_casual_id THEN
                v_curr_type := v_sick_id;
            ELSIF v_curr_type = v_sick_id THEN
                v_curr_type := v_lop_id;
            ELSIF v_curr_type = v_lop_id THEN
        -- ? All remaining goes to LOP (unlimited)
                v_lop_used := v_lop_used + v_days_left;
                v_days_left := 0;
                EXIT;

            END IF;
        END IF;
    END LOOP;
END;


BEGIN
    -- Step 1: Check leave request exists
    BEGIN
        SELECT status, employee_id, leave_type_id, start_date, end_date
        INTO v_status, v_employee_id, v_leave_type_id, v_start_date, v_end_date
        FROM leave_application
        WHERE leave_id=p_leave_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('The leave request with the given ID does not exist. Please check the leave ID.');
        RETURN;
    END;

    -- Step 2: Already processed
    IF v_status != 'Pending' THEN
        DBMS_OUTPUT.PUT_LINE('This leave request has already been processed. Current status is "'||v_status||'". You cannot process it again.');
        RETURN;
    END IF;

    -- Step 3: Validate action
    IF UPPER(p_action) NOT IN ('APPROVED','REJECTED') THEN
        DBMS_OUTPUT.PUT_LINE('The action provided is invalid. Please use either "Approved" or "Rejected".');
        RETURN;
    END IF;
    

    -- Step 4: Validate manager
BEGIN
    -- Step 1: Get the actual manager of the employee
    SELECT manager_id 
    INTO v_manager_id 
    FROM employee 
    WHERE employee_id = v_employee_id;

    -- Step 2: Get candidate_id and name of the manager who tried to approve
    DECLARE
        v_wrong_manager_name VARCHAR2(100);
        v_actual_manager_name VARCHAR2(100);
        v_actual_candidate_id NUMBER;
        v_wrong_candidate_id NUMBER;
    BEGIN
        -- Get wrong approver details
        SELECT candidate_id
        INTO v_wrong_candidate_id
        FROM employee
        WHERE employee_id = p_approved_by;

        SELECT INITCAP(first_name || ' ' || last_name)
        INTO v_wrong_manager_name
        FROM candidates
        WHERE candidate_id = v_wrong_candidate_id;

        -- Get actual manager details
        IF v_manager_id IS NOT NULL THEN
            SELECT candidate_id
            INTO v_actual_candidate_id
            FROM employee
            WHERE employee_id = v_manager_id;

            SELECT INITCAP(first_name || ' ' || last_name)
            INTO v_actual_manager_name
            FROM candidates
            WHERE candidate_id = v_actual_candidate_id;
        END IF;

        -- Step 3: Validate manager assignment
        IF v_manager_id IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(' Leave approval cannot proceed. The employee does not have a manager assigned.');
            RETURN;
        ELSIF v_manager_id != p_approved_by THEN
            DBMS_OUTPUT.PUT_LINE('Leave approval failed: You are not authorized to approve this leave.');
            DBMS_OUTPUT.PUT_LINE('Employee: ' || v_employee_id);
            DBMS_OUTPUT.PUT_LINE('Actual manager of the employee: ' || NVL(v_actual_manager_name,'Unknown'));
            DBMS_OUTPUT.PUT_LINE('You attempted to approve as: ' || NVL(v_wrong_manager_name,'Unknown'));
            RETURN;
        END IF;

    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(' Leave approval failed: Employee or manager records not found. Please check the system.');
            RETURN;
    END;
END;

    -- Step 5: Fetch leave type IDs
    SELECT leave_type_id INTO v_casual_id FROM leave_type_master WHERE UPPER(leave_type)='CASUAL';
    SELECT leave_type_id INTO v_sick_id FROM leave_type_master WHERE UPPER(leave_type)='SICK';
    SELECT leave_type_id INTO v_lop_id FROM leave_type_master WHERE UPPER(leave_type)='LOSS OF PAY';
    SELECT leave_type_id INTO v_maternity_id FROM leave_type_master WHERE UPPER(leave_type)='MATERNITY';
    SELECT leave_type_id INTO v_paternity_id FROM leave_type_master WHERE UPPER(leave_type)='PATERNITY';
    SELECT leave_type
    INTO v_leave_type
    FROM leave_type_master
    WHERE leave_type_id = v_leave_type_id;

    -- Step 6: Calculate leave days and validate limits
--    IF v_leave_type_id IN (v_maternity_id,v_paternity_id) THEN
--        v_days := count_all_days(v_start_date,v_end_date);
--        SELECT annual_limit INTO v_annual_limit
--        FROM leave_type_master
--        WHERE leave_type_id=v_leave_type_id;
--
--        IF v_days>v_annual_limit THEN
--            DBMS_OUTPUT.PUT_LINE('The requested maternity/paternity leave duration ('||v_days||' days) exceeds the maximum allowed limit ('||v_annual_limit||' days). Please adjust the leave duration.');
--            RETURN;
--        END IF;
--
--    ELSE
--        v_days := count_weekdays(v_start_date,v_end_date);
--
--        IF v_days<=0 THEN
--            DBMS_OUTPUT.PUT_LINE('The leave duration must include at least one working day (Monday to Friday). Please adjust the dates.');
--            RETURN;
--        END IF;
--
--        IF v_start_date<TRUNC(SYSDATE) THEN
--            DBMS_OUTPUT.PUT_LINE('The leave cannot start in the past. Please select a start date from today or later.');
--            RETURN;
--        END IF;
--
--        -- Deduct balances with fallback
--        deduct_leave(v_leave_type_id,v_days);
--    END IF;
-- Step 6: Calculate leave days and validate limits (No deduction here)
IF v_leave_type_id IN (v_maternity_id, v_paternity_id) THEN
    v_days := count_all_days(v_start_date, v_end_date);

    SELECT annual_limit INTO v_annual_limit
    FROM leave_type_master
    WHERE leave_type_id = v_leave_type_id;

    -- check balance for maternity/paternity
    SELECT NVL(balance_days,0)
    INTO v_balance
    FROM leave_balance
    WHERE employee_id = v_employee_id
      AND leave_type_id = v_leave_type_id
      AND leave_year = EXTRACT(YEAR FROM v_start_date);

    IF v_days > v_balance THEN
        DBMS_OUTPUT.PUT_LINE(
            ' Error: Requested '||v_days||' days, but only '||v_balance||
            ' days are available for '||INITCAP(v_leave_type)||'. Please apply remaining as LOP.'
        );
        RETURN;
    END IF;

ELSE
    v_days := count_weekdays(v_start_date, v_end_date);

    IF v_days <= 0 THEN
        DBMS_OUTPUT.PUT_LINE(' Error: Leave request invalid. No working days (Mon�Fri) in the selected period.');
        RETURN;
    END IF;

    IF v_start_date < TRUNC(SYSDATE) THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: Leave request invalid. Start date ('||TO_CHAR(v_start_date,'DD-MON-YYYY')||') is in the past.'
        );
        RETURN;
    END IF;

    -- check balance
    SELECT NVL(balance_days,0)
    INTO v_balance
    FROM leave_balance
    WHERE employee_id = v_employee_id
      AND leave_type_id = v_leave_type_id
      AND leave_year = EXTRACT(YEAR FROM v_start_date);

    IF v_leave_type_id != v_lop_id AND v_days > v_balance THEN
        DBMS_OUTPUT.PUT_LINE(
            ' Error: Requested '||v_days||' days, but only '||v_balance||
            ' days are available for '||INITCAP(v_leave_type)||'. Please apply remaining as LOP.'
        );
        RETURN;
    END IF;
END IF;

------------------------------------------------------------
-- Step 7: Approve or Reject leave (Update balances only if approved)
IF UPPER(p_action)='APPROVED' THEN

    -- Deduct leave balances
    IF v_leave_type_id = v_lop_id THEN
        v_lop_used := v_days;
    ELSIF v_leave_type_id = v_casual_id THEN
        v_casual_used := v_days;
        v_casual_balance := v_balance - v_days;
    ELSIF v_leave_type_id = v_sick_id THEN
        v_sick_used := v_days;
        v_sick_balance := v_balance - v_days;
    ELSIF v_leave_type_id = v_maternity_id THEN
        v_maternity_used := v_days;
        v_maternity_balance := v_balance - v_days;
    ELSIF v_leave_type_id = v_paternity_id THEN
        v_paternity_used := v_days;
        v_paternity_balance := v_balance - v_days;
    END IF;

    -- Update leave_balance table
    IF v_leave_type_id != v_lop_id THEN
        UPDATE leave_balance
        SET balance_days = balance_days - v_days,
            last_updated = SYSDATE
        WHERE employee_id = v_employee_id
          AND leave_type_id = v_leave_type_id
          AND leave_year = EXTRACT(YEAR FROM v_start_date);
    END IF;

    -- Mark leave as approved
    UPDATE leave_application
    SET status='Approved', approved_by=p_approved_by
    WHERE leave_id=p_leave_id;

    -- Display summary
    DBMS_OUTPUT.PUT_LINE(' Leave Approved Successfully.');
    DBMS_OUTPUT.PUT_LINE(' Summary:');
    DBMS_OUTPUT.PUT_LINE('Total leave days requested: ' || v_days);

    IF v_casual_used > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Casual leave approved: ' || v_casual_used ||
                             ' (Remaining balance: ' || v_casual_balance || ')');
    END IF;

    IF v_sick_used > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Sick leave approved: ' || v_sick_used ||
                             ' (Remaining balance: ' || v_sick_balance || ')');
    END IF;

    IF v_maternity_used > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Maternity leave approved: ' || v_maternity_used ||
                             ' (Remaining balance: ' || v_maternity_balance || ')');
    END IF;

    IF v_paternity_used > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Paternity leave approved: ' || v_paternity_used ||
                             ' (Remaining balance: ' || v_paternity_balance || ')');
    END IF;

    IF v_lop_used > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loss of Pay applied: ' || v_lop_used || ' day(s)');
    END IF;

ELSE
    -- Leave is rejected, no deduction
            -- Find candidate_id of the manager
        SELECT candidate_id
        INTO v_candidate_id
        FROM employee
        WHERE employee_id = p_approved_by;

        -- Get manager's name from candidate table
        SELECT INITCAP(first_name || ' ' || last_name)
        INTO v_manager_name
        FROM candidates
        WHERE candidate_id = v_candidate_id;


    UPDATE leave_application
    SET status='Rejected', approved_by=p_approved_by
    WHERE leave_id=p_leave_id;

        DBMS_OUTPUT.PUT_LINE('Leave request has been rejected.');
        DBMS_OUTPUT.PUT_LINE('Rejected by: ' || v_manager_name);
END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred while processing the leave: ' || SQLERRM);
        RAISE;
END process_leave;



PROCEDURE mark_in_time (
    p_employee_id IN NUMBER
) AS
    ln_exists       NUMBER;
    ld_today        DATE := TRUNC(SYSDATE);
    ln_in_time_set  NUMBER;
BEGIN
    -- Check if employee exists
    SELECT COUNT(*) INTO ln_exists FROM employee WHERE employee_id = p_employee_id;

    IF ln_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee does not exist with ID: ' || p_employee_id);
    END IF;

    -- Check if in-time already exists for today
    SELECT COUNT(*) INTO ln_in_time_set
    FROM employee_attendance
    WHERE employee_id = p_employee_id AND attendance_date = ld_today AND in_time IS NOT NULL;

    IF ln_in_time_set > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'In-Time already recorded for today.');
    END IF;

    -- Insert or update record
    BEGIN
        INSERT INTO employee_attendance (attendance_id,employee_id, attendance_date, in_time,status)
        VALUES (seq_attendance_id.NEXTVAL,p_employee_id, ld_today, SYSTIMESTAMP,'Present');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          RAISE_APPLICATION_ERROR(-20016, 'Attendance already marked for today!');

    END;

    DBMS_OUTPUT.PUT_LINE('Employee ID ' || p_employee_id || ' has entered the company at ' || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS'));
END;


PROCEDURE mark_out_time (
    p_employee_id IN NUMBER
) AS
    ln_exists        NUMBER;
    ld_today         DATE := TRUNC(SYSDATE);
    ln_attendance_id NUMBER;
    ld_in_time       TIMESTAMP;
    ln_out_time_set  NUMBER;
BEGIN
    -- Check if employee exists
    SELECT COUNT(*) INTO ln_exists FROM employee WHERE employee_id = p_employee_id;

    IF ln_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee does not exist with ID: ' || p_employee_id);
    END IF;

    -- Check if in-time exists first
    SELECT in_time, attendance_id INTO ld_in_time, ln_attendance_id
    FROM employee_attendance
    WHERE employee_id = p_employee_id AND attendance_date = ld_today;

    IF ld_in_time IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cannot mark Out-Time without In-Time.');
    END IF;

    -- Check if out-time is already marked
    SELECT COUNT(*) INTO ln_out_time_set
    FROM employee_attendance
    WHERE employee_id = p_employee_id AND attendance_date = ld_today AND out_time IS NOT NULL;

    IF ln_out_time_set > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Out-Time already recorded for today.');
    END IF;

    -- Update Out-Time
    UPDATE employee_attendance
    SET out_time = SYSTIMESTAMP
    WHERE attendance_id = ln_attendance_id;

    DBMS_OUTPUT.PUT_LINE('Employee ID ' || p_employee_id || ' has exited the company at ' || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS'));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'No attendance record found for today. Please mark In-Time first.');
END;


PROCEDURE mark_leave (
    ln_employee_id IN NUMBER
) AS
    ln_exists NUMBER;
BEGIN
    -- Check if employee exists
    SELECT COUNT(*) INTO ln_exists
    FROM employee
    WHERE employee_id = ln_employee_id;

    IF ln_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Employee not found.');
    END IF;

    -- Check if attendance already marked for today
    SELECT COUNT(*) INTO ln_exists
    FROM employee_attendance
    WHERE employee_id = ln_employee_id
      AND attendance_date = TRUNC(SYSDATE);

    IF ln_exists > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Attendance already marked for today.');
    END IF;

    -- Insert Leave
    INSERT INTO employee_attendance (
        attendance_id,employee_id, attendance_date, status
    ) VALUES (
        seq_attendance_id.NEXTVAL,ln_employee_id, TRUNC(SYSDATE), 'Leave'
    );

    DBMS_OUTPUT.PUT_LINE('Employee ID ' || ln_employee_id || ' marked as on Leave today.');
END;


PROCEDURE mark_absentees AS
BEGIN
    INSERT INTO employee_attendance (
        attendance_id, employee_id, attendance_date, status
    )
    SELECT seq_attendance_id.NEXTVAL, e.employee_id, TRUNC(SYSDATE), 'Absent'
    FROM employee e
    WHERE NOT EXISTS (
        SELECT 1 FROM employee_attendance a
        WHERE a.employee_id = e.employee_id AND a.attendance_date = TRUNC(SYSDATE)
    );


    DBMS_OUTPUT.PUT_LINE('All unmarked employees have been marked as Absent for today.');
END;


END pkg_emp_ops;
/





--CREATE OR REPLACE TRIGGER trg_validate_leave
--BEFORE INSERT OR UPDATE ON employee_leaves
--FOR EACH ROW
--DECLARE
--    ln_count   NUMBER;
--    lv_gender VARCHAR2(1);
--BEGIN
--    -- 1. Start date must be before or same as end date
--    IF :NEW.start_date > :NEW.end_date THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Start date must be before or equal to end date.');
--    END IF;
--
--    --  2. Overlap check should run only when:
--    --    a) INSERTING a new leave
--    --    b) UPDATING start_date or end_date
--    IF (:NEW.start_date != :OLD.start_date OR
--        :NEW.end_date   != :OLD.end_date OR
--        INSERTING) THEN
--
--        -- 3. Check if there is any overlapping leave for same employee
--        SELECT COUNT(*) INTO ln_count
--        FROM employee_leaves
--        WHERE employee_id = :NEW.employee_id
--          AND status IN ('Pending', 'Approved')
--          AND (
--              (:NEW.start_date BETWEEN start_date AND end_date)
--              OR (:NEW.end_date BETWEEN start_date AND end_date)
--              OR (start_date BETWEEN :NEW.start_date AND :NEW.end_date)
--              OR (end_date BETWEEN :NEW.start_date AND :NEW.end_date)
--          );
--
--        -- 4. If overlapping leave found, raise error
--        IF ln_count > 0 THEN
--            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
--        END IF;
--        -- 5. Gender-Based Business Rule: Maternity Leave for Female Only
--        IF LOWER(:NEW.leaves_type) = 'maternity' THEN
--            SELECT gender INTO lv_gender
--            FROM employee
--            WHERE employee_id = :NEW.employee_id;
--    
--            IF lv_gender != 'F' THEN
--                RAISE_APPLICATION_ERROR(-20013, 'Maternity leave is only applicable for female employees.');
--            END IF;
--        END IF;
--
--    -- 6. Gender-Based Business Rule: Paternity Leave for Male Only
--    IF LOWER(:NEW.leaves_type) = 'paternity' THEN
--        SELECT gender INTO lv_gender
--        FROM employee
--        WHERE employee_id = :NEW.employee_id;
--
--        IF lv_gender != 'M' THEN
--            RAISE_APPLICATION_ERROR(-20014, 'Paternity leave is only applicable for male employees.');
--        END IF;
--    END IF;
--
--
--    END IF;
--END;

--CREATE OR REPLACE TRIGGER trg_validate_leave
--BEFORE INSERT OR UPDATE ON employee_leaves
--FOR EACH ROW
--DECLARE
--    ln_count   NUMBER;
--    lv_gender VARCHAR2(1);
--BEGIN
--    -- 1. Start date must be before or same as end date
--    IF :NEW.start_date > :NEW.end_date THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Start date must be before or equal to end date.');
--    END IF;
--
--    --  2. Overlap check should run only when:
--    --    a) INSERTING a new leave
--    --    b) UPDATING start_date or end_date
--    IF (:NEW.start_date != :OLD.start_date OR
--        :NEW.end_date   != :OLD.end_date OR
--        INSERTING) THEN
--
--        -- 3. Check if there is any overlapping leave for same employee
--        SELECT COUNT(*) INTO ln_count
--        FROM employee_leaves
--        WHERE employee_id = :NEW.employee_id
--          AND status IN ('Pending', 'Approved')
--          AND (
--              (:NEW.start_date BETWEEN start_date AND end_date)
--              OR (:NEW.end_date BETWEEN start_date AND end_date)
--              OR (start_date BETWEEN :NEW.start_date AND :NEW.end_date)
--              OR (end_date BETWEEN :NEW.start_date AND :NEW.end_date)
--          );
--
--        -- 4. If overlapping leave found, raise error
--        IF ln_count > 0 THEN
--            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
--        END IF;
--        -- 5. Gender-Based Business Rule: Maternity Leave for Female Only
--        IF LOWER(:NEW.leaves_type) = 'maternity' THEN
--            SELECT gender INTO lv_gender
--            FROM employee
--            WHERE employee_id = :NEW.employee_id;
--    
--            IF lv_gender != 'F' THEN
--                RAISE_APPLICATION_ERROR(-20013, 'Maternity leave is only applicable for female employees.');
--            END IF;
--        END IF;
--
--    -- 6. Gender-Based Business Rule: Paternity Leave for Male Only
--    IF LOWER(:NEW.leaves_type) = 'paternity' THEN
--        SELECT gender INTO lv_gender
--        FROM employee
--        WHERE employee_id = :NEW.employee_id;
--
--        IF lv_gender != 'M' THEN
--            RAISE_APPLICATION_ERROR(-20014, 'Paternity leave is only applicable for male employees.');
--        END IF;
--    END IF;
--
--
--    END IF;
--END;


--CREATE OR REPLACE TRIGGER trg_validate_leave
--BEFORE INSERT OR UPDATE ON employee_leaves
--FOR EACH ROW
--DECLARE
--    ln_count   NUMBER;
--    lv_gender VARCHAR2(1);
--BEGIN
--    -- 1. Start date must be before or same as end date
--    IF :NEW.start_date > :NEW.end_date THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Start date must be before or equal to end date.');
--    END IF;
--
--    --  2. Overlap check should run only when:
--    --    a) INSERTING a new leave
--    --    b) UPDATING start_date or end_date
--    IF (:NEW.start_date != :OLD.start_date OR
--        :NEW.end_date   != :OLD.end_date OR
--        INSERTING) THEN
--
--        -- 3. Check if there is any overlapping leave for same employee
--        SELECT COUNT(*) INTO ln_count
--        FROM employee_leaves
--        WHERE employee_id = :NEW.employee_id
--          AND status IN ('Pending', 'Approved')
--          AND (
--              (:NEW.start_date BETWEEN start_date AND end_date)
--              OR (:NEW.end_date BETWEEN start_date AND end_date)
--              OR (start_date BETWEEN :NEW.start_date AND :NEW.end_date)
--              OR (end_date BETWEEN :NEW.start_date AND :NEW.end_date)
--          );
--
--        -- 4. If overlapping leave found, raise error
--        IF ln_count > 0 THEN
--            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
--        END IF;
--        -- 5. Gender-Based Business Rule: Maternity Leave for Female Only
--        IF LOWER(:NEW.leaves_type) = 'maternity' THEN
--            SELECT gender INTO lv_gender
--            FROM employee
--            WHERE employee_id = :NEW.employee_id;
--    
--            IF lv_gender != 'F' THEN
--                RAISE_APPLICATION_ERROR(-20013, 'Maternity leave is only applicable for female employees.');
--            END IF;
--        END IF;
--
--    -- 6. Gender-Based Business Rule: Paternity Leave for Male Only
--    IF LOWER(:NEW.leaves_type) = 'paternity' THEN
--        SELECT gender INTO lv_gender
--        FROM employee
--        WHERE employee_id = :NEW.employee_id;
--
--        IF lv_gender != 'M' THEN
--            RAISE_APPLICATION_ERROR(-20014, 'Paternity leave is only applicable for male employees.');
--        END IF;
--    END IF;
--
--
--    END IF;
--END;
--

--CREATE OR REPLACE TRIGGER trg_validate_leave
--BEFORE INSERT OR UPDATE ON employee_leaves
--FOR EACH ROW
--DECLARE
--    ln_count   NUMBER;
--    lv_gender VARCHAR2(1);
--BEGIN
--    -- 1. Start date must be before or same as end date
--    IF :NEW.start_date > :NEW.end_date THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Start date must be before or equal to end date.');
--    END IF;
--
--    --  2. Overlap check should run only when:
--    --    a) INSERTING a new leave
--    --    b) UPDATING start_date or end_date
--    IF (:NEW.start_date != :OLD.start_date OR
--        :NEW.end_date   != :OLD.end_date OR
--        INSERTING) THEN
--
--        -- 3. Check if there is any overlapping leave for same employee
--        SELECT COUNT(*) INTO ln_count
--        FROM employee_leaves
--        WHERE employee_id = :NEW.employee_id
--          AND status IN ('Pending', 'Approved')
--          AND (
--              (:NEW.start_date BETWEEN start_date AND end_date)
--              OR (:NEW.end_date BETWEEN start_date AND end_date)
--              OR (start_date BETWEEN :NEW.start_date AND :NEW.end_date)
--              OR (end_date BETWEEN :NEW.start_date AND :NEW.end_date)
--          );
--
--        -- 4. If overlapping leave found, raise error
--        IF ln_count > 0 THEN
--            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
--        END IF;
--        -- 5. Gender-Based Business Rule: Maternity Leave for Female Only
--        IF LOWER(:NEW.leaves_type) = 'maternity' THEN
--            SELECT gender INTO lv_gender
--            FROM employee
--            WHERE employee_id = :NEW.employee_id;
--    
--            IF lv_gender != 'F' THEN
--                RAISE_APPLICATION_ERROR(-20013, 'Maternity leave is only applicable for female employees.');
--            END IF;
--        END IF;
--
--    -- 6. Gender-Based Business Rule: Paternity Leave for Male Only
--    IF LOWER(:NEW.leaves_type) = 'paternity' THEN
--        SELECT gender INTO lv_gender
--        FROM employee
--        WHERE employee_id = :NEW.employee_id;
--
--        IF lv_gender != 'M' THEN
--            RAISE_APPLICATION_ERROR(-20014, 'Paternity leave is only applicable for male employees.');
--        END IF;
--    END IF;
--
--
--    END IF;
--END;
--

CREATE OR REPLACE TRIGGER trg_prevent_duplicate_attendance
BEFORE INSERT ON employee_attendance
FOR EACH ROW
DECLARE
    ln_count NUMBER;
BEGIN
    -- Validations only for 'Present' status
    IF LOWER(:NEW.status) = 'present' THEN
        -- In-time must not be NULL
        IF :NEW.in_time IS NULL THEN
            RAISE_APPLICATION_ERROR(-20006, 'In Time cannot be null when marking Present.');
        END IF;

        -- In-time must be between 09:00 and 11:00
--        IF TO_CHAR(:NEW.in_time, 'HH24:MI') NOT BETWEEN '0:00' AND '11:00' THEN
--            RAISE_APPLICATION_ERROR(-20007, 'In Time must be between 09:00 and 11:00 for Present employees.');
--        END IF;

        -- If out_time is provided, it must be after in_time
        IF :NEW.out_time IS NOT NULL AND :NEW.out_time <= :NEW.in_time THEN
            RAISE_APPLICATION_ERROR(-20008, 'Out Time must be after In Time.');
        END IF;
    END IF;

    -- For 'Leave' and 'Absent', in_time and out_time must be NULL
    IF LOWER(:NEW.status) IN ('leave', 'absent') THEN
        IF :NEW.in_time IS NOT NULL OR :NEW.out_time IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20009, 'In Time and Out Time must be null for Leave or Absent status.');
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validate_out_time
BEFORE UPDATE OF out_time ON employee_attendance
FOR EACH ROW
BEGIN
    -- Validate out_time is not null
    IF :NEW.out_time IS NULL THEN
        RAISE_APPLICATION_ERROR(-20008, 'Out Time cannot be null when updating.');
    END IF;

    -- Ensure in_time exists first
    IF :OLD.in_time IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'Cannot set Out Time without In Time.');
    END IF;

    -- Ensure out_time is after in_time
    IF :NEW.out_time <= :OLD.in_time THEN
        RAISE_APPLICATION_ERROR(-20010, 'Out Time must be later than In Time.');
    END IF;

--    IF TO_CHAR(:NEW.out_time, 'HH24:MI') > '17:00' THEN
--        RAISE_APPLICATION_ERROR(-20011, 'Out Time cannot be later than 22:00.');
--    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_check_leave_type_exists
BEFORE INSERT OR UPDATE ON leave_type_master
FOR EACH ROW
DECLARE
    v_exists        NUMBER := 0;  
    v_errors        VARCHAR2(4000) := '';  

BEGIN
    -- 0. Check if leave_type is NULL
    IF :NEW.leave_type IS NULL OR LENGTH(TRIM(:NEW.leave_type)) = 0 THEN
        v_errors := v_errors || 'Leave type cannot be empty. ';
    END IF;

    -- 1. Check duplicate in leave_type_master
    SELECT COUNT(*)
    INTO v_exists
    FROM leave_type_master
    WHERE UPPER(TRIM(leave_type)) = UPPER(TRIM(:NEW.leave_type))
      AND (:OLD.leave_type IS NULL OR leave_type != :OLD.leave_type);

    IF v_exists > 0 THEN
        v_errors := v_errors || 'The leave type "' || :NEW.leave_type || '" already exists. ';
    END IF;

    -- 2. Validate against master_data
    SELECT COUNT(*)
    INTO v_exists
    FROM master_data
    WHERE UPPER(TRIM(masterdata_value)) = UPPER(TRIM(:NEW.leave_type))
      AND masterdata_type = 'LEAVE_TYPE';

    IF v_exists = 0 THEN
        v_errors := v_errors || 'The leave type "' || :NEW.leave_type || '" is not recognized in master list. ';
    END IF;

    -- 3. Validate is_paid
    IF :NEW.is_paid NOT IN ('Y','N') THEN
        v_errors := v_errors || 'Please specify if leave is paid ("Y") or unpaid ("N"). ';
    END IF;

    -- 4. Validate gender_allowed
    IF :NEW.gender_allowed NOT IN ('All','M','F') THEN
        v_errors := v_errors || 'Allowed gender must be "All", "M", or "F". ';
    END IF;

    -- 5. Validate carry_forward
    IF :NEW.carry_forward IS NOT NULL AND :NEW.carry_forward NOT IN ('Y','N') THEN
        v_errors := v_errors || 'Carry forward must be "Y" or "N". ';
    END IF;

    -- 6. Assign default values for specific leave types
   CASE UPPER(TRIM(:NEW.leave_type))
    WHEN 'LOSS OF PAY' THEN
        :NEW.annual_limit := 0;
        :NEW.is_paid := 'N';
        :NEW.carry_forward := 'N';
        :NEW.gender_allowed := 'All';
    WHEN 'PATERNITY' THEN
        :NEW.annual_limit := 10;
        :NEW.is_paid := 'Y';
        :NEW.gender_allowed := 'M';
        :NEW.carry_forward := 'N';
    WHEN 'MATERNITY' THEN
        :NEW.annual_limit := 182;
        :NEW.is_paid := 'Y';
        :NEW.gender_allowed := 'F';
        :NEW.carry_forward := 'N';
    WHEN 'CASUAL' THEN
        :NEW.carry_forward := 'Y';
    ELSE
        -- Default: don’t override whatever was provided
        NULL;
END CASE;

    -- 7. Raise all collected errors together
    IF LENGTH(TRIM(v_errors)) > 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Please correct the following: ' || v_errors);
    END IF;

END;
/


CREATE OR REPLACE TRIGGER trg_insert_leave_balance
AFTER INSERT ON employee
FOR EACH ROW
DECLARE
    v_gender candidates.gender%TYPE;
    v_join_month NUMBER;
    v_months_remaining NUMBER;
BEGIN

    -- 1. Get gender from candidates table
    SELECT gender INTO v_gender
    FROM candidates
    WHERE candidate_id = :NEW.candidate_id;

    -- 2. Calculate months remaining in the year including joining month
    v_join_month := EXTRACT(MONTH FROM :NEW.date_of_joining);
    v_months_remaining := 13 - v_join_month;  -- e.g., Nov = 11, 13-11 = 2 months

    -- 3. Insert initial leave balance records
    FOR rec IN (
        SELECT 
            ltm.leave_type_id,
            ltm.leave_type,
            ltm.annual_limit,
            ltm.is_paid,
            ltm.gender_allowed
        FROM leave_type_master ltm
        WHERE ltm.gender_allowed = 'All'
           OR UPPER(ltm.gender_allowed) = UPPER(v_gender)
    ) LOOP
        DECLARE
            v_balance NUMBER := 0;
        BEGIN
            -- Pro-rate Casual and Sick leaves
            IF UPPER(rec.leave_type) IN ('CASUAL', 'SICK') THEN
                v_balance := ROUND(NVL(rec.annual_limit,0) * (v_months_remaining / 12), 0);
            ELSE
                -- Full entitlement for special leaves (Maternity/Paternity/LOP)
                v_balance := NVL(rec.annual_limit,0);
            END IF;

            -- Insert into leave_balance table
            INSERT INTO leave_balance (
                employee_id, 
                leave_type_id, 
                balance_days, 
                leave_year
            ) VALUES (
                :NEW.employee_id,
                rec.leave_type_id,
                v_balance,
                EXTRACT(YEAR FROM :NEW.date_of_joining)
            );
        END;
    END LOOP;
END;

