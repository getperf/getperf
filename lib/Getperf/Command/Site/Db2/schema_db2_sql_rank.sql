DROP TABLE IF EXISTS `db2_sql_rank`;
CREATE TABLE `db2_sql_rank` (
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
alter table `db2_sql_rank` add PRIMARY KEY(
    `clock`, `stmtid`, `member`, `stmt_type_id`, `package_schema`, 
    `package_name`, `effective_isolation`, `planid`, `metric`
);

ALTER TABLE db2_sql_rank PARTITION BY RANGE ( clock)
(PARTITION p2029_10_06 VALUES LESS THAN (UNIX_TIMESTAMP("2029-10-07 00:00:00")) ENGINE = InnoDB);

