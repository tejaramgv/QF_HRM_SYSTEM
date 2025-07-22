CREATE OR REPLACE PACKAGE master_data_validator AS
    FUNCTION is_valid(p_id NUMBER, p_type VARCHAR2) RETURN BOOLEAN;
END master_data_validator;
/

CREATE OR REPLACE PACKAGE BODY master_data_validator AS
    FUNCTION is_valid(p_id NUMBER, p_type VARCHAR2) RETURN BOOLEAN IS
        v_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cnt
        FROM master_data
        WHERE masterdata_id = p_id
          AND masterdata_type = p_type;

        RETURN v_cnt > 0;
    END is_valid;
END master_data_validator;
/

CREATE OR REPLACE TRIGGER trg_validate_candidates_master_data
BEFORE INSERT OR UPDATE ON candidates
FOR EACH ROW
BEGIN
    IF :NEW.city_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.city_id, 'CITY') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid CITY ID.');
    END IF;

    IF :NEW.country_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.country_id, 'COUNTRY') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid COUNTRY ID.');
    END IF;

    IF :NEW.highest_degree IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.highest_degree, 'DEGREE') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid DEGREE.');
    END IF;

    IF :NEW.id_proof_type IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.id_proof_type, 'ID_PROOF_TYPE') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Invalid ID_PROOF_TYPE.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validate_employees_master_data
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    IF :NEW.department_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.department_id, 'DEPARTMENT') THEN
        RAISE_APPLICATION_ERROR(-20005, 'Invalid DEPARTMENT ID.');
    END IF;

    IF :NEW.band_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.band_id, 'BAND') THEN
        RAISE_APPLICATION_ERROR(-20006, 'Invalid BAND ID.');
    END IF;

    IF :NEW.exit_reason_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.exit_reason_id, 'EXIT_REASON') THEN
        RAISE_APPLICATION_ERROR(-20007, 'Invalid EXIT_REASON ID.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validate_performance_master_data
BEFORE INSERT OR UPDATE ON performance_reviews
FOR EACH ROW
BEGIN
    IF :NEW.rating IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.rating, 'PERFORMANCE_RATING') THEN
        RAISE_APPLICATION_ERROR(-20008, 'Invalid PERFORMANCE_RATING ID.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validate_baseline_salary_master_data
BEFORE INSERT OR UPDATE ON baseline_salary
FOR EACH ROW
BEGIN
    IF :NEW.skill IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.skill, 'SKILL') THEN
        RAISE_APPLICATION_ERROR(-20009, 'Invalid SKILL ID.');
    END IF;

    IF :NEW.band IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.band, 'BAND') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Invalid BAND ID in baseline salary.');
    END IF;
END;
/