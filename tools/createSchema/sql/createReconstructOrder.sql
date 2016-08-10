DELIMITER //
DROP PROCEDURE IF EXISTS createReconstructOrder;
CREATE PROCEDURE `createReconstructOrder`()
BEGIN
 
  DECLARE v_sub_id INTEGER;
  DECLARE v_prop_id INTEGER;
  DECLARE v_obj_id INTEGER;
  DECLARE v_max INTEGER;
  DECLARE c_done INTEGER DEFAULT 0;

  DECLARE cur_sub CURSOR FOR SELECT sub_id,prop_id,obj_id FROM triple_reconstruct ORDER BY RAND();
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET c_done = 1;

  OPEN cur_sub;

  loop_subs: LOOP
    FETCH cur_sub INTO v_sub_id,v_prop_id,v_obj_id;
    IF c_done THEN LEAVE loop_subs; END IF;
    -- order all triples starting at 1 in each subject
	SELECT MAX(idx)+1 INTO v_max FROM triple_reconstruct WHERE sub_id = v_sub_id;
	UPDATE triple_reconstruct SET idx = v_max WHERE sub_id = v_sub_id AND prop_id = v_prop_id AND obj_id = v_obj_id;
  END LOOP loop_subs;     

  CLOSE cur_sub;


END //
DELIMITER ;  