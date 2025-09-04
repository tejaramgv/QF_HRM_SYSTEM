CREATE SEQUENCE perf_eval_seq
START WITH 5000
INCREMENT BY 1
NOCACHE;


CREATE OR REPLACE PACKAGE pkg_perform_mngmt AS
 PROCEDURE add_or_update_performance (
    p_employee_id     IN NUMBER,
    p_quarter         IN VARCHAR2,
    p_year            IN NUMBER,
    p_rating_value    IN VARCHAR2, -- '1','2','3','4','5'
    p_eval_type       IN VARCHAR2, -- 'Provisional' or 'Final'
    p_evaluator_id    IN NUMBER,
    p_remarks         IN VARCHAR2 DEFAULT NULL
) ;

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
    p_new_salary  IN NUMBER DEFAULT NULL
);

END;
/


CREATE OR REPLACE PACKAGE BODY pkg_perform_mngmt AS


 PROCEDURE add_or_update_performance (
    p_employee_id     IN NUMBER,
    p_quarter         IN VARCHAR2,
    p_year            IN NUMBER,
    p_rating_value    IN VARCHAR2, -- '1','2','3','4','5'
    p_eval_type       IN VARCHAR2, -- 'Provisional' or 'Final'
    p_evaluator_id    IN NUMBER,
    p_remarks         IN VARCHAR2 DEFAULT NULL
) IS
    v_rating_id       master_data.masterdata_id%TYPE;
    v_exists_type     VARCHAR2(20);
    v_dummy           NUMBER;
    v_old_rating_id   NUMBER;
    v_old_eval_type   VARCHAR2(20);
    v_old_remarks     VARCHAR2(200);
    v_cur_year        NUMBER;
    v_cur_quarter_num NUMBER;
    v_in_quarter_num  NUMBER;
    v_manager_id      NUMBER;
BEGIN
    -- ✅ Validate employee exists
    BEGIN
        SELECT 1 INTO v_dummy
        FROM employee
        WHERE employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(' Employee ID ' || p_employee_id || ' not found.');
            RETURN;
    END;

    -- ✅ Validate evaluator is employee's manager
    BEGIN
        SELECT manager_id INTO v_manager_id
        FROM employee
        WHERE employee_id = p_employee_id;

        IF v_manager_id IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(' Employee ' || p_employee_id || ' has no manager assigned. Cannot evaluate.');
            RETURN;
        ELSIF v_manager_id != p_evaluator_id THEN
            DBMS_OUTPUT.PUT_LINE(' Only the assigned manager (ID ' || v_manager_id || ') can evaluate this employee.');
            RETURN;
        END IF;
    END;

    -- ✅ Validate rating exists
    BEGIN
        SELECT masterdata_id INTO v_rating_id
        FROM master_data
        WHERE masterdata_type = 'PERFORMANCE_RATING'
          AND masterdata_value = TO_CHAR(p_rating_value);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(' Invalid performance rating "' || p_rating_value || '". Must be 1–5.');
            RETURN;
    END;

    -- ✅ Check no future quarter/year entry
    v_cur_year := EXTRACT(YEAR FROM SYSDATE);
    v_cur_quarter_num := CEIL(EXTRACT(MONTH FROM SYSDATE) / 3);

    v_in_quarter_num := CASE UPPER(p_quarter)
                           WHEN 'Q1' THEN 1
                           WHEN 'Q2' THEN 2
                           WHEN 'Q3' THEN 3
                           WHEN 'Q4' THEN 4
                           ELSE NULL
                        END;

    IF v_in_quarter_num IS NULL THEN
        DBMS_OUTPUT.PUT_LINE(' Invalid quarter: ' || p_quarter);
        RETURN;
    END IF;

    IF (p_year > v_cur_year) OR (p_year = v_cur_year AND v_in_quarter_num > v_cur_quarter_num) THEN
        DBMS_OUTPUT.PUT_LINE(' Cannot insert performance for future quarter (' || p_quarter || '-' || p_year || ').');
        RETURN;
    END IF;

    -- ✅ Check if record exists for employee-quarter-year
    BEGIN
        SELECT rating_id, evaluation_type, remarks
        INTO v_old_rating_id, v_old_eval_type, v_old_remarks
        FROM performance_evaluation
        WHERE employee_id = p_employee_id
          AND quarter = UPPER(p_quarter)
          AND year = p_year;

        IF v_old_eval_type = 'Final' THEN
            DBMS_OUTPUT.PUT_LINE('Cannot update: Final rating already exists for ' || p_quarter || '-' || p_year);
            RETURN;
        ELSE
            UPDATE performance_evaluation
            SET rating_id       = v_rating_id,
                evaluation_type = INITCAP(p_eval_type),
                evaluator_id    = p_evaluator_id,
                remarks         = INITCAP(p_remarks),
                last_updated    = SYSDATE
            WHERE employee_id = p_employee_id
              AND quarter = UPPER(p_quarter)
              AND year = p_year;

            DBMS_OUTPUT.PUT_LINE('🔄 Performance updated for Employee ID ' || p_employee_id || ' in ' || p_quarter || '-' || p_year);

            IF v_old_rating_id != v_rating_id THEN
                DBMS_OUTPUT.PUT_LINE('   Rating changed.');
            END IF;
            IF v_old_eval_type != INITCAP(p_eval_type) THEN
                DBMS_OUTPUT.PUT_LINE('   Evaluation Type: ' || v_old_eval_type || ' → ' || INITCAP(p_eval_type));
            END IF;
            IF NVL(v_old_remarks,'') != NVL(INITCAP(p_remarks),'') THEN
                DBMS_OUTPUT.PUT_LINE('   Remarks updated: "' || NVL(v_old_remarks,'-') || '" → "' || NVL(p_remarks,'-') || '"');
            END IF;
            RETURN;
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO performance_evaluation (
                eval_id, employee_id, quarter, year, rating_id, evaluation_type,
                evaluator_id, remarks, created_date, last_updated
            ) VALUES (
                perf_eval_seq.NEXTVAL, p_employee_id, UPPER(p_quarter), p_year,
                v_rating_id, INITCAP(p_eval_type), p_evaluator_id,
                INITCAP(p_remarks), SYSDATE, SYSDATE
            );

            DBMS_OUTPUT.PUT_LINE('✅ New performance record added for Employee ID ' || p_employee_id ||
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
    p_quarter          IN VARCHAR2 DEFAULT NULL,
    p_rating_value      IN VARCHAR2 DEFAULT NULL, 
    p_rating_desc       IN VARCHAR2 DEFAULT NULL   
) IS
 v_found BOOLEAN := FALSE;
BEGIN
    -- Header
    DBMS_OUTPUT.PUT_LINE('=============================================================================================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('Employee', 25) || RPAD('Quarter-Year', 15) || RPAD('Rating', 10) || RPAD('Description', 15) ||
                         RPAD('Type', 15) || RPAD('Evaluator', 25) || RPAD('Updated On', 15) || 'Remarks');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------------------------------------------------------------------');

    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               p.quarter,
               p.year,
               r.masterdata_value AS rating,       
               d.masterdata_value AS rating_desc,   
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
          AND (p_quarter IS NULL OR LOWER(p.quarter) = LOWER(search_performance.p_quarter))
          AND (p_rating_value IS NULL OR r.masterdata_value = p_rating_value)
          AND (p_rating_desc IS NULL OR UPPER(d.masterdata_value) LIKE '%' || UPPER(p_rating_desc) || '%')
        ORDER BY p.year, p.quarter
    ) LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) ||
                             RPAD(rec.quarter || '-' || rec.year, 15) ||
                             RPAD(rec.rating, 10) ||
                             RPAD(NVL(rec.rating_desc,'-'), 15) ||
                             RPAD(rec.evaluation_type, 15) ||
                             RPAD(NVL(rec.evaluator_name,'N/A'), 25) ||
                             RPAD(rec.updated_on, 15) ||
                             NVL(rec.remarks,'None'));
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE(' No performance records found for given filters.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('================================================================================================================================================');
END;



 PROCEDURE salary_analysis IS
    v_count NUMBER := 0;
BEGIN
    -- Header
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('Employee', 25) || RPAD('Salary', 15) || RPAD('Max Salary', 15) || 'Percent of Max');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------');

    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               e.salary, b.max_salary,
               ROUND((e.salary / b.max_salary) * 100, 2) AS salary_percent
        FROM employee e
        JOIN candidates c ON c.candidate_id = e.candidate_id
        JOIN baseline_salary b ON e.band_id = b.band_id
        WHERE e.salary >= (0.8 * b.max_salary)
    ) LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) ||
                             RPAD(TO_CHAR(rec.salary), 15) ||
                             RPAD(TO_CHAR(rec.max_salary), 15) ||
                             rec.salary_percent || '%');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=====================================================================');
    DBMS_OUTPUT.PUT_LINE('Total Employees (>=80% of band max): ' || v_count);
    DBMS_OUTPUT.PUT_LINE('=====================================================================');
END;




 PROCEDURE promotion_recommendation IS
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===========================================================================================');
    DBMS_OUTPUT.PUT_LINE(RPAD('Employee Name', 25) || RPAD('Current Band', 15) || RPAD('Eligible For', 20) || RPAD('Next Band', 15) || 'Salary Range');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------------');

    -- Rule 1: 3 consecutive top ratings
    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               b.band AS current_band,
               b.job_title,
               b.band_id
        FROM employee e
        JOIN candidates c ON c.candidate_id = e.candidate_id
        JOIN baseline_salary b ON e.band_id = b.band_id
        WHERE EXISTS (
            SELECT 1
            FROM (
                SELECT p.employee_id,
                       LISTAGG(md.masterdata_value, ',') WITHIN GROUP (ORDER BY p.year DESC, p.quarter DESC) ratings
                FROM performance_evaluation p
                JOIN master_data md ON md.masterdata_id = p.rating_id
                WHERE md.masterdata_type = 'PERFORMANCE_RATING'
                GROUP BY p.employee_id
            ) t
            WHERE t.employee_id = e.employee_id
              AND REGEXP_LIKE(t.ratings, '^5,5,5')  -- three consecutive top ratings
        )
        AND (e.last_promotion_date IS NULL OR ADD_MONTHS(e.last_promotion_date, 12) <= SYSDATE) -- ✅ skip recent promotions
    ) LOOP
        v_count := v_count + 1;

        DECLARE
            v_next_band baseline_salary.band%TYPE;
            v_min_sal   NUMBER;
            v_max_sal   NUMBER;
        BEGIN
            SELECT band, min_salary, max_salary
            INTO v_next_band, v_min_sal, v_max_sal
            FROM baseline_salary
            WHERE job_title = rec.job_title
              AND min_exp > (SELECT min_exp FROM baseline_salary WHERE band_id = rec.band_id)
            ORDER BY min_exp
            FETCH FIRST 1 ROWS ONLY;

            DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) || RPAD(rec.current_band, 15) ||
                                 RPAD('Promotion', 20) || RPAD(v_next_band, 15) ||
                                 TO_CHAR(v_min_sal) || ' - ' || TO_CHAR(v_max_sal));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) || RPAD(rec.current_band, 15) ||
                                     RPAD('Top Band Reached', 20) || RPAD('-', 15) || '-');
        END;
    END LOOP;

    -- Rule 2: Experience band check
    FOR rec IN (
        SELECT e.employee_id,
               c.first_name || ' ' || c.last_name AS employee_name,
               b.band AS current_band,
               b.job_title,
               b.band_id,
               (c.years_of_experience + FLOOR(MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12)) AS total_exp,
               b.max_exp
        FROM employee e
        JOIN candidates c ON c.candidate_id = e.candidate_id
        JOIN baseline_salary b ON e.band_id = b.band_id
        WHERE (c.years_of_experience + FLOOR(MONTHS_BETWEEN(SYSDATE, e.date_of_joining)/12)) > b.max_exp
        AND (e.last_promotion_date IS NULL OR ADD_MONTHS(e.last_promotion_date, 12) <= SYSDATE) -- ✅ skip recent promotions
    ) LOOP
        v_count := v_count + 1;

        DECLARE
            v_next_band baseline_salary.band%TYPE;
            v_min_sal   NUMBER;
            v_max_sal   NUMBER;
        BEGIN
            SELECT band, min_salary, max_salary
            INTO v_next_band, v_min_sal, v_max_sal
            FROM baseline_salary
            WHERE job_title = rec.job_title
              AND min_exp > (SELECT min_exp FROM baseline_salary WHERE band_id = rec.band_id)
            ORDER BY min_exp
            FETCH FIRST 1 ROWS ONLY;

            DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) || RPAD(rec.current_band, 15) ||
                                 RPAD('Promotion', 20) || RPAD(v_next_band, 15) ||
                                 TO_CHAR(v_min_sal) || ' - ' || TO_CHAR(v_max_sal));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(RPAD(rec.employee_name, 25) || RPAD(rec.current_band, 15) ||
                                     RPAD('Top Band Reached', 20) || RPAD('-', 15) || '-');
        END;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('============================================================================================');
    DBMS_OUTPUT.PUT_LINE('Total Eligible Employees: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('============================================================================================');
END;


PROCEDURE promote_employee (
    p_employee_id IN NUMBER,
    p_new_salary  IN NUMBER DEFAULT NULL
) IS
    v_role          VARCHAR2(100);
    v_band          VARCHAR2(100);
    v_job_title     VARCHAR2(100);
    v_band_id       NUMBER;
    v_new_band_id   NUMBER;
    v_min_salary    NUMBER;
    v_max_salary    NUMBER;
    v_new_band      VARCHAR2(100);
    v_final_salary  NUMBER;
    v_emp_name      VARCHAR2(200);
BEGIN
    -- ✅ Validate employee exists and get current details
    BEGIN
        SELECT c.first_name || ' ' || c.last_name,
               b.job_title, b.band, e.band_id
        INTO v_emp_name, v_job_title, v_band, v_band_id
        FROM employee e
        JOIN baseline_salary b ON e.band_id = b.band_id
        JOIN candidates c ON c.candidate_id = e.candidate_id
        WHERE e.employee_id = p_employee_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(' Employee ID ' || p_employee_id || ' not found.');
            RETURN;
    END;

    -- ✅ Find next higher band for same role
    BEGIN
        SELECT band_id, min_salary, max_salary, band
        INTO v_new_band_id, v_min_salary, v_max_salary, v_new_band
        FROM baseline_salary
        WHERE job_title = v_job_title
          AND ((v_band = 'Junior' AND band = 'Mid')
            OR (v_band = 'Mid' AND band = 'Senior'))
        FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('️ Employee ' || v_emp_name || 
                                 ' is already at the highest band (' || v_band || ').');
            RETURN;
    END;

    -- ✅ Salary validation
    IF p_new_salary IS NULL THEN
        v_final_salary := v_min_salary; -- default to band min
    ELSIF p_new_salary < v_min_salary OR p_new_salary > v_max_salary THEN
        DBMS_OUTPUT.PUT_LINE('Invalid salary ' || p_new_salary ||
                             '. Must be between ' || v_min_salary ||
                             ' and ' || v_max_salary || 
                             ' for ' || v_new_band || ' band.');
        RETURN;
    ELSE
        v_final_salary := p_new_salary;
    END IF;

    -- ✅ Update employee
    UPDATE employee
    SET band_id = v_new_band_id,
        salary  = v_final_salary,
        last_promotion_date = SYSDATE
    WHERE employee_id = p_employee_id;

    DBMS_OUTPUT.PUT_LINE(' ' || v_emp_name || 
                         ' promoted from ' || v_band || ' → ' || v_new_band ||
                         ', salary set to ' || v_final_salary);

END;


END;
/


