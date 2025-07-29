CREATE SEQUENCE department_seq
START WITH 10
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
        
       IF p_manager_id IS NOT NULL THEN
               UPDATE employee
        SET manager_id = p_manager_id
        WHERE department_id = p_department_id
          AND employee_id != p_manager_id;
       UPDATE employee
       SET manager_id=NULL
       WHERE employee_id=p_manager_id;
        DBMS_OUTPUT.PUT_LINE('✅ Assigned new manager_id ' || p_manager_id || ' to all employees of department ' || p_department_id);
    END IF;
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
BEGIN
    INSERT INTO employee_leaves (
        employee_id, leaves_type, start_date, end_date, status, approved_by
    ) VALUES (
        p_employee_id, p_leave_type, p_start_date, p_end_date, 'Pending', NULL
    );

    DBMS_OUTPUT.PUT_LINE('Leave request submitted successfully.');
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
BEGIN
    -- Get the end_date for this leave request
    SELECT end_date INTO Ld_end_date
    FROM employee_leaves
    WHERE employee_id = p_employee_id AND start_date = p_start_date;

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

        DBMS_OUTPUT.PUT_LINE('Leave approved. ' || Ln_days || ' working days deducted.');

    ELSIF UPPER(p_action) = 'REJECT' THEN
        -- Just update status to Rejected
        UPDATE employee_leaves
        SET status = 'Rejected',
            approved_by = p_approved_by
        WHERE employee_id = p_employee_id AND start_date = p_start_date;

        DBMS_OUTPUT.PUT_LINE('Leave rejected.');

    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Invalid action. Use APPROVE or REJECT.');
    END IF;
END;

END pkg_emp_ops;
/



CREATE OR REPLACE TRIGGER trg_validate_leave
BEFORE INSERT OR UPDATE ON employee_leaves
FOR EACH ROW
DECLARE
    v_count NUMBER;
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
        SELECT COUNT(*) INTO v_count
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
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Leave dates overlap with existing approved or pending leave.');
        END IF;

    END IF;
END;
