DROP TABLE IF EXISTS `db2_sql_rank_daily`;
CREATE TABLE `db2_sql_rank_daily` (
    `stmtid`              bigint       NOT NULL,
    `member`              varchar(100) NOT NULL,
    `metric`              varchar(100)     DEFAULT ''       NOT NULL,
    `clock`               integer          DEFAULT '0'      NOT NULL,
    `max_value`           DOUBLE PRECISION DEFAULT '0.0000' NOT NULL,
    `sum_value`           DOUBLE PRECISION DEFAULT '0.0000' NOT NULL
) ENGINE=InnoDB;
alter table `db2_sql_rank_daily` add PRIMARY KEY(
    `clock`, `stmtid`, `member`, `metric`
);

ALTER TABLE db2_sql_rank_daily PARTITION BY RANGE ( clock)
(PARTITION p2023_03_06 VALUES LESS THAN (UNIX_TIMESTAMP("2023-03-07 00:00:00")) ENGINE = InnoDB);

