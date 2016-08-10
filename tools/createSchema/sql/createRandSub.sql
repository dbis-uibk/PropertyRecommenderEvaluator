DELIMITER //
DROP PROCEDURE IF EXISTS createRandSub;
CREATE PROCEDURE `createRandSub`()
BEGIN
 
	DECLARE v_sub_count_total INT(10) DEFAULT '0';
    DECLARE v_sub_count_matched INT(10) DEFAULT '0';
	
    DECLARE v_rand_percentage DECIMAL(5,2) DEFAULT '0.1';
    DECLARE v_rand_matched_percentage DECIMAL(5,2) DEFAULT '0.1';

    DECLARE v_min_prop_count INT(10) DEFAULT '0';

    SET v_rand_percentage = 0.1;
    SET v_min_prop_count = 4;

	SELECT COUNT(*) INTO v_sub_count_total FROM dict_sub;
    SELECT COUNT(*) INTO v_sub_count_matched FROM (SELECT sub_id FROM triple GROUP BY sub_id HAVING count(*) >= v_min_prop_count) as matched;
    
	SET v_rand_matched_percentage = (v_sub_count_total*v_rand_percentage)/v_sub_count_matched;

    -- set 10% of total that fulfill criteria of v_min_prop_count to exclude
    -- include useless sub_id in calc to force recalc in each line
    UPDATE dict_sub d SET sub_exclude = 1 WHERE sub_id IN 
      (SELECT sub_id FROM
         (SELECT sub_id FROM triple GROUP BY sub_id HAVING count(*) >= v_min_prop_count) as candidates -- all subjects with more than v_min_prop_count properties
       WHERE (RAND() * v_sub_count_matched)+sub_id < (v_sub_count_matched*v_rand_matched_percentage)+sub_id); -- ??? 

	SELECT COUNT(*) as 'sub_total', sum(sub_exclude) as 'sub_excluded', sum(sub_exclude)/COUNT(*) as 'percentage' FROM dict_sub;

	-- insert excluded triples for reconstruction
	INSERT IGNORE INTO triple_reconstruct (
       SELECT s.sub_id,prop_id,obj_id, 0 FROM
	   dict_sub s JOIN triple t USING (sub_id)
	   WHERE sub_exclude = 1
	);

    CALL createReconstructOrder();

END //
DELIMITER ;