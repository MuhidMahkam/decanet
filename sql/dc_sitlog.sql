-- DROP DATABASE IF EXISTS sitlog;

CREATE DATABASE IF NOT EXISTS sitlog DEFAULT CHARACTER SET utf8;

USE sitlog;

  DROP TABLE IF EXISTS sitlog.dclog;
  CREATE TABLE sitlog.dclog (DCLOG_ID INT NOT NULL AUTO_INCREMENT,
                             CONSTRAINT PK_DCLOG PRIMARY KEY (DCLOG_ID),
                             DBUSER VARCHAR(50) NOT NULL,
                             DUSER_ID INT NOT NULL,
                             DCLOG_DT DATETIME NOT NULL,
                             DCLOG_EXPRESSION TINYTEXT NOT NULL,
                             DCLOG_IRESULT INT NOT NULL, -- код ошибки MySQL
                             DCLOG_SRESULT TINYTEXT,     -- ошибка MySQL
                             DCLOG_IRET INT              -- возврат СП
    ) ENGINE=INNODB;