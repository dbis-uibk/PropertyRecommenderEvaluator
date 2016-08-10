DELIMITER //
DROP PROCEDURE IF EXISTS insertTriple;
CREATE PROCEDURE insertTriple(IN pSub VARCHAR(700), IN pProp VARCHAR(700), IN pObj VARCHAR(10000) CHARACTER SET utf8mb4, IN pLang VARCHAR(255), IN pType VARCHAR(700))
  BEGIN
    DECLARE vLang_id INT DEFAULT NULL;
    DECLARE vProp_id INT DEFAULT NULL;
    DECLARE vObj_id INT DEFAULT NULL;
    DECLARE vSub_id INT DEFAULT NULL;
    DECLARE vType_id INT DEFAULT NULL;

    -- get lang id

    IF pLang IS NULL THEN
        SET vLang_id = NULL;
    ELSE
        SELECT lang_id INTO vLang_id FROM dict_lang WHERE lang_text = pLang;
        IF vLang_id IS NULL THEN 
        INSERT INTO dict_lang (lang_text) VALUES (pLang);
        SELECT LAST_INSERT_ID() INTO vLang_id;   
        END IF;
    END IF;

    -- get type id

    IF pType IS NULL THEN
        SET vType_id = NULL;
    ELSE
        SELECT type_id INTO vType_id FROM dict_type WHERE type_text = pType;
        IF vType_id IS NULL THEN 
        INSERT INTO dict_type (type_text) VALUES (pType);
        SELECT LAST_INSERT_ID() INTO vType_id;   
        END IF;
    END IF;

    -- get sub id

    IF pSub IS NULL THEN
        SET vSub_id = NULL;
    ELSE
        SELECT sub_id INTO vSub_id FROM dict_sub WHERE sub_text = pSub;
        IF vSub_id IS NULL THEN 
        INSERT INTO dict_sub (sub_text) VALUES (pSub);
        SELECT LAST_INSERT_ID() INTO vSub_id;   
        END IF;
    END IF;

    -- get prop id

    IF pProp IS NULL THEN
        SET vprop_id = NULL;
    ELSE
        SELECT prop_id INTO vProp_id FROM dict_prop WHERE prop_text = pProp;
        IF vprop_id IS NULL THEN 
        INSERT INTO dict_prop (prop_text) VALUES (pProp);
        SELECT LAST_INSERT_ID() INTO vProp_id;   
        END IF;
    END IF;

    -- get obj id

    IF pObj IS NULL THEN
        SET vObj_id = NULL;
    ELSE
        IF vLang_id IS NULL AND vType_id IS NULL THEN
          SELECT obj_id INTO vObj_id FROM dict_obj
          WHERE obj_text = pObj AND type_id IS NULL AND lang_id IS NULL;
        ELSE 
        IF vLang_id IS NULL AND vType_id IS NOT NULL THEN
          SELECT obj_id INTO vObj_id FROM dict_obj
          WHERE obj_text = pObj AND type_id = vType_id AND lang_id IS NULL;
        ELSE
        IF vLang_id IS NOT NULL AND vType_id IS NULL THEN
          SELECT obj_id INTO vObj_id FROM dict_obj
          WHERE obj_text = pObj AND type_id IS NULL AND lang_id = vLang_id;
        ELSE
          SELECT obj_id INTO vObj_id FROM dict_obj
          WHERE obj_text = pObj AND type_id = vType_id AND lang_id = vLang_id;
        END IF;
        END IF;
        END IF;

        IF vObj_id IS NULL THEN 
        INSERT IGNORE INTO dict_obj (obj_text,type_id,lang_id) VALUES (pObj,vType_id,vLang_id);
        SELECT LAST_INSERT_ID() INTO vObj_id;   
        END IF;
    END IF;

    INSERT IGNORE INTO triple (sub_id, prop_id, obj_id) VALUES (vSub_id, vProp_id, vObj_id);

  END;
//

DELIMITER ;
