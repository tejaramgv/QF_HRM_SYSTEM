


CREATE OR REPLACE PACKAGE BODY master_data_validator AS
    FUNCTION is_valid(p_value VARCHAR2, p_type VARCHAR2) RETURN BOOLEAN IS
        ln_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO ln_cnt
        FROM master_data
        WHERE LOWER(masterdata_value) = LOWER(p_value)
          AND masterdata_type = p_type;

        RETURN ln_cnt > 0;
    END is_valid;
    
    FUNCTION is_valid(p_id NUMBER, p_type VARCHAR2) RETURN BOOLEAN IS
        ln_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO ln_cnt
        FROM master_data
        WHERE masterdata_id = p_id
          AND masterdata_type = p_type;

        RETURN ln_cnt > 0;
    END is_valid;
END master_data_validator;
/



CREATE OR REPLACE TRIGGER trg_validate_candidates_master_data
BEFORE INSERT OR UPDATE ON candidates
FOR EACH ROW
BEGIN
    IF :NEW.highest_degree IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.highest_degree, 'DEGREE') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid DEGREE.');
    END IF;

    IF :NEW.id_proof_type IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.id_proof_type, 'ID_PROOF_TYPE') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Invalid ID_PROOF_TYPE.');
    END IF;
    
    IF :NEW.country_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.country_id, 'ID_PROOF_TYPE') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Invalid Country Id');
    END IF;
    
    IF :NEW.city_id IS NOT NULL AND NOT master_data_validator.is_valid(:NEW.city_id, 'ID_PROOF_TYPE') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Invalid City Id');
    END IF;
END;

/

