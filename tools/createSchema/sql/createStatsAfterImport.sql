DELIMITER //
DROP PROCEDURE IF EXISTS createStatsAfterImport;
CREATE PROCEDURE `createStatsAfterImport`()
BEGIN
	DECLARE vIndexPs INT DEFAULT 0;
	DECLARE vIndexOs INT DEFAULT 0;
	DECLARE vIndexSp INT DEFAULT 0;
	
	SELECT COUNT(*)
	INTO vIndexPs
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
    AND table_name = 'triple'
    AND index_name = 'ps';
	
	IF vIndexPs > 0 THEN 
      DROP INDEX ps ON triple;
    END IF;
    
	SELECT COUNT(*)
	INTO vIndexOs
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
    AND table_name = 'triple'
    AND index_name = 'os';
    
    IF vIndexOs > 0 THEN
      DROP INDEX os ON triple;
    END IF;
    
	SELECT COUNT(*)
	INTO vIndexSp
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
    AND table_name = 'triple'
    AND index_name = 'sp';
    
    IF vIndexSp > 0 THEN
      DROP INDEX sp ON triple;
    END IF;

    -- count all sub occurrences
    UPDATE dict_sub d SET sub_count = (SELECT count(*) FROM triple t WHERE t.sub_id = d.sub_id);
    -- count all prop occurences
    -- first we ensure that there is the correct index
    CREATE INDEX ps ON triple (prop_id,sub_id);
    UPDATE dict_prop d
      SET prop_count = (SELECT count(*) FROM triple t WHERE t.prop_id = d.prop_id),
          prop_count_dist = (SELECT count(distinct(t.sub_id)) FROM triple t WHERE t.prop_id = d.prop_id);
    -- count all obj occurrences
    -- first we ensure that there is the correct index
    CREATE INDEX os ON triple (obj_id,sub_id);
    UPDATE dict_obj d SET obj_count = (SELECT count(*) FROM triple t WHERE t.obj_id = d.obj_id);

    -- other indices
    CREATE INDEX sp ON triple (sub_id,prop_id);



END //
DELIMITER ;