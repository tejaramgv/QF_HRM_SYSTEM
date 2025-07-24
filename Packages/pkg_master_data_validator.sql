CREATE OR REPLACE PACKAGE master_data_validator AS
    FUNCTION is_valid(p_value VARCHAR2, p_type VARCHAR2) RETURN BOOLEAN;
    FUNCTION is_valid(p_id NUMBER, p_type VARCHAR2) RETURN BOOLEAN;

    -- New functions to fetch canonical values
    FUNCTION get_value(p_value VARCHAR2, p_type VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_id(p_value VARCHAR2, p_type VARCHAR2) RETURN NUMBER;
END master_data_validator;
/

CREATE OR REPLACE PACKAGE BODY master_data_validator AS
    FUNCTION is_valid(p_value VARCHAR2, p_type VARCHAR2) RETURN BOOLEAN IS
        ln_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO ln_cnt
        FROM master_data
        WHERE LOWER(masterdata_value) = LOWER(p_value)
          AND masterdata_type = p_type;

        RETURN ln_cnt > 0;
    END;

    FUNCTION is_valid(p_id NUMBER, p_type VARCHAR2) RETURN BOOLEAN IS
        ln_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO ln_cnt
        FROM master_data
        WHERE masterdata_id = p_id
          AND masterdata_type = p_type;

        RETURN ln_cnt > 0;
    END;

    FUNCTION get_value(p_value VARCHAR2, p_type VARCHAR2) RETURN VARCHAR2 IS
        v_value VARCHAR2(255);
    BEGIN
        SELECT masterdata_value INTO v_value
        FROM master_data
        WHERE LOWER(masterdata_value) = LOWER(p_value)
          AND masterdata_type = p_type
          AND ROWNUM = 1;

        RETURN v_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    FUNCTION get_id(p_value VARCHAR2, p_type VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT masterdata_id INTO v_id
        FROM master_data
        WHERE LOWER(masterdata_value) = LOWER(p_value)
          AND masterdata_type = p_type
          AND ROWNUM = 1;

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

END master_data_validator;
/


--CREATE OR REPLACE TRIGGER trg_validate_dept_city_master_data
--BEFORE INSERT OR UPDATE ON department
--FOR EACH ROW
--BEGIN
--    -- Validate department_name against master_data (type = 'DEPARTMENT')
--    IF :NEW.department_name IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.department_name, 'DEPARTMENT') THEN
--        RAISE_APPLICATION_ERROR(-20012, 'Invalid DEPARTMENT name.');
--    END IF;
--
--    -- Validate city_id against master_data (type = 'CITY')
--    IF :NEW.city_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.city_id, 'CITY') THEN
--        RAISE_APPLICATION_ERROR(-20013, 'Invalid CITY ID.');
--    END IF;
--    
--END;
--/
CREATE OR REPLACE TRIGGER trg_validate_dept_city_master_data
BEFORE INSERT OR UPDATE ON department
FOR EACH ROW
BEGIN
    -- Validate and standardize department_name
    IF :NEW.department_name IS NOT NULL THEN
        IF NOT master_data_validator.is_valid(:NEW.department_name, 'DEPARTMENT') THEN
            RAISE_APPLICATION_ERROR(-20012, 'Invalid DEPARTMENT name.');
        ELSE
            :NEW.department_name := master_data_validator.get_value(:NEW.department_name, 'DEPARTMENT');
        END IF;
    END IF;

    -- Validate city_id
    IF :NEW.city_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.city_id, 'CITY') THEN
        RAISE_APPLICATION_ERROR(-20013, 'Invalid CITY ID.');
    END IF;

END;
/


CREATE OR REPLACE TRIGGER trg_validate_baseline_salary_master_data
BEFORE INSERT OR UPDATE ON baseline_salary
FOR EACH ROW
BEGIN
    -- Validate BAND from master_data
    IF :NEW.band IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.band, 'BAND') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Invalid BAND.');
    END IF;

    -- Validate SKILL from master_data (only if skill is not null)
    IF :NEW.skill IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.skill, 'SKILL') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Invalid SKILL.');
    END IF;
    
    -- Validate JOB_TITLE
    IF :NEW.job_title IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.job_title, 'JOB_TITLE') THEN
        RAISE_APPLICATION_ERROR(-20012, 'Invalid JOB TITLE.');
    END IF;

END;
/


CREATE OR REPLACE TRIGGER trg_check_job_title
BEFORE INSERT OR UPDATE ON candidates
FOR EACH ROW
DECLARE
    v_job_title master_data.masterdata_value%TYPE;
BEGIN
    -- Look up the exact job title from master_data (case-insensitive match)
    SELECT masterdata_value
    INTO v_job_title
    FROM master_data
    WHERE masterdata_type = 'JOB_TITLE'
      AND UPPER(masterdata_value) = UPPER(:NEW.role);

    -- Standardize inserted value
    :NEW.role := v_job_title;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20014, 'Invalid job title. It must exist in master_data.');
END;
/

