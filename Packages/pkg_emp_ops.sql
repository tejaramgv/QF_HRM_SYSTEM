CREATE OR REPLACE PACKAGE pkg_emp_ops AS
    PROCEDURE add_department (
        p_department_id   IN NUMBER,
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
END pkg_emp_ops;
/


CREATE OR REPLACE PACKAGE BODY pkg_emp_ops AS

    PROCEDURE add_department (
        p_department_id   IN NUMBER,
        p_department_name IN VARCHAR2,
        p_manager_id      IN NUMBER DEFAULT NULL,
        p_city_id         IN NUMBER DEFAULT NULL
    ) IS
    BEGIN
        INSERT INTO department (
            department_id,
            department_name,
            manager_id,
            city_id
        ) VALUES (
            p_department_id,
            p_department_name,
            p_manager_id,
            p_city_id
        );

        DBMS_OUTPUT.PUT_LINE('Inserted into department:');
        DBMS_OUTPUT.PUT_LINE('  ID = ' || p_department_id);
        DBMS_OUTPUT.PUT_LINE('  Name = ' || p_department_name);
        DBMS_OUTPUT.PUT_LINE('  Manager ID = ' || NVL(TO_CHAR(p_manager_id), 'NULL'));
        DBMS_OUTPUT.PUT_LINE('  City ID = ' || NVL(TO_CHAR(p_city_id), 'NULL'));
    END;

    PROCEDURE update_department (
        p_department_id   IN NUMBER,
        p_department_name IN VARCHAR2 DEFAULT NULL,
        p_manager_id      IN NUMBER DEFAULT NULL,
        p_city_id         IN NUMBER DEFAULT NULL
    ) IS
    BEGIN
        IF p_department_name IS NOT NULL THEN
            UPDATE department
            SET department_name = p_department_name
            WHERE department_id = p_department_id;

            DBMS_OUTPUT.PUT_LINE('Updated department_name to "' || p_department_name || '" for department_id = ' || p_department_id);
        END IF;

        IF p_manager_id IS NOT NULL THEN
            UPDATE department
            SET manager_id = p_manager_id
            WHERE department_id = p_department_id;

            DBMS_OUTPUT.PUT_LINE('Updated manager_id to ' || p_manager_id || ' for department_id = ' || p_department_id);
        END IF;

        IF p_city_id IS NOT NULL THEN
            UPDATE department
            SET city_id = p_city_id
            WHERE department_id = p_department_id;

            DBMS_OUTPUT.PUT_LINE('Updated city_id to ' || p_city_id || ' for department_id = ' || p_department_id);
        END IF;
    END;

END pkg_emp_ops;
/

