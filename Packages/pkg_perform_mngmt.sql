CREATE SEQUENCE perf_eval_seq
START WITH 5000
INCREMENT BY 1
NOCACHE;


CREATE OR REPLACE PACKAGE pkg_perform_mngmt AS
 PROCEDURE add_or_update_performance (
    p_employee_id     IN NUMBER,
    p_quarter         IN VARCHAR2,
    p_year            IN NUMBER,
    p_rating_value    IN VARCHAR2,
    p_eval_type       IN VARCHAR2, 
    p_evaluator_id    IN NUMBER,
    p_remarks         IN VARCHAR2 DEFAULT NULL
);


 PROCEDURE search_performance (
    p_employee_id   IN NUMBER DEFAULT NULL,
    p_employee_name IN VARCHAR2 DEFAULT NULL,
    p_year          IN NUMBER DEFAULT NULL,
    p_quarter       IN VARCHAR2 DEFAULT NULL
);

END;
/


CREATE OR REPLACE PACKAGE BODY pkg_perform_mngmt AS


 PROCEDURE add_or_update_performance (
    p_employee_id     IN NUMBER,
    p_quarter        IN VARCHAR2,
    p_year            IN NUMBER,
    p_rating_value    IN VARCHAR2, 
    p_eval_type       IN VARCHAR2,
    p_evaluator_id    IN NUMBER,
    p_remarks         IN VARCHAR2 DEFAULT NULL
) IS
    v_rating_id     master_data.masterdata_id%TYPE;
    v_exists_type   VARCHAR2(20);
    v_dummy         NUMBER;
BEGIN
    -- ✅ Validate employee
    BEGIN
        SELECT 1 INTO v_dummy
        FROM employee
        WHERE employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('❌ Employee ID ' || p_employee_id || ' not found.');
            RETURN;
    END;

    -- ✅ Validate rating
    BEGIN
        SELECT masterdata_id INTO v_rating_id
        FROM master_data
        WHERE masterdata_type = 'PERFORMANCE_RATING'
          AND masterdata_value = to_char(p_rating_value);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('❌ Invalid performance rating "' || p_rating_value || '". Must be 1–5.');
            RETURN;
    END;

    -- ✅ Check if record already exists for quarter+year
    BEGIN
        SELECT evaluation_type INTO v_exists_type
        FROM performance_evaluation
        WHERE employee_id = p_employee_id
          AND quarter = p_quarter
          AND year = p_year;

        -- If already Final → block update
        IF v_exists_type = 'Final' THEN
            DBMS_OUTPUT.PUT_LINE('❌ Cannot update: Final rating already exists for ' || p_quarter || '-' || p_year);
            RETURN;
        ELSE
            -- Update Provisional
            UPDATE performance_evaluation
            SET rating_id       = v_rating_id,
                evaluation_type = INITCAP(p_eval_type),
                evaluator_id    = p_evaluator_id,
                remarks         = INITCAP(p_remarks),
                last_updated    = SYSDATE
            WHERE employee_id = p_employee_id
              AND quarter = UPPER(p_quarter)
              AND year = p_year;

            DBMS_OUTPUT.PUT_LINE('🔄 Updates done for employee ID ' || p_employee_id || 
                                 ' in ' || p_quarter || '-' || p_year);
            RETURN;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- No record exists → Insert new
            INSERT INTO performance_evaluation (
                eval_id, employee_id, quarter, year, rating_id, evaluation_type,
                evaluator_id, remarks, created_date, last_updated
            ) VALUES (
                perf_eval_seq.NEXTVAL, p_employee_id, UPPER(p_quarter), p_year, v_rating_id, INITCAP(p_eval_type),
                p_evaluator_id, INITCAP(p_remarks), SYSDATE, SYSDATE
            );

            DBMS_OUTPUT.PUT_LINE('✅ New performance record added for employee ID ' || p_employee_id || 
                                 ' in ' || p_quarter || '-' || p_year);
    END;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Unexpected error: ' || SQLERRM);
END;

END;
/