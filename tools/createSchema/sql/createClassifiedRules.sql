DELIMITER //
DROP PROCEDURE IF EXISTS createClassifiedRules;
CREATE PROCEDURE `createClassifiedRules`()
BEGIN
 
  DECLARE v_prop31_id INTEGER;
  DECLARE v_prop279_id INTEGER;
  DECLARE v_prop_id INTEGER;
  DECLARE v_counter_total INTEGER;
  DECLARE v_counter INTEGER DEFAULT 0;
  DECLARE v_percentage DOUBLE DEFAULT 0;
  DECLARE v_percentage_step DOUBLE DEFAULT 0.05;
  DECLARE c_done INTEGER DEFAULT 0;

  DECLARE cur_prop CURSOR FOR SELECT prop_id FROM dict_prop;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET c_done = 1;
 
  SELECT prop_id INTO v_prop31_id FROM dict_prop WHERE prop_text = 'P31';
  SELECT prop_id INTO v_prop279_id FROM dict_prop WHERE prop_text = 'P279';
  
  SELECT count(*) INTO v_counter_total FROM dict_prop;
  SET v_percentage = v_percentage_step;

  OPEN cur_prop;

  loop_props: LOOP
    FETCH cur_prop INTO v_prop_id;
    IF c_done THEN LEAVE loop_props; END IF;
    -- INSERT INTO rule (
    --     SELECT w1.prop_id,w2.prop_id
    --     FROM triple w1 JOIN triple w2 USING (sub_id) JOIN dict_sub r ON (w1.sub_id=r.sub_id)
    --     WHERE w1.prop_id = v_prop_id AND w1.prop_id <> w2.prop_id AND r.sub_exclude = 0
    --     GROUP BY w1.sub_id,w1.prop_id,w2.prop_id
    -- );
    IF (v_prop_id = v_prop31_id OR v_prop_id = v_prop279_id) THEN
        INSERT INTO rulecount_classified (head, object, tail, count, confidence, confidence_distinct) (
          SELECT head, object, tail, count, count / count_instance as confidence, count / count_instance_distinct as confidence_distinct
          FROM ( SELECT t1.prop_id AS head, obj.obj_id AS object, t2.prop_id AS tail, COUNT(DISTINCT t1.sub_id) AS count,
                   (
                     SELECT COUNT(*)
                     FROM triple JOIN dict_obj USING(obj_id)
                     WHERE prop_id = v_prop_id AND obj_text = sub.sub_text
                   ) AS count_instance, 
                   (
                     SELECT COUNT(DISTINCT sub_id)
                     FROM triple JOIN dict_obj USING(obj_id)
                     WHERE prop_id = v_prop_id AND obj_text = sub.sub_text
                   ) AS count_instance_distinct
                 FROM triple t1 JOIN triple t2 USING(sub_id) JOIN dict_obj obj ON(t1.obj_id = obj.obj_id) JOIN dict_sub sub ON (sub_text = obj_text)
                 WHERE t1.prop_id = v_prop_id AND t1.prop_id <> t2.prop_id AND sub_exclude = 0
                 GROUP BY head, object, tail
                 HAVING COUNT > 0
               ) AS rulecount_classified
        );
    ELSE
        INSERT INTO rulecount_classified (head, object, tail, count, confidence, confidence_distinct) (
          SELECT t1.prop_id AS head, 0 AS object, t2.prop_id AS tail, COUNT(DISTINCT t1.sub_id) AS COUNT, 
            COUNT(DISTINCT t1.sub_id) / (
              SELECT COUNT(*)
              FROM triple
              WHERE prop_id = v_prop_id
            ) AS confidence, 
            COUNT(DISTINCT t1.sub_id) / (
              SELECT COUNT(DISTINCT sub_id)
              FROM triple
              WHERE prop_id = v_prop_id
            ) AS confidence_distinct
          FROM triple t1 JOIN triple t2 USING(sub_id) JOIN dict_sub USING (sub_id)
          WHERE t1.prop_id = v_prop_id AND t1.prop_id <> t2.prop_id AND sub_exclude = 0
          GROUP BY head, object, tail
          HAVING COUNT > 1
        );
    END IF;

    SET v_counter = v_counter + 1;

    IF (v_counter/v_counter_total >= v_percentage) THEN
       SELECT CONCAT((v_counter/v_counter_total)*100,'% done') as status;
       SET v_percentage = v_percentage + v_percentage_step;
    END IF;

  END LOOP loop_props;     

  CLOSE cur_prop;

  SELECT count(*) as 'total compressed rules' FROM rulecount_classified;
  SELECT sum(c) as 'total rules' FROM rulecount_classified;

  -- SELECT count(*) as 'total rules' FROM rule;

  -- INSERT INTO rulecount (SELECT head,tail,count(*) FROM rule GROUP BY head,tail);

  -- INSERT INTO rulecount (SELECT head,tail,1 FROM rule) ON DUPLICATE KEY UPDATE c=c+1;

  -- SELECT count(*) as 'total unique rules (compressed)' FROM rulecount;

END //
DELIMITER ;
