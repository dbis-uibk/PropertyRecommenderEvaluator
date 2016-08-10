DELIMITER //
DROP PROCEDURE IF EXISTS createObjectPropertyRules;
CREATE PROCEDURE `createObjectPropertyRules`()
BEGIN
 
  DECLARE v_obj_id INTEGER;
  DECLARE v_counter_total INTEGER;
  DECLARE v_counter INTEGER DEFAULT 0;
  DECLARE v_percentage DOUBLE DEFAULT 0;
  DECLARE v_percentage_step DOUBLE DEFAULT 0.05;
  DECLARE c_done INTEGER DEFAULT 0;
  DECLARE v_conf_threshold INTEGER DEFAULT 0.9;

  DECLARE cur_obj CURSOR FOR SELECT obj_id FROM dict_obj;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET c_done = 1;
  
  SELECT count(*) INTO v_counter_total FROM dict_obj;
  SET v_percentage = v_percentage_step;

  OPEN cur_obj;

  loop_objs: LOOP
    FETCH cur_obj INTO v_obj_id;
    IF c_done THEN LEAVE loop_objs; END IF;
    
    INSERT INTO rulecount_object_property (head, tail, count, confidence, confidence_distinct) (
      SELECT t1.obj_id AS head, t2.prop_id AS tail, COUNT(DISTINCT t1.sub_id) AS COUNT, 
        COUNT(DISTINCT t1.sub_id) / (
          SELECT COUNT(*)
          FROM triple
          WHERE obj_id = v_obj_id
        ) AS confidence, 
        COUNT(DISTINCT t1.sub_id) / (
          SELECT COUNT(DISTINCT sub_id)
          FROM triple
          WHERE obj_id = v_obj_id
        ) AS confidence_distinct
      FROM triple t1 JOIN triple t2 USING(sub_id) JOIN dict_sub USING (sub_id)
      WHERE t1.obj_id = v_obj_id AND sub_exclude = 0
      GROUP BY head, tail
      HAVING count > 1
    );

    SET v_counter = v_counter + 1;

    IF (v_counter/v_counter_total >= v_percentage) THEN
       SELECT CONCAT((v_counter/v_counter_total) * 100, '% done') as status;
       SET v_percentage = v_percentage + v_percentage_step;
    END IF;

  END LOOP loop_objs;     

  CLOSE cur_obj;

  SELECT count(*) as 'total compressed rules' FROM rulecount_object_property;
  SELECT sum(c) as 'total rules' FROM rulecount_object_property;

END //
DELIMITER ;
