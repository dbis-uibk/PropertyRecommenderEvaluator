-- dict tables
-- we use only 255 chars due to the 767bytes key limitation

DROP TABLE IF EXISTS `dict_sub`;
CREATE TABLE IF NOT EXISTS `dict_sub` (
  `sub_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sub_text` varchar(700) NOT NULL,
  `sub_count` int(10) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`sub_id`),
  UNIQUE KEY `sub_text.unq` (`sub_text`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

ALTER TABLE `dict_sub` ADD COLUMN `sub_exclude` TINYINT(1) DEFAULT '0';
CREATE INDEX `exclude.idx` ON `dict_sub`(sub_exclude);

DROP TABLE IF EXISTS `dict_prop`;
CREATE TABLE IF NOT EXISTS `dict_prop` (
  `prop_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `prop_text` varchar(700) NOT NULL,
  `prop_count` int(10) unsigned NOT NULL DEFAULT '1',
  `prop_count_dist` int(10) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`prop_id`),
  UNIQUE KEY `prop_text.unq` (`prop_text`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `dict_lang`;
CREATE TABLE IF NOT EXISTS `dict_lang` (
  `lang_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `lang_text` varchar(255) NOT NULL,
  `lang_count` int(10) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`lang_id`),
  UNIQUE KEY `lang_text.unq` (`lang_text`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `dict_type`;
CREATE TABLE IF NOT EXISTS `dict_type` (
  `type_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `type_text` varchar(700) NOT NULL,
  `type_count` int(10) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`type_id`),
  UNIQUE KEY `type_text.unq` (`type_text`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `dict_obj`;
CREATE TABLE IF NOT EXISTS `dict_obj` (
  `obj_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `obj_text` varchar(10000) NOT NULL,
  `obj_count` int(10) unsigned NOT NULL DEFAULT '1',
  `type_id` smallint(5) unsigned NULL,
  `lang_id` smallint(5) unsigned NULL,
  PRIMARY KEY (`obj_id`),
  UNIQUE KEY `obj_text.unq` (obj_text(191),`type_id`,`lang_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- triple table

DROP TABLE IF EXISTS `triple`;
CREATE TABLE IF NOT EXISTS `triple` (
  `sub_id` int(10) unsigned NOT NULL,
  `prop_id` int(10) unsigned NOT NULL,
  `obj_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`sub_id`,`prop_id`,`obj_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- rule table

DROP TABLE IF EXISTS `rule`;
CREATE TABLE `rule` (
  `head` int(11) NOT NULL,
  `tail` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `rulecount`;
CREATE TABLE `rulecount` (
  `head` int(11) NOT NULL,
  `tail` int(11) NOT NULL,
  `c` int(11) NOT NULL,
  PRIMARY KEY (head, tail)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `rulecount_classified`;
CREATE TABLE `rulecount_classified` (
  `head` int(11) NOT NULL,
  `object` int(11) NOT NULL,
  `tail` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `confidence` float(12) NOT NULL,
  `confidence_distinct` float(12) NOT NULL,
  PRIMARY KEY (head, object, tail)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `rulecount_objects`;
CREATE TABLE `rulecount_objects` (
  `head` int(11) NOT NULL,
  `tail` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `confidence` float(12) NOT NULL,
  `confidence_distinct` float(12) NOT NULL,
  PRIMARY KEY (head, tail)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `rulecount_object_property`;
CREATE TABLE `rulecount_object_property` (
  `head` int(11) NOT NULL,
  `tail` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `confidence` float(12) NOT NULL,
  `confidence_distinct` float(12) NOT NULL,
  PRIMARY KEY (head, tail)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `rulecount_mem`;
CREATE TABLE `rulecount_mem` (
  `head` int(11) NOT NULL,
  `tail` int(11) NOT NULL,
  `c` int(11) NOT NULL,
  PRIMARY KEY (head, tail)
) ENGINE=Memory DEFAULT CHARSET=latin1;

-- eval tables

DROP TABLE IF EXISTS `triple_reconstruct`;
CREATE TABLE IF NOT EXISTS `triple_reconstruct` (
  `sub_id` int(10) unsigned NOT NULL,
  `prop_id` int(10) unsigned NOT NULL,
  `obj_id` int(10) unsigned NOT NULL,
  `idx` mediumint(8) unsigned NOT NULL,
  PRIMARY KEY (`sub_id`,`prop_id`,`obj_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

