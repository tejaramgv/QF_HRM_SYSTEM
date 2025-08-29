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
    p_employee_id       IN NUMBER DEFAULT NULL,
    p_employee_name     IN VARCHAR2 DEFAULT NULL,
    p_year              IN NUMBER DEFAULT NULL,
    p_quarter           IN VARCHAR2 DEFAULT NULL,
    p_rating_value      IN VARCHAR2 DEFAULT NULL,
    p_rating_desc       IN VARCHAR2 DEFAULT NULL  
);
 PROCEDURE salary_analysis;
 PROCEDURE promotion_recommendation;
 
 PROCEDURE promote_employee (
    p_employee_id IN NUMBER,
    p_new_band_id IN NUMBER,
    p_new_salary  IN NUMBER,
    p_new_role    IN VARCHAR2 DEFAULT NULL
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
            DBMS_OUTPUT.PUT_LINE('Employee ID ' || p_employee_id || ' not found.');
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
            DBMS_OUTPUT.PUT_LINE('Invalid performance rating "' || p_rating_value || '". Must be 1–5.');
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
            DBMS_OUTPUT.PUT_LINE(' Cannot update: Final rating already exists for ' || p_quarter || '-' || p_year);
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

            DBMS_OUTPUT.PUT_LINE(' Updates done for employee ID ' || p_employee_id || 
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
        DBMS_OUTPUT.PUT_LINE(' Unexpected error: ' || SQLERRM);
END;


PROCEDURE search_performance (
    p_employee_id       IN NUMBER DEFAULT NULL,
    p_employee_name     IN VARCHAR2 DEFAULT NULL,
    p_year              IN NUMBER DEFAULT NULL,
    p_quarter           IN VARCHAR2 DEFAULT NULL,
    p_rating_value      IN VARCHAR2 DEFAULT NULL, 
    p_rating_desc       IN VARCHAR2 DEFAULT NULL   
) IS
 v_found BOOLEAN := FALSE;
BEGIN
    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               p.quarter,
               p.year,
               r.masterdata_value AS rating,        -- numeric rating
               d.masterdata_value AS rating_desc,   -- description
               p.evaluation_type,
               evc.first_name || ' ' || evc.last_name AS evaluator_name,
               p.remarks,
               TO_CHAR(p.last_updated, 'DD-MON-YYYY') AS updated_on
        FROM performance_evaluation p
        JOIN employee e ON e.employee_id = p.employee_id
        JOIN candidates c ON c.candidate_id = e.candidate_id
        JOIN master_data r ON r.masterdata_id = p.rating_id
        LEFT JOIN master_data d ON d.parent_id = r.masterdata_id
        LEFT JOIN employee ev ON ev.employee_id = p.evaluator_id
        LEFT JOIN candidates evc ON evc.candidate_id = ev.candidate_id
        WHERE (p_employee_id IS NULL OR e.employee_id = search_performance.p_employee_id)
          AND (p_employee_name IS NULL OR UPPER(c.first_name || ' ' || c.last_name) LIKE '%' || UPPER(p_employee_name) || '%')
          AND (p_year IS NULL OR p.year = search_performance.p_year)
          AND (p_quarter IS NULL OR p.quarter = search_performance.p_quarter)
          AND (p_rating_value IS NULL OR r.masterdata_value = p_rating_value)
          AND (p_rating_desc IS NULL OR UPPER(d.masterdata_value) LIKE '%' || UPPER(p_rating_desc) || '%')
        ORDER BY p.year, p.quarter
    ) LOOP
     v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(' Employee: ' || rec.employee_name);
        DBMS_OUTPUT.PUT_LINE('   Quarter: ' || rec.quarter || '-' || rec.year);
        DBMS_OUTPUT.PUT_LINE('   Rating: ' || rec.rating || ' - ' || rec.rating_desc);
        DBMS_OUTPUT.PUT_LINE('   Evaluation Type: ' || rec.evaluation_type);
        DBMS_OUTPUT.PUT_LINE('   Evaluated By: ' || NVL(rec.evaluator_name, 'N/A'));
        DBMS_OUTPUT.PUT_LINE('   Remarks: ' || NVL(rec.remarks, 'None'));
        DBMS_OUTPUT.PUT_LINE('   Last Updated: ' || rec.updated_on);
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
    END LOOP;
      IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE(' No performance records found for given filters.');
    END IF;
END;


PROCEDURE salary_analysis IS
v_count NUMBER:=0;
BEGIN
    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               e.salary, b.max_salary,
               ROUND((e.salary / b.max_salary) * 100, 2) AS salary_percent
        FROM employee e
        JOIN candidates c ON c.candidate_id = e.candidate_id   -- ✅ fetch name from candidates
        JOIN baseline_salary b ON e.band_id = b.band_id
        WHERE e.salary >= (0.8 * b.max_salary)
    ) LOOP
    v_count:=v_count+1;
        DBMS_OUTPUT.PUT_LINE(
            '️ Employee ' || rec.employee_name ||
            ' has reached ' || rec.salary_percent || '% of their band max salary (' ||
            rec.salary || '/' || rec.max_salary || ').'
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE( ' ('||v_count ||')'|| ' employees has reached 80% of their band max salary');
END;

 PROCEDURE promotion_recommendation IS
BEGIN
    -- Rule 1: 3 consecutive "1" ratings
    FOR rec IN (
       SELECT e.employee_id,
       c.first_name || ' ' || c.last_name AS employee_name
FROM employee e
JOIN candidates c ON c.candidate_id = e.candidate_id
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT p.employee_id,
               LISTAGG(md.masterdata_value, ',') WITHIN GROUP (ORDER BY p.year DESC, p.quarter DESC) AS ratings
        FROM performance_evaluation p
        JOIN master_data md ON md.masterdata_id = p.rating_id
        WHERE md.masterdata_type = 'PERFORMANCE_RATING'
        GROUP BY p.employee_id
    ) t
    WHERE t.employee_id = e.employee_id
      AND REGEXP_LIKE(t.ratings, '^5,5,5') -- three consecutive "1" ratings

        )
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.employee_name || ' eligible for promotion (3 consecutive top ratings).');
    END LOOP;

    -- Rule 2: Experience band check
    FOR rec IN (
      SELECT e.employee_id,
       c.first_name || ' ' || c.last_name AS employee_name,
       (c.years_of_experience + FLOOR(MONTHS_BETWEEN(SYSDATE, e.date_of_joining) / 12)) AS total_experience,
       b.max_exp
FROM employee e
JOIN candidates c ON c.candidate_id = e.candidate_id
JOIN baseline_salary b ON e.band_id = b.band_id
WHERE (c.years_of_experience + FLOOR(MONTHS_BETWEEN(SYSDATE, e.date_of_joining) / 12)) > b.max_exp

    ) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.employee_name || ' eligible for promotion (crossed experience band).');
    END LOOP;
END;

PROCEDURE promote_employee (
    p_employee_id IN NUMBER,
    p_new_band_id IN NUMBER,
    p_new_salary  IN NUMBER,
    p_new_role    IN VARCHAR2 DEFAULT NULL
) IS
    v_min_salary baseline_salary.min_salary%TYPE;
    v_max_salary baseline_salary.max_salary%TYPE;
BEGIN
    -- Validate salary against band
    SELECT min_salary, max_salary INTO v_min_salary, v_max_salary
    FROM baseline_salary
    WHERE band_id = p_new_band_id;

    IF p_new_salary < v_min_salary OR p_new_salary > v_max_salary THEN
        DBMS_OUTPUT.PUT_LINE('❌ Salary ' || p_new_salary || ' not valid for band ' || p_new_band_id);
        RETURN;
    END IF;

    -- Update
    UPDATE employee
    SET band_id = p_new_band_id,
        salary  = p_new_salary,
        role    = NVL(p_new_role, role)
    WHERE employee_id = p_employee_id;

    DBMS_OUTPUT.PUT_LINE('✅ Employee ' || p_employee_id || ' promoted with new band ' || p_new_band_id || ' and salary ' || p_new_salary);
END;


END;
/