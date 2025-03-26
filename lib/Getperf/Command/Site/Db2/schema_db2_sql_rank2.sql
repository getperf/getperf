DROP TABLE IF EXISTS `db2_sql_rank2`;
CREATE TABLE `db2_sql_rank2` (
    `stmtid`              bigint       NOT NULL,
    `member`              varchar(100) NOT NULL,
    `stmt_type_id`        varchar(100) NOT NULL,
    `package_schema`      varchar(100) NOT NULL,
    `package_name`        varchar(100) NOT NULL,
    `effective_isolation` varchar(100) NOT NULL,
    `planid`              bigint       NOT NULL,
    `metric`              varchar(100)     DEFAULT ''       NOT NULL,
    `clock`               integer          DEFAULT '0'      NOT NULL,
    `value`               DOUBLE PRECISION DEFAULT '0.0000' NOT NULL
) ENGINE=InnoDB;
alter table `db2_sql_rank2` add PRIMARY KEY(
    `clock`, `stmtid`, `member`, `stmt_type_id`, `package_schema`, 
    `package_name`, `effective_isolation`, `planid`, `metric`
);

ALTER TABLE db2_sql_rank2 PARTITION BY RANGE ( clock)
(PARTITION p2021_09_15 VALUES LESS THAN (1631718000) ENGINE = InnoDB,
 PARTITION p2021_09_16 VALUES LESS THAN (1631804400) ENGINE = InnoDB,
 PARTITION p2021_09_17 VALUES LESS THAN (1631890800) ENGINE = InnoDB,
 PARTITION p2021_09_18 VALUES LESS THAN (1631977200) ENGINE = InnoDB,
 PARTITION p2021_09_19 VALUES LESS THAN (1632063600) ENGINE = InnoDB,
 PARTITION p2021_09_20 VALUES LESS THAN (1632150000) ENGINE = InnoDB,
 PARTITION p2021_09_21 VALUES LESS THAN (1632236400) ENGINE = InnoDB,
 PARTITION p2021_09_22 VALUES LESS THAN (1632322800) ENGINE = InnoDB,
 PARTITION p2021_09_23 VALUES LESS THAN (1632409200) ENGINE = InnoDB,
 PARTITION p2021_09_24 VALUES LESS THAN (1632495600) ENGINE = InnoDB,
 PARTITION p2021_09_25 VALUES LESS THAN (1632582000) ENGINE = InnoDB,
 PARTITION p2021_09_26 VALUES LESS THAN (1632668400) ENGINE = InnoDB,
 PARTITION p2021_09_27 VALUES LESS THAN (1632754800) ENGINE = InnoDB,
 PARTITION p2021_09_28 VALUES LESS THAN (1632841200) ENGINE = InnoDB) ;

