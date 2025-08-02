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
        p_department_id   IN NUMBER DEFAULT NULL,
        p_role            IN VARCHAR2 DEFAULT NULL,
        p_status          IN VARCHAR2 DEFAULT NULL,
        p_band_id         IN NUMBER DEFAULT NULL,
        p_city_id         IN NUMBER DEFAULT NULL,
        p_country_id      IN NUMBER DEFAULT NULL,
        p_manager_id      IN NUMBER DEFAULT NULL
    );
    
    PROCEDURE get_employee_details (
    p_employee_id IN NUMBER
) ;

PROCEDURE update_employee (
    p_employee_id   IN NUMBER,
    p_salary        IN NUMBER DEFAULT NULL,
    p_role          IN VARCHAR2 DEFAULT NULL,
    p_department_id IN NUMBER DEFAULT NULL
);

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
    
    PROCEDURE apply_leave (
    p_employee_id IN NUMBER,
    p_leave_type  IN VARCHAR2,
    p_start_date  IN DATE,
    p_end_date    IN DATE
);

PROCEDURE process_leave (
    p_employee_id IN NUMBER,
    p_start_date  IN DATE,
    p_approved_by IN NUMBER DEFAULT NULL,
    p_action      IN VARCHAR2  -- 'APPROVE' or 'REJECT'
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
END pkg_emp_ops;
/


CREATE OR REPLACE PACKAGE BODY pkg_emp_ops AS
PROCEDURE list_employees (
    p_department_id   IN NUMBER DEFAULT NULL,
    p_role            IN VARCHAR2 DEFAULT NULL,
    p_status          IN VARCHAR2 DEFAULT NULL,
    p_band_id         IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL,
    p_country_id      IN NUMBER DEFAULT NULL,
    p_manager_id      IN NUMBER DEFAULT NULL
) IS
    v_found BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE(' EMP_ID | CAND_ID |   NAME    | ROLE               | BAND  | STATUS   | EXP_YEARS | SALARY   | DEPT_ID | MANAGER_ID | COUNTRY  | CITY |' );
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------------------------------------------------------');

    FOR emp_rec IN (
        SELECT 
            e.employee_id,
            e.candidate_id,
            INITCAP(c.first_name || ' ' || c.last_name) AS full_name,
            e.role,
            b.band,
            e.employee_status,
            ROUND(c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12, 1) AS total_exp,
            e.salary,
            e.department_id,
            e.manager_id,
            city_md.masterdata_value as city,
            country_md.masterdata_value as country
        FROM employee e
        JOIN candidates c ON e.candidate_id = c.candidate_id
        LEFT JOIN baseline_salary b ON b.band_id = e.band_id
        JOIN department d ON d.department_id = e.department_id
        JOIN master_data city_md ON d.city_id = city_md.masterdata_id
        LEFT JOIN master_data country_md ON city_md.parent_id = country_md.masterdata_id
        WHERE (p_department_id IS NULL OR e.department_id = p_department_id)
          AND (p_role IS NULL OR e.role = p_role)
          AND (p_status IS NULL OR e.employee_status = p_status)
          AND (p_band_id IS NULL OR e.band_id = p_band_id)
          AND (p_manager_id IS NULL OR e.manager_id = p_manager_id)
          AND (p_city_id IS NULL OR d.city_id = p_city_id)
          AND (p_country_id IS NULL OR city_md.parent_id = p_country_id)
          AND e.employee_status='Active'
        ORDER BY e.employee_id
    ) LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(emp_rec.employee_id, 8) || '|' ||
            RPAD(emp_rec.candidate_id, 9) || '|' ||
            RPAD(emp_rec.full_name, 11) || '|' ||
            RPAD(emp_rec.role, 20) || '|' ||
            RPAD(NVL(emp_rec.band, '-'), 7) || '|' ||
            RPAD(emp_rec.employee_status, 11) || '|' ||
            RPAD(emp_rec.total_exp, 10) || '|' ||
            RPAD(emp_rec.salary, 10) || '|' ||
            RPAD(emp_rec.department_id, 9) || '|' ||
            RPAD(nvl(to_char(emp_rec.manager_id),'-'), 12) || '|' ||
            RPAD(emp_rec.country, 10) || '|' ||
            RPAD(emp_rec.city, 9)
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
           e.leaves_balance,

           d.department_name,
           city_md.masterdata_value,
           country_md.masterdata_value,

           (SELECT INITCAP(c.first_name || ' ' || c.last_name)
            FROM employee m
            JOIN candidates mc ON mc.candidate_id = m.candidate_id
            WHERE m.employee_id = e.manager_id)
    INTO v_full_name, v_gender, v_dob, v_email, v_contact, v_id_proof_type,
         v_id_proof_number, v_degree, v_college, v_experience,
         v_role, v_status, v_salary, v_band, v_doj, v_leave_balance,
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
DBMS_OUTPUT.PUT_LINE('Salary           : â‚¹' || v_salary);
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
    p_employee_id   IN NUMBER,
    p_salary        IN NUMBER DEFAULT NULL,
    p_role          IN VARCHAR2 DEFAULT NULL,
    p_department_id IN NUMBER DEFAULT NULL
) IS
    v_salary       employee.salary%TYPE;
    v_role         employee.role%TYPE;
    v_band_id      employee.band_id%TYPE;
    v_old_dept     employee.department_id%TYPE;
    v_exp          NUMBER;
    v_band_found   BOOLEAN := FALSE;
    v_is_manager   NUMBER := 0;
BEGIN
    -- Fetch current role and salary if not provided
    SELECT 
        NVL(p_salary, salary),
        NVL(p_role, role),
        department_id
    INTO 
        v_salary, v_role, v_old_dept
    FROM employee
    WHERE employee_id = p_employee_id;

    -- Get experience from candidate + tenure
    SELECT ROUND(
        c.years_of_experience + MONTHS_BETWEEN(SYSDATE, e.date_of_joining) / 12,
        1
    )
    INTO v_exp
    FROM employee e
    JOIN candidates c ON e.candidate_id = c.candidate_id
    WHERE e.employee_id = p_employee_id;

    -- Get matching band
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
            NULL; -- Try fallback
    END;

    -- Fallback band assignment if experience > defined
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
                RAISE_APPLICATION_ERROR(-20002, 'â?Œ No suitable band found for given role, salary, and experience.');
        END;
    END IF;

    -- Update salary
    IF p_salary IS NOT NULL THEN
        UPDATE employee
        SET salary = p_salary
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('âœ… Salary updated to ' || p_salary);
    END IF;

    -- Update role
    IF p_role IS NOT NULL THEN
        UPDATE employee
        SET role = p_role
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('âœ… Role updated to ' || p_role);
    END IF;

    -- Update band
    IF p_role IS NOT NULL OR p_salary IS NOT NULL THEN
    UPDATE employee
    SET band_id = v_band_id
    WHERE employee_id = p_employee_id;
    DBMS_OUTPUT.PUT_LINE('âœ… Band ID set to ' || v_band_id);
    END IF;

    -- Update department and manager
    IF p_department_id IS NOT NULL THEN
        UPDATE employee
        SET department_id = p_department_id
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('âœ… Department updated to ' || p_department_id);

        -- Get department manager
        DECLARE
            v_dept_mgr_id department.manager_id%TYPE;
        BEGIN
            SELECT manager_id INTO v_dept_mgr_id
            FROM department
            WHERE department_id = p_department_id;

            IF v_dept_mgr_id IS NOT NULL AND v_dept_mgr_id != p_employee_id THEN
                UPDATE employee
                SET manager_id = v_dept_mgr_id
                WHERE employee_id = p_employee_id;
                DBMS_OUTPUT.PUT_LINE('âœ… Manager updated to ' || v_dept_mgr_id);
            ELSE
                UPDATE employee
                SET manager_id = NULL
                WHERE employee_id = p_employee_id;
                DBMS_OUTPUT.PUT_LINE('No valid manager assigned.');
            END IF;
        END;

        -- If employee is a manager of previous dept, remove them
        UPDATE department
        SET manager_id = NULL
        WHERE manager_id = p_employee_id AND department_id = v_old_dept;

        -- Remove manager_id from all employees who reported to this manager
        UPDATE employee
        SET manager_id = NULL
        WHERE manager_id = p_employee_id AND department_id = v_old_dept;
    END IF;

    -- Final check: if this employee is a manager of any department,
    -- ensure they do not have a manager themselves
    SELECT COUNT(*) INTO v_is_manager
    FROM department
    WHERE manager_id = p_employee_id;

    IF v_is_manager > 0 THEN
        UPDATE employee
        SET manager_id = NULL
        WHERE employee_id = p_employee_id;
        DBMS_OUTPUT.PUT_LINE('Removed self manager assignment since employee is a department manager.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ No such employee exists.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ error: ' || SQLERRM);
END;

PROCEDURE add_department (
    p_department_name IN VARCHAR2,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
) IS
    ln_dept_id   NUMBER := department_seq.NEXTVAL;
    v_exists     NUMBER := 0;
BEGIN
    -- Check if department with same name and city_id already exists
    SELECT COUNT(*)
    INTO v_exists
    FROM department
    WHERE UPPER(department_name) = UPPER(p_department_name)
      AND city_id = p_city_id;

    IF v_exists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ Department "' || p_department_name || '" already exists in city ID ' || p_city_id || '.');
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
        p_department_name,
        p_manager_id,
        p_city_id
    );

    DBMS_OUTPUT.PUT_LINE('âœ… Inserted into department:');
    DBMS_OUTPUT.PUT_LINE('  ID = ' || ln_dept_id);
    DBMS_OUTPUT.PUT_LINE('  Name = ' || p_department_name);
    DBMS_OUTPUT.PUT_LINE('  Manager ID = ' || NVL(TO_CHAR(p_manager_id), 'Manager is not assigned yet'));
    DBMS_OUTPUT.PUT_LINE('  City ID = ' || NVL(TO_CHAR(p_city_id), 'NULL'));
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ Unexpected error during department insertion: ' || SQLERRM);
END;


 PROCEDURE update_department (
    p_department_id   IN NUMBER,
    p_department_name IN VARCHAR2 DEFAULT NULL,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
) IS
    v_new_name   VARCHAR2(100);
    v_new_city   NUMBER;
    v_count      NUMBER;
BEGIN
    -- Step 1: Fetch current values if not provided
    SELECT department_name, city_id
    INTO v_new_name, v_new_city
    FROM department
    WHERE department_id = p_department_id;

    -- Override only if parameters are provided
    IF p_department_name IS NOT NULL THEN
        v_new_name := p_department_name;
    END IF;

    IF p_city_id IS NOT NULL THEN
        v_new_city := p_city_id;
    END IF;

    -- Step 2: Check uniqueness for (name, city) combination
    SELECT COUNT(*)
    INTO v_count
    FROM department
    WHERE UPPER(department_name) = UPPER(v_new_name)
      AND city_id = v_new_city
      AND department_id != p_department_id;

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ Department name "' || v_new_name || '" already exists in city ID ' || v_new_city || '.');
        RETURN;
    END IF;

    -- Step 3: Update department_name and/or city_id
    IF p_department_name IS NOT NULL OR p_city_id IS NOT NULL THEN
        UPDATE department
        SET department_name = v_new_name,
            city_id = v_new_city
        WHERE department_id = p_department_id;

        DBMS_OUTPUT.PUT_LINE('âœ… Updated department name/city to "' || v_new_name || '", City ID: ' || v_new_city || ' for department_id = ' || p_department_id);
    END IF;

    -- Step 4: Update manager_id if given
    IF p_manager_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_count
        FROM employee
        WHERE employee_id = p_manager_id
          AND department_id = p_department_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'â?Œ Manager must belong to the same department.');
        END IF;

        -- Assign manager to department
        UPDATE department
        SET manager_id = p_manager_id
        WHERE department_id = p_department_id;

        -- Set manager_id to all employees (except manager himself)
        UPDATE employee
        SET manager_id = p_manager_id
        WHERE department_id = p_department_id
          AND employee_id != p_manager_id;

        -- Ensure manager himself has NULL as manager
        UPDATE employee
        SET manager_id = NULL
        WHERE employee_id = p_manager_id;

        DBMS_OUTPUT.PUT_LINE('âœ… Updated manager_id to ' || p_manager_id || ' for department_id = ' || p_department_id);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ Department with ID ' || p_department_id || ' not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('â?Œ Unexpected error: ' || SQLERRM);
END;


PROCEDURE apply_leave (
    p_employee_id IN NUMBER,
    p_leave_type  IN VARCHAR2,
    p_start_date  IN DATE,
    p_end_date    IN DATE
) AS
ln_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO ln_exists
    FROM employee
    WHERE employee_id = p_employee_id;

    IF ln_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Employee does not exist with employee_id '||p_employee_id);
    END IF;
    
    IF LOWER(p_leave_type) NOT IN ('sick', 'casual', 'annual', 'maternity', 'paternity', 'unpaid') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Invalid leave type.Please check the leave type');
    END IF;


    INSERT INTO employee_leaves (
        employee_id, leaves_type, start_date, end_date, status, approved_by
    ) VALUES (
        p_employee_id, p_leave_type, p_start_date, p_end_date, 'Pending', NULL
    );

    DBMS_OUTPUT.PUT_LINE('Leave request submitted successfully for employee_id'||P_employee_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

PROCEDURE process_leave (
    p_employee_id IN NUMBER,
    p_start_date  IN DATE,
    p_approved_by IN NUMBER DEFAULT NULL,
    p_action      IN VARCHAR2  -- 'APPROVE' or 'REJECT'
) AS
    Ln_days        NUMBER := 0;
    Ln_balance     NUMBER;
    Ld_date        DATE;
    Ld_end_date    DATE;
    lv2_status     VARCHAR2(20);
    ln_managerid  NUMBER;

BEGIN
    -- Get the end_date for this leave request
    SELECT status,end_date INTO Ld_end_date,lv2_status
    FROM employee_leaves
    WHERE employee_id = p_employee_id AND start_date = p_start_date;

    IF LOWER(lv2_status) != 'pending' THEN
        RAISE_APPLICATION_ERROR(-20007, 'Leave already processed.');
    END IF;
    SELECT manager_id INTO ln_managerid
    FROM employee
    WHERE employee_id = p_employee_id;

    IF ln_managerid IS NULL THEN
        RAISE_APPLICATION_ERROR(-20008, 'Employee has no assigned manager.');
    END IF;

    IF ln_managerid != p_approved_by THEN
        RAISE_APPLICATION_ERROR(-20009, 'Only the assigned manager can approve/reject this leave.');
    END IF;

    -- Count only weekdays between start_date and end_date
    Ld_date := p_start_date;
    WHILE Ld_date <= Ld_end_date LOOP
        -- Exclude Saturday (7) and Sunday (1)
        IF TO_CHAR(Ld_date, 'D') NOT IN ('1','7') THEN
            Ln_days := Ln_days + 1;
        END IF;
        Ld_date := Ld_date + 1;
    END LOOP;

    IF UPPER(p_action) = 'APPROVE' THEN
        -- Check leave balance
        SELECT Leaves_Balance INTO Ln_balance
        FROM employee
        WHERE employee_id = p_employee_id;

        IF Ln_days > Ln_balance THEN
            RAISE_APPLICATION_ERROR(-20003, 'Not enough leave balance.');
        END IF;

        -- Update leave status to Approved and record approver
        UPDATE employee_leaves
        SET status = 'Approved',
            approved_by = p_approved_by
        WHERE employee_id = p_employee_id AND start_date = p_start_date;

        -- Deduct leave days from total balance
        UPDATE employee
        SET Leaves_Balance = Leaves_Balance - Ln_days
        WHERE employee_id = p_employee_id;

        DBMS_OUTPUT.PUT_LINE('Leave approved for  '||P_Employee_id||' and ' || Ln_days || ' working days deducted.');

    ELSIF UPPER(p_action) = 'REJECT' THEN
        -- Just update status to Rejected
        UPDATE employee_leaves
        SET status = 'Rejected',
            approved_by = p_approved_by
        WHERE employee_id = p_employee_id AND start_date = p_start_date;

        DBMS_OUTPUT.PUT_LINE('Leave rejected for '||P_employee_id);

    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Invalid action. Use APPROVE or REJECT.');
    END IF;
END;

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




CREATE OR REPLACE TRIGGER trg_validate_leave
BEFORE INSERT OR UPDATE ON employee_leaves
FOR EACH ROW
DECLARE
    ln_count   NUMBER;
    lv_gender VARCHAR2(1);
BEGIN
    -- 1. Start date must be before or same as end date
    IF :NEW.start_date > :NEW.end_date THEN
        RAISE_APPLICATION_ERROR(-20001, 'Start date must be before or equal to end date.');
    END IF;

    --  2. Overlap check should run only when:
    --    a) INSERTING a new leave
    --    b) UPDATING start_date or end_date
    IF (:NEW.start_date != :OLD.start_date OR
        :NEW.end_date   != :OLD.end_date OR
        INSERTING) THEN

        -- 3. Check if there is any overlapping leave for same employee
        SELECT COUNT(*) INTO ln_count
        FROM employee_leaves
        WHERE employee_id = :NEW.employee_id
          AND status IN ('Pending', 'Approved')
          AND (
              (:NEW.start_date BETWEEN start_date AND end_date)
              OR (:NEW.end_date BETWEEN start_date AND end_date)
              OR (start_date BETWEEN :NEW.start_date AND :NEW.end_date)
              OR (end_date BETWEEN :NEW.start_date AND :NEW.end_date)
          );

        -- 4. If overlapping leave found, raise error
        IF ln_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
        END IF;
        -- 5. Gender-Based Business Rule: Maternity Leave for Female Only
        IF LOWER(:NEW.leaves_type) = 'maternity' THEN
            SELECT gender INTO lv_gender
            FROM employee
            WHERE employee_id = :NEW.employee_id;
    
            IF lv_gender != 'F' THEN
                RAISE_APPLICATION_ERROR(-20013, 'Maternity leave is only applicable for female employees.');
            END IF;
        END IF;

    -- 6. Gender-Based Business Rule: Paternity Leave for Male Only
    IF LOWER(:NEW.leaves_type) = 'paternity' THEN
        SELECT gender INTO lv_gender
        FROM employee
        WHERE employee_id = :NEW.employee_id;

        IF lv_gender != 'M' THEN
            RAISE_APPLICATION_ERROR(-20014, 'Paternity leave is only applicable for male employees.');
        END IF;
    END IF;


    END IF;
END;


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