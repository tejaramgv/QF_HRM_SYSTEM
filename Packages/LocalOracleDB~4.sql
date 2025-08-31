CREATE TABLE exit_management (
    exit_id           NUMBER PRIMARY KEY, -- unique exit record
    employee_id       NUMBER NOT NULL,                                     -- FK to employee table
    exit_reason_id    NUMBER NOT NULL,                                     -- FK to master_data(masterdata_id)
    exit_date         DATE NOT NULL,                                       -- employee’s last working date
    exit_comments     VARCHAR2(500),                                       -- optional free-text comments
    created_at        DATE DEFAULT SYSDATE NOT NULL,                       -- record creation timestamp

    CONSTRAINT fk_exit_emp FOREIGN KEY (employee_id) 
        REFERENCES employee(employee_id),

    CONSTRAINT fk_exit_reason FOREIGN KEY (exit_reason_id) 
        REFERENCES master_data(masterdata_id)
);

ALTER TABLE exit_management
ADD created_by NUMBER NOT NULL; -- FK to users/employee table representing HR

CREATE OR REPLACE PROCEDURE record_exit (
    p_employee_id    IN NUMBER,
    p_exit_reason    IN VARCHAR2,
    p_exit_date_str  IN VARCHAR2,
    p_exit_comments  IN VARCHAR2,
    p_created_by     IN NUMBER
)
IS
    v_exit_reason_id   master_data.masterdata_id%TYPE;
    v_exit_date        DATE;
    v_join_date        DATE;
    v_dob              DATE;
    v_errors           VARCHAR2(4000) := '';
    v_retirement_age   NUMBER := 60;
    v_notice_days      NUMBER := 30;
    v_count            NUMBER;
    v_user_role        VARCHAR2(50);
    v_user_status      VARCHAR2(20);
    v_emp_status       VARCHAR2(20);
    v_manager_id       NUMBER;
BEGIN
    -----------------------------------------------------------------
    -- 0. Validate creator: must be active HR Executive or manager of employee
    -----------------------------------------------------------------
    BEGIN
        SELECT role, status INTO v_user_role, v_user_status
        FROM users
        WHERE user_id = p_created_by;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errors := v_errors || 'Error: The user creating the exit record was not found in the system. ';
    END;

    IF v_user_status != 'ACTIVE' THEN
        v_errors := v_errors || 'Error: The user creating the exit record must be ACTIVE. ';
    END IF;

    -----------------------------------------------------------------
    -- 1. Employee existence & join date & manager
    -----------------------------------------------------------------
    BEGIN
        SELECT join_date, status, manager_id INTO v_join_date, v_emp_status, v_manager_id
        FROM employee
        WHERE employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errors := v_errors || 'Error: Employee with the given ID does not exist. ';
    END;

    IF v_emp_status != 'ACTIVE' THEN
        v_errors := v_errors || 'Error: Employee is not active. Cannot process exit. ';
    END IF;

    IF NOT ((v_user_role = 'HR_EXECUTIVE') OR (v_manager_id = p_created_by)) THEN
        v_errors := v_errors || 'Error: Only the employee''s manager or an HR Executive can create an exit record. ';
    END IF;

    -----------------------------------------------------------------
    -- 2. Mandatory Fields Validation
    -----------------------------------------------------------------
    IF p_exit_reason IS NULL THEN
        v_errors := v_errors || 'Error: Exit reason is mandatory. ';
    END IF;

    IF p_exit_date_str IS NULL THEN
        v_errors := v_errors || 'Error: Exit date is mandatory and should be in YYYY-MM-DD format. ';
    END IF;

    -----------------------------------------------------------------
    -- 3. Convert Exit Date
    -----------------------------------------------------------------
    BEGIN
        v_exit_date := TO_DATE(p_exit_date_str,'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            v_errors := v_errors || 'Error: Invalid exit date format. Use YYYY-MM-DD (e.g., 2025-08-31). ';
    END;

    -----------------------------------------------------------------
    -- 4. Exit Reason Validation
    -----------------------------------------------------------------
    BEGIN
        SELECT masterdata_id INTO v_exit_reason_id
        FROM master_data
        WHERE UPPER(masterdata_value) = UPPER(p_exit_reason)
          AND masterdata_type = 'EXIT_REASON';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errors := v_errors || 'Error: Invalid exit reason "' || p_exit_reason || '". Please select a valid reason. ';
    END;

    -----------------------------------------------------------------
    -- 5. Duplicate Exit Check
    -----------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM exit_management
    WHERE employee_id = p_employee_id;

    IF v_count > 0 THEN
        v_errors := v_errors || 'Error: Employee already has an exit record. Multiple exits are not allowed. ';
    END IF;

    -----------------------------------------------------------------
    -- 6. DOB check if RETIREMENT
    -----------------------------------------------------------------
    IF UPPER(p_exit_reason) = 'RETIREMENT' THEN
        BEGIN
            SELECT c.dob INTO v_dob
            FROM candidates c
            JOIN employee e ON e.candidate_id = c.candidate_id
            WHERE e.employee_id = p_employee_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_errors := v_errors || 'Error: DOB is required for retirement validation but not found. ';
        END;

        IF v_dob IS NOT NULL AND MONTHS_BETWEEN(v_exit_date, v_dob)/12 < v_retirement_age THEN
            v_errors := v_errors || 'Error: Employee is not eligible for retirement. Minimum retirement age is ' || v_retirement_age || ' years. ';
        END IF;
    END IF;

    -----------------------------------------------------------------
    -- 7. Real-world Validations
    -----------------------------------------------------------------
    IF v_exit_date < v_join_date THEN
        v_errors := v_errors || 'Error: Exit date (' || TO_CHAR(v_exit_date,'YYYY-MM-DD') || ') cannot be before joining date (' || TO_CHAR(v_join_date,'YYYY-MM-DD') || '). ';
    END IF;

    IF v_exit_date < SYSDATE - 365 THEN
        v_errors := v_errors || 'Error: Exit date cannot be older than one year from today. ';
    END IF;

    IF v_exit_date > SYSDATE + v_notice_days THEN
        v_errors := v_errors || 'Error: Exit date exceeds the allowed notice period of ' || v_notice_days || ' days. ';
    END IF;

    IF TO_CHAR(v_exit_date,'DY','NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT','SUN') THEN
        v_errors := v_errors || 'Error: Exit date falls on a weekend (Saturday/Sunday). Please choose a weekday. ';
    END IF;

    IF UPPER(p_exit_reason) IN ('TERMINATION','PERFORMANCE ISSUES') AND (p_exit_comments IS NULL OR TRIM(p_exit_comments) = '') THEN
        v_errors := v_errors || 'Error: Comments are mandatory for Termination or Performance Issues exits. ';
    END IF;

    -----------------------------------------------------------------
    -- 8. Pending Leave Check
    -----------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM leave_management
    WHERE employee_id = p_employee_id AND status = 'PENDING';

    IF v_count > 0 THEN
        v_errors := v_errors || 'Error: Employee has ' || v_count || ' pending leave(s). Exit cannot be processed until all leaves are approved or rejected. ';
    END IF;

    -----------------------------------------------------------------
    -- 9. Return all accumulated errors if any
    -----------------------------------------------------------------
    IF v_errors IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Cannot create exit record due to the following issues:');
        DBMS_OUTPUT.PUT_LINE(v_errors);
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 10. Insert Exit Record
    -----------------------------------------------------------------
    INSERT INTO exit_management (
        exit_id, employee_id, exit_reason_id, exit_date, exit_comments, created_at, created_by
    ) VALUES (
        exit_management_seq.NEXTVAL,
        p_employee_id,
        v_exit_reason_id,
        v_exit_date,
        p_exit_comments,
        SYSDATE,
        p_created_by
    );

    -- Update employee status to INACTIVE
    UPDATE employee
    SET status = 'INACTIVE'
    WHERE employee_id = p_employee_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Exit record successfully created for Employee ID: ' || p_employee_id);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Unexpected error occurred: ' || SQLERRM);
END record_exit;
/


CREATE OR REPLACE PROCEDURE record_exit (
    p_employee_id    IN NUMBER DEFAULT NULL,
    p_exit_reason    IN VARCHAR2 DEFAULT NULL,
    p_exit_date  IN VARCHAR2 DEFAULT NULL,   -- now as VARCHAR2
    p_exit_comments  IN VARCHAR2 DEFAULT NULL,
    p_created_by     IN NUMBER DEFAULT NULL
)
IS
    ln_exit_reason_id  master_data.masterdata_id%TYPE;
    ld_exit_date       DATE;
    ld_join_date       DATE;
    ld_dob             DATE;
    lv2_errors         VARCHAR2(4000) := '';
    ln_retirement_age  NUMBER := 60;
    ln_notice_days     NUMBER := 30;
    ln_count           NUMBER;
--    lv2_user_role      VARCHAR2(50);
--    lv2_user_status    VARCHAR2(20);
--    lv2_emp_status     VARCHAR2(20);
    ln_manager_id      NUMBER;
    lv2_emp_name       VARCHAR2(4000);
    lv2_user_role      VARCHAR2(4000);
    lv2_user_status    VARCHAR2(4000);
    lv2_emp_status     VARCHAR2(4000);
    ln_exit_id         NUMBER;
BEGIN
    -----------------------------------------------------------------
    -- 0. Mandatory Fields Validation
    -----------------------------------------------------------------
    IF p_employee_id IS NULL THEN
        lv2_errors := lv2_errors || 'Employee ID is required. ';
    END IF;

    IF p_exit_reason IS NULL THEN
        lv2_errors := lv2_errors || 'Exit reason is required. ';
    END IF;

    IF p_exit_date IS NULL THEN
        lv2_errors := lv2_errors || 'Exit date is required and should be in YYYY-MM-DD format. ';
    END IF;

    IF p_created_by IS NULL THEN
        lv2_errors := lv2_errors || 'HR Executive or Manager performing this action must be provided. ';
    END IF;

    IF lv2_errors IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Cannot create exit record due to the following missing mandatory information:');
        DBMS_OUTPUT.PUT_LINE(lv2_errors);
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 1. Validate HR/Manager performing this action
    -----------------------------------------------------------------
    BEGIN
        SELECT role, employee_status INTO lv2_user_role, lv2_user_status
        FROM employee
        WHERE employee_id = p_created_by;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('The HR Executive or Manager performing this action (ID: ' || p_created_by || ') was not found.');
            RETURN;
    END;

    IF UPPER(lv2_user_status) != 'ACTIVE' THEN
        DBMS_OUTPUT.PUT_LINE('The HR Executive or Manager (ID: ' || p_created_by || ') performing this action must be ACTIVE.');
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 2. Employee Existence, Status, Manager, and Name
    -----------------------------------------------------------------
    BEGIN
        SELECT e.date_of_joining, e.employee_status, e.manager_id, c.first_name || ' ' || c.last_name
        INTO ld_join_date, lv2_emp_status, ln_manager_id, lv2_emp_name
        FROM employee e
        JOIN candidates c ON e.candidate_id = c.candidate_id
        WHERE e.employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Employee with ID ' || p_employee_id || ' does not exist.');
            RETURN;
    END;

    IF UPPER(lv2_emp_status) != 'ACTIVE' THEN
        DBMS_OUTPUT.PUT_LINE('Employee ' || lv2_emp_name || ' (ID: ' || p_employee_id || ') is already exited. Exit cannot be processed.');
        RETURN;
    END IF;

    IF NOT ((UPPER(lv2_user_role) = 'HR EXECUTIVE') OR (ln_manager_id = p_created_by)) THEN
        DBMS_OUTPUT.PUT_LINE('Only the employee''s manager or an HR Executive can create an exit record for ' || lv2_emp_name || ' (ID: ' || p_employee_id || ').');
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 3. Convert Exit Date
    -----------------------------------------------------------------
    BEGIN
        -- Trim spaces
        IF NOT REGEXP_LIKE(TRIM(p_exit_date), '^\d{4}-\d{2}-\d{2}$') THEN
            DBMS_OUTPUT.PUT_LINE('Invalid exit date format. Correct format is YYYY-MM-DD (e.g., 2025-08-31).');
            RETURN;
        END IF;

        -- Convert to DATE
        BEGIN
            ld_exit_date := TO_DATE(TRIM(p_exit_date),'YYYY-MM-DD');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Invalid exit date value. Please check the date (e.g., 2025-08-31).');
                RETURN;
        END;
    END;

    -----------------------------------------------------------------
    -- 4. Exit Reason Validation
    -----------------------------------------------------------------
    BEGIN
        SELECT masterdata_id INTO ln_exit_reason_id
        FROM master_data
        WHERE UPPER(masterdata_value) = UPPER(p_exit_reason)
          AND UPPER(masterdata_type) = 'EXIT_REASON';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Invalid exit reason "' || p_exit_reason || '" for ' || lv2_emp_name || ' (ID: ' || p_employee_id || '). Please select a valid reason.');
            RETURN;
    END;

    -----------------------------------------------------------------
    -- 5. Duplicate Exit Check
    -----------------------------------------------------------------
    SELECT COUNT(*) INTO ln_count
    FROM exit_management
    WHERE employee_id = p_employee_id;

    IF ln_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Employee ' || lv2_emp_name || ' (ID: ' || p_employee_id || ') already has an exit record. Multiple exits are not allowed.');
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 6. DOB check for Retirement
    -----------------------------------------------------------------
    IF UPPER(p_exit_reason) = 'RETIREMENT' THEN
        BEGIN
            SELECT c.dob INTO ld_dob
            FROM candidates c
            JOIN employee e ON e.candidate_id = c.candidate_id
            WHERE e.employee_id = p_employee_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Date of Birth is required for retirement validation of ' || lv2_emp_name || ' (ID: ' || p_employee_id || ') but was not found.');
                RETURN;
        END;

        IF MONTHS_BETWEEN(ld_exit_date, ld_dob)/12 < ln_retirement_age THEN
    DBMS_OUTPUT.PUT_LINE(
        'Employee ' || lv2_emp_name || ' (ID: ' || p_employee_id || ') is not eligible for retirement. ' ||
        'Minimum retirement age is ' || ln_retirement_age || ' years. ' ||
        'Current age is ' || FLOOR(MONTHS_BETWEEN(ld_exit_date, ld_dob)/12) || ' years.'
    );
            RETURN;
        END IF;
    END IF;

    -----------------------------------------------------------------
    -- 7. Real-world Validations
    -----------------------------------------------------------------
    IF ld_exit_date < ld_join_date THEN
        DBMS_OUTPUT.PUT_LINE('Exit date (' || TO_CHAR(ld_exit_date,'YYYY-MM-DD') || ') cannot be before ' || lv2_emp_name || '''s joining date (' || TO_CHAR(ld_join_date,'YYYY-MM-DD') || ').');
        RETURN;
    END IF;

    IF ld_exit_date < SYSDATE - 30 THEN
        DBMS_OUTPUT.PUT_LINE('Exit date cannot be older than one month from today for ' || lv2_emp_name || ' (ID: ' || p_employee_id || ').');
        RETURN;
    END IF;

    IF ld_exit_date > SYSDATE + ln_notice_days THEN
        DBMS_OUTPUT.PUT_LINE('Exit date exceeds the allowed notice period of ' || ln_notice_days || ' days for ' || lv2_emp_name || ' (ID: ' || p_employee_id || ').');
        RETURN;
    END IF;

-- Weekend check using DY and NLS_DATE_LANGUAGE
IF TRIM(UPPER(TO_CHAR(ld_exit_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH'))) IN ('SAT','SUN') THEN
    DBMS_OUTPUT.PUT_LINE('Exit date falls on a weekend (Saturday or Sunday) for ' 
        || lv2_emp_name || ' (ID: ' || p_employee_id || '). Please choose a weekday.');
    RETURN;
END IF;




    IF UPPER(p_exit_reason) IN ('TERMINATION','PERFORMANCE ISSUES') AND (p_exit_comments IS NULL OR TRIM(p_exit_comments) = '') THEN
        DBMS_OUTPUT.PUT_LINE('Comments are required for Termination or Performance Issues exits for ' || lv2_emp_name || ' (ID: ' || p_employee_id || ').');
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 8. Pending Leave Check
    -----------------------------------------------------------------
    SELECT COUNT(*) INTO ln_count
    FROM leave_application
    WHERE employee_id = p_employee_id AND UPPER(status) = 'PENDING';

    IF ln_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Employee ' || lv2_emp_name || ' (ID: ' || p_employee_id || ') has ' || ln_count || ' pending leave(s). Exit cannot be processed until all leaves are approved or rejected.');
        RETURN;
    END IF;

    -----------------------------------------------------------------
    -- 9. Insert Exit Record
    -----------------------------------------------------------------
    SELECT NVL(MAX(exit_id),0)+1 
    INTO ln_exit_id
    FROM exit_management;

    INSERT INTO exit_management (
        exit_id, employee_id, exit_reason_id, exit_date, exit_comments, created_at, created_by
    ) VALUES (
        ln_exit_id,
        p_employee_id,
        ln_exit_reason_id,
        ld_exit_date,
        p_exit_comments,
        SYSDATE,
        p_created_by
    );

    -- Update employee status to INACTIVE
    UPDATE employee
    SET employee_status = 'Inactive'
    WHERE employee_id = p_employee_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Exit record has been successfully created for ' || lv2_emp_name || ' (ID: ' || p_employee_id || ').');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Unexpected error occurred: ' || SQLERRM);
END record_exit;


select * from employee;


BEGIN
    record_exit(
        p_employee_id    => 1354,
      p_exit_reason    => 'Resignation',
        p_exit_date  => '2025-09-15',
--        p_exit_comments  => '',   -- empty string instead of NULL
        p_created_by     => 1350  -- HR Executive or Manager of employee 101
    );
END;
/

select * from employee;

select * from exit_management;

SELECT TO_CHAR(SYSDATE, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') AS today_day
FROM dual;


CREATE OR REPLACE PROCEDURE list_exit_employees (
    p_manager_id      IN NUMBER   DEFAULT NULL,
    p_manager_name    IN VARCHAR2 DEFAULT NULL,
    p_department_name IN VARCHAR2 DEFAULT NULL,
    p_city_name       IN VARCHAR2 DEFAULT NULL,
    p_country_name    IN VARCHAR2 DEFAULT NULL,
    p_band_name       IN VARCHAR2 DEFAULT NULL,
    p_exit_reason     IN VARCHAR2 DEFAULT NULL
) IS
    v_found       BOOLEAN := FALSE;
    v_total_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('EMP_ID | FULL_NAME       | ROLE              | BAND  | EXIT_REASON       | MANAGER         | DEPARTMENT | CITY       | COUNTRY   ');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------');

    FOR emp_rec IN (
        SELECT 
            e.employee_id,
            INITCAP(c.first_name || ' ' || c.last_name) AS full_name,
            e.role,
            NVL(b.band, '-') AS band,
            md_exit.masterdata_value AS exit_reason,
            NVL(mgr_c.first_name || ' ' || mgr_c.last_name, '-') AS manager_name,
            d.department_name,
            city_md.masterdata_value AS city,
            country_md.masterdata_value AS country
        FROM exit_management em
        JOIN employee e ON em.employee_id = e.employee_id
        JOIN candidates c ON e.candidate_id = c.candidate_id
        LEFT JOIN baseline_salary b ON e.band_id = b.band_id
        JOIN master_data md_exit ON em.exit_reason_id = md_exit.masterdata_id
        JOIN department d ON e.department_id = d.department_id
        LEFT JOIN master_data city_md ON d.city_id = city_md.masterdata_id
        LEFT JOIN master_data country_md ON city_md.parent_id = country_md.masterdata_id
        LEFT JOIN employee mgr ON d.manager_id = mgr.employee_id
        LEFT JOIN candidates mgr_c ON mgr.candidate_id = mgr_c.candidate_id
        WHERE e.employee_status = 'Inactive'
          AND (p_manager_id IS NULL OR d.manager_id = p_manager_id)
          AND (p_manager_name IS NULL OR UPPER(mgr_c.first_name || ' ' || mgr_c.last_name) = UPPER(p_manager_name))
          AND (p_department_name IS NULL OR UPPER(d.department_name) = UPPER(p_department_name))
          AND (p_city_name IS NULL OR UPPER(city_md.masterdata_value) = UPPER(p_city_name))
          AND (p_country_name IS NULL OR UPPER(country_md.masterdata_value) = UPPER(p_country_name))
          AND (p_band_name IS NULL OR UPPER(b.band) = UPPER(p_band_name))
          AND (p_exit_reason IS NULL OR UPPER(md_exit.masterdata_value) = UPPER(p_exit_reason))
        ORDER BY e.employee_id
    ) LOOP
        v_found := TRUE;
        v_total_count := v_total_count + 1;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(emp_rec.employee_id, 7) || '|' ||
            RPAD(emp_rec.full_name, 17) || '|' ||
            RPAD(emp_rec.role, 20) || '|' ||
            RPAD(emp_rec.band, 8) || '|' ||
            RPAD(emp_rec.exit_reason, 19) || '|' ||
            RPAD(emp_rec.manager_name, 17) || '|' ||
            RPAD(emp_rec.department_name, 14) || '|' ||
            RPAD(NVL(emp_rec.city,'-'), 12) || '|' ||
            RPAD(NVL(emp_rec.country,'-'), 10)
        );
    END LOOP;

    IF v_found THEN
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Summary: Total Exited Employees found: ' || v_total_count);
    ELSE
        DBMS_OUTPUT.PUT_LINE('No exited employees found with the specified criteria.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END list_exit_employees;
/




select * from department;


BEGIN
    list_exit_employees(P_manager_name=>'arjun reddy');
END;
/

BEGIN
    list_exit_employees(p_department_name=>'sales');
END;
/

BEGIN
    list_exit_employees(p_country_name=>'India');
END;
/

BEGIN
    list_exit_employees(p_city_name=>'delhi');
END;
/
BEGIN
    list_exit_employees(p_band_name=>'mid');
END;
/

BEGIN
    exit_management_pkg.list_exit_employees(p_exit_reason=>'termination');
END;
/
select * from employee;


CREATE OR REPLACE PROCEDURE exit_analysis_top_3_reasons IS
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOP 3 EXIT REASONS');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('EXIT_REASON', 25) || '| TOTAL_EXITS');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');

    FOR rec IN (
        SELECT 
            md.masterdata_value AS exit_reason,
            COUNT(*) AS total_exits
        FROM exit_management em
        JOIN master_data md 
            ON em.exit_reason_id = md.masterdata_id
        JOIN employee e 
            ON em.employee_id = e.employee_id
        WHERE e.employee_status = 'Inactive'
        GROUP BY md.masterdata_value
        ORDER BY total_exits DESC
    ) LOOP
        v_count := v_count + 1;
        EXIT WHEN v_count > 3;  -- show only top 3

        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.exit_reason, 25) || '| ' || rec.total_exits
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END exit_analysis_top_3_reasons;
/


BEGIN
    exit_management_pkg.exit_analysis_top_3_reasons;
END;
/
