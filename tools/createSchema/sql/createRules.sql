DELIMITER //
DROP PROCEDURE IF EXISTS createRules;
CREATE PROCEDURE `createRules`()
BEGIN
 
  DECLARE v_prop_id INTEGER;
  DECLARE v_counter_total INTEGER;
  DECLARE v_counter INTEGER DEFAULT 0;
  DECLARE v_percentage DOUBLE DEFAULT 0;
  DECLARE v_percentage_step DOUBLE DEFAULT 0.05;
  DECLARE c_done INTEGER DEFAULT 0;

  DECLARE cur_prop CURSOR FOR SELECT prop_id FROM dict_prop;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET c_done = 1;
 
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
    INSERT INTO rulecount (head,tail,c) (
        SELECT  head,tail,count(*) as c FROM (
            SELECT w1.prop_id as head,w2.prop_id as tail,1
            FROM triple w1 JOIN triple w2 USING (sub_id) JOIN dict_sub r ON (w1.sub_id=r.sub_id)
            WHERE w1.prop_id = v_prop_id AND w1.prop_id <> w2.prop_id AND r.sub_exclude = 0
            GROUP BY w1.sub_id,w1.prop_id,w2.prop_id) as sub
        -- HAVING if we want only rules appear more than X times
        GROUP BY head,tail HAVING count(*) > 1
    ) ON DUPLICATE KEY UPDATE c=c+VALUES(c);

    SET v_counter = v_counter + 1;

    IF (v_counter/v_counter_total >= v_percentage) THEN
       SELECT CONCAT((v_counter/v_counter_total)*100,'% done') as status;
       SET v_percentage = v_percentage + v_percentage_step;
    END IF;

  END LOOP loop_props;     

  CLOSE cur_prop;

  SELECT count(*) as 'total compressed rules' FROM rulecount;
  SELECT sum(c) as 'total rules' FROM rulecount;

  -- SELECT count(*) as 'total rules' FROM rule;

  -- INSERT INTO rulecount (SELECT head,tail,count(*) FROM rule GROUP BY head,tail);

  -- INSERT INTO rulecount (SELECT head,tail,1 FROM rule) ON DUPLICATE KEY UPDATE c=c+1;

  -- SELECT count(*) as 'total unique rules (compressed)' FROM rulecount;

END //
DELIMITER ;