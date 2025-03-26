DROP TABLE IF EXISTS `db2_sql_text`;
CREATE TABLE `db2_sql_text` (
    `db_name`      varchar(100)   NOT NULL,
    `stmtid`       bigint         NOT NULL,
    `last_update`  integer        DEFAULT '0'      NOT NULL,
    `sql_text`     varchar(10000) NOT NULL
) ENGINE=InnoDB;
CREATE UNIQUE INDEX `db2_sql_text_uk` ON `db2_sql_text` (
    `db_name`, `stmtid`
);
CREATE INDEX `db2_sql_text_k1` ON `db2_sql_text` (
    `stmtid`
);
