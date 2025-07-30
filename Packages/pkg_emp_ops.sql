CREATE SEQUENCE department_seq
START WITH 10
INCREMENT BY 1
NOCACHE;

CREATE SEQUENCE seq_attendance_id
START WITH 1
INCREMENT BY 1
NOCACHE;


CREATE OR REPLACE PACKAGE pkg_emp_ops AS
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

    PROCEDURE add_department (
        p_department_name IN VARCHAR2,
        p_manager_id      IN NUMBER DEFAULT NULL,
        p_city_id         IN NUMBER DEFAULT NULL
    ) IS
    ln_dept_id NUMBER:=department_seq.NEXTVAL;
    BEGIN
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

        DBMS_OUTPUT.PUT_LINE('Inserted into department:');
        DBMS_OUTPUT.PUT_LINE('  ID = ' || ln_dept_id);
        DBMS_OUTPUT.PUT_LINE('  Name = ' || p_department_name);
        DBMS_OUTPUT.PUT_LINE('  Manager ID = ' || NVL(TO_CHAR(p_manager_id), 'Manager is not assigned yet'));
        DBMS_OUTPUT.PUT_LINE('  City ID = ' || NVL(TO_CHAR(p_city_id), 'NULL'));
        
    END;

  PROCEDURE update_department (
    p_department_id   IN NUMBER,
    p_department_name IN VARCHAR2 DEFAULT NULL,
    p_manager_id      IN NUMBER DEFAULT NULL,
    p_city_id         IN NUMBER DEFAULT NULL
) IS
BEGIN
    -- Update department name
    IF p_department_name IS NOT NULL THEN
        UPDATE department
        SET department_name = p_department_name
        WHERE department_id = p_department_id;

        DBMS_OUTPUT.PUT_LINE('✅ Updated department_name to "' || p_department_name || '" for department_id = ' || p_department_id);
    END IF;

    -- Update manager_id and propagate to employees
    IF p_manager_id IS NOT NULL THEN
        UPDATE department
        SET manager_id = p_manager_id
        WHERE department_id = p_department_id;

        DBMS_OUTPUT.PUT_LINE('Updated manager_id to ' || p_manager_id || ' for department_id = ' || p_department_id);

        -- Propagate to all employees in that department (except the manager himself)
        UPDATE employee
        SET manager_id = p_manager_id
        WHERE department_id = p_department_id
          AND employee_id != p_manager_id;
       UPDATE employee
       SET manager_id=NULL
       WHERE employee_id=p_manager_id;
        DBMS_OUTPUT.PUT_LINE('✅ Assigned new manager_id ' || p_manager_id || ' to all employees of department ' || p_department_id);
    
    END IF;

    -- Update city_id
    IF p_city_id IS NOT NULL THEN
        UPDATE department
        SET city_id = p_city_id
        WHERE department_id = p_department_id;

        DBMS_OUTPUT.PUT_LINE('Updated city_id to ' || p_city_id || ' for department_id = ' || p_department_id);
    END IF;
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