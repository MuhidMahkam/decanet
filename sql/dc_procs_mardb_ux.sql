-- СКРИПТ ФУНКЦИЙ БИЗНЕС-ЛОГИКИ БД decanet
-- --------------------------------------
-- v0.016 2025-01-12
-- --------------------------------------


-- бизнес логика готовая к работе на unix - nginx - marшidb на удаленном сервере
-- nginx должен обрабатывать расширение .sit как .php
/*
        location / {
        index index.php index.html index.sit;
        try_files $uri $uri/ /\.(php|sit)?$args;
        }

        location ~ \.(php|sit)$ {
        try_files $uri $uri/ /\.(php|sit)?$args;
        fastcgi_split_path_info ^(.+\.(?:php|sit))(.*)$;
        fastcgi_pass unix:/var/run/php-fpm.web.sock;
        fastcgi_index index.sit;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
        }
*/

-- НСД переведено на роли
-- для инициализации работы в СУБД
-- админ создает схему decanet
-- нужен пользователь (например decan) c правами:
-- GRANT ALL PRIVILEGES ON decanet.* TO 'decan'@'%'
-- GRANT SELECT ON mysql.* TO 'decan'@'%'  (для отладки, но не обязательно)
-- GRANT CREATE USER, GRANT OPTION ON *.* TO 'decan'@'%'

-- все роли назначить decan иначе он не сможет их раздавать юзерам
-- возможно рутом через INSERT INTO mysql.roles_mapping VALUES ('localhost', 'decan', 'A', 'Y');
-- GRANT A (DZSV) TO 'decan'@'%'

-- юзерам с ролью A нужно назначть и роли DZSV иначе они не смогут создавать пользователя (дарить и назначать ему роль)


USE decanet;
USE decanet;

CREATE ROLE IF NOT EXISTS A;
CREATE ROLE IF NOT EXISTS D;
CREATE ROLE IF NOT EXISTS Z;
CREATE ROLE IF NOT EXISTS S;
CREATE ROLE IF NOT EXISTS V;

-- вот тут нужно GRANT CREATE USER, GRANT OPTION ON *.* TO 'decan'@'%'
GRANT CREATE USER ON *.* TO A;

-- а лучше так (но только root)
DELETE FROM mysql.procs_priv
  WHERE Db = 'decanet' AND
        User IN ('A', 'D', 'Z', 'S', 'V');

DELIMITER $$

/*
-- служебная - ОТНЯТЬ GRANT EXECUTE у ролей
DROP PROCEDURE IF EXISTS decanet.REVOKEXECUTE $$
CREATE PROCEDURE decanet.REVOKEXECUTE()
BEGIN

  DECLARE done, rvk INT DEFAULT 0;
  DECLARE N VARCHAR(64);
  DECLARE cRE CURSOR FOR SELECT ROUTINE_NAME FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'decanet' AND ROUTINE_TYPE = 'PROCEDURE';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42000' SET rvk = rvk + 1; -- если таких полномочий нет, то ничего страшного - продолжаем
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;


  SET rvk = 0;

  OPEN cRE;
  REPEAT
    FETCH cRE INTO N;
    IF NOT done THEN
        SET @dcsql = ('REVOKE EXECUTE ON PROCEDURE decanet.', N, ' FROM A');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
        SET @dcsql = CONCAT('REVOKE EXECUTE ON PROCEDURE decanet.', N, ' FROM D');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
        SET @dcsql = CONCAT('REVOKE EXECUTE ON PROCEDURE decanet.', N, ' FROM Z');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
        SET @dcsql = CONCAT('REVOKE EXECUTE ON PROCEDURE decanet.', N, ' FROM S');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
        SET @dcsql = CONCAT('REVOKE EXECUTE ON PROCEDURE decanet.', N, ' FROM V');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
    END IF;
  UNTIL done END REPEAT;
  CLOSE cRE;
  DEALLOCATE PREPARE dcstmt;


  SELECT 1 AS RES, rvk AS RVK;

END $$

-- CALL decanet.REVOKEXECUTE() $$
*/

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ I. ПОДПРОГРАММЫ ОБЩЕГО НАЗНАЧЕНИЯ
-- ---------------------------------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS decanet.DBVER_ITM$$
CREATE PROCEDURE decanet.DBVER_ITM()
COMMENT 'ADZSV'
BEGIN
  SELECT MAX(VERNO) AS DBVER
    FROM decanet.version;
END$$
GRANT EXECUTE ON PROCEDURE decanet.DBVER_ITM TO A,D,Z,S,V $$


-- учебный год на заданную дату
DROP FUNCTION IF EXISTS decanet.GETUYEAR $$
CREATE FUNCTION decanet.GETUYEAR(DIV_ID INT, D DATE) RETURNS YEAR
BEGIN
  DECLARE UYEAR YEAR;
  DECLARE CURM INT;

  SET CURM = MONTH(D);

  SELECT IF(CURM < D.DIVISION_UYEAR, YEAR(D) - 1, YEAR(D)) INTO UYEAR
    FROM decanet.division D WHERE D.DIVISION_ID = DIV_ID;

  RETURN UYEAR;
END $$

-- строка периода обучения потока c SELECT-ом
DROP FUNCTION IF EXISTS decanet.FSTRMPERIOD $$
CREATE FUNCTION decanet.FSTRMPERIOD(STRM_ID INT) RETURNS VARCHAR(10)
BEGIN
  DECLARE S VARCHAR(10);
  SELECT CONCAT(STREAM_FROMYEAR, '-', STREAM_FROMYEAR + FLOOR(STREAM_SEMCOUNT / 2 + 0.5) - 1)
    INTO S
    FROM decanet.stream
    WHERE STREAM_ID = STRM_ID;
  RETURN S;
END$$

-- строка периода обучения потока c вычислением
DROP FUNCTION IF EXISTS decanet.FSTREAMPERIOD $$
CREATE FUNCTION decanet.FSTREAMPERIOD(STRM_FY YEAR, SCNT INT) RETURNS VARCHAR(10)
BEGIN
  RETURN (CONCAT(STRM_FY, '-', STRM_FY + FLOOR(SCNT / 2 + 0.5) - 1));
END$$

-- дата начала нечетного семестра для отделения в указанном учебном году
DROP FUNCTION IF EXISTS decanet.GETCHETBEGSEM $$
CREATE FUNCTION decanet.GETCHETBEGSEM(DIV_ID INT, Y YEAR) RETURNS DATE
BEGIN
  DECLARE S VARCHAR(11);
  SET S = CONCAT(Y, '-',
                 (SELECT D.DIVISION_UYEAR
                    FROM decanet.division D
                    WHERE D.DIVISION_ID = DIV_ID),
                 '-01');
  RETURN CAST(S AS DATE);
END$$

-- дата начала четного семестра для отделения в указанном учебном году
DROP FUNCTION IF EXISTS decanet.GETNCHETBEGSEM $$
CREATE FUNCTION decanet.GETNCHETBEGSEM(DIV_ID INT, Y YEAR) RETURNS DATE
BEGIN
  DECLARE S VARCHAR(11);
  SET S = CONCAT(Y, '-',
                 (SELECT D.DIVISION_HALFUYEAR
                    FROM decanet.division D
                    WHERE D.DIVISION_ID = DIV_ID),
                 '-01');
  RETURN CAST(S AS DATE);
END$$

-- определение текущего курса учебной группы на заданную дату
-- (для перевода на сл. курс)
DROP FUNCTION IF EXISTS SGROUPKURS $$
CREATE FUNCTION SGROUPKURS(SGR_ID INT, DT DATE) RETURNS INT
COMMENT 'ADZSV'
BEGIN
  DECLARE DI, DS, KURSN INT;
  DECLARE FY, UYEAR YEAR;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION RETURN 0; -- SQL - ошибка

  SELECT D.DIVISION_ID, R.STREAM_SEMCOUNT, R.STREAM_FROMYEAR
    INTO DI, DS, FY
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE G.SGROUP_ID = SGR_ID LIMIT 1;

  SET UYEAR = GETUYEAR(DI, DT);

  SET KURSN = UYEAR - FY + 1;

  IF KURSN > DS / 2 THEN
    SET KURSN = ROUND(DS / 2);
  END IF;

  RETURN KURSN;
END $$


-- определение текущего семестра учебной группы
DROP PROCEDURE IF EXISTS decanet.CURSEM_ITM $$
CREATE PROCEDURE decanet.CURSEM_ITM(IN SGR_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE UYEAR YEAR;
  DECLARE HYEAR INT;
  DECLARE MUY INT;
  DECLARE MHY INT;
  DECLARE CURM INT;

  SET CURM = MONTH(CURDATE());


  SELECT IF(CURM < D.DIVISION_UYEAR, YEAR(NOW()) - 1, YEAR(NOW())),
         DIVISION_UYEAR,
         DIVISION_HALFUYEAR
    INTO UYEAR, MUY, MHY -- учебный год, месяц начала уч. года, месяц смены полугодия (начала 2-го семестра) уч. года
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE G.SGROUP_ID = SGR_ID;

  -- определение коэффициента семестра
  IF MHY > MUY THEN
    IF CURM >= MUY AND CURM < MHY THEN
      SET HYEAR = 1;
    ELSE
      SET HYEAR = 0;
    END IF;
  ELSE
    IF CURM >= MHY AND CURM < MUY THEN
      SET HYEAR = 0;
    ELSE
      SET HYEAR = 1;
    END IF;
  END IF;

  SELECT IF(2 * (UYEAR - R.STREAM_FROMYEAR + 1) - HYEAR <= R.STREAM_SEMCOUNT,
            2 * (UYEAR - R.STREAM_FROMYEAR + 1) - HYEAR,
            R.STREAM_SEMCOUNT) AS CURSEM
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGR_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.CURSEM_ITM TO A,D,Z,S,V $$

-- определение текущего семестра учебной группы
-- ТОЖЕ только функция
DROP FUNCTION IF EXISTS decanet.FGETCURSEM $$
CREATE FUNCTION decanet.FGETCURSEM(SGR_ID INT) RETURNS INT
BEGIN
  DECLARE UYEAR YEAR;
  DECLARE HYEAR INT;
  DECLARE MUY INT;
  DECLARE MHY INT;
  DECLARE CURM INT;
  DECLARE CURSEM INT;

  SET CURM = MONTH(CURDATE());

  SELECT IF(CURM < D.DIVISION_UYEAR, YEAR(NOW()) - 1, YEAR(NOW())),
         DIVISION_UYEAR,
         DIVISION_HALFUYEAR
    INTO UYEAR, MUY, MHY -- учебный год, месяц начала уч. года, месяц смены полугодия (начала 2-го семестра) уч. года
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE G.SGROUP_ID = SGR_ID;

  -- определение коэффициента семестра
  IF MHY > MUY THEN
    IF CURM >= MUY AND CURM < MHY THEN
      SET HYEAR = 1;
    ELSE
      SET HYEAR = 0;
    END IF;
  ELSE
    IF CURM >= MHY AND CURM < MUY THEN
      SET HYEAR = 0;
    ELSE
      SET HYEAR = 1;
    END IF;
  END IF;

  SET CURSEM = (SELECT IF(2 * (UYEAR - R.STREAM_FROMYEAR + 1) - HYEAR <= R.STREAM_SEMCOUNT,
                          2 * (UYEAR - R.STREAM_FROMYEAR + 1) - HYEAR,
                          R.STREAM_SEMCOUNT) AS CURSEM
                  FROM decanet.sgroup G LEFT JOIN
                       decanet.stream R USING (STREAM_ID)
                  WHERE G.SGROUP_ID = SGR_ID);

  RETURN CURSEM;
END$$

-- ##SSG
-- определение текущего семестра студента
DROP FUNCTION IF EXISTS decanet.GETSTUDCURSEM $$
CREATE FUNCTION decanet.GETSTUDCURSEM(SSG_ID INT) RETURNS INT
BEGIN
  DECLARE UYEAR YEAR;
  DECLARE HYEAR INT;
  DECLARE MUY INT;
  DECLARE MHY INT;
  DECLARE CURM INT;
  DECLARE CURSEM INT;

  SET CURM = MONTH(NOW());

  SELECT IF(CURM < D.DIVISION_UYEAR, YEAR(NOW()) - 1, YEAR(NOW())),
         DIVISION_UYEAR,
         DIVISION_HALFUYEAR
    INTO UYEAR, MUY, MHY   -- учебный год, месяц начала уч. года, месяц смены полугодия (начала 2-го семестра) уч. года
    FROM decanet.studsgrp SSG LEFT JOIN
         decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
    WHERE SSG.STUDSGRP_ID = SSG_ID;

  -- определение коэффициента семестра
  IF MHY > MUY THEN
    IF CURM >= MUY AND CURM < MHY THEN
      SET HYEAR = 1;
    ELSE
      SET HYEAR = 0;
    END IF;
  ELSE
    IF CURM >= MHY AND CURM < MUY THEN
      SET HYEAR = 0;
    ELSE
      SET HYEAR = 1;
    END IF;
  END IF;

  SELECT IF(FSGROUP_ACTIVE(G.SGROUP_ID),
            2 * (UYEAR - R.STREAM_FROMYEAR + 1) - HYEAR,
            R.STREAM_SEMCOUNT) INTO CURSEM
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID;

  RETURN CURSEM;

END$$

-- кол-во семестров на потоке
DROP PROCEDURE IF EXISTS decanet.STREAMSEM_CNT $$
CREATE PROCEDURE decanet.STREAMSEM_CNT(IN DIV_ID INT, IN FY INT)
COMMENT 'ADZSV'
BEGIN
  SELECT STREAM_SEMCOUNT
    FROM decanet.stream
    WHERE DIVISION_ID = DIV_ID AND
          STREAM_FROMYEAR = FY;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STREAMSEM_CNT TO A,D,Z,S,V $$

-- список возможных результатов для контрольного мероприятия
DROP PROCEDURE IF EXISTS decanet.CONTROLRESULT_LST $$
CREATE PROCEDURE decanet.CONTROLRESULT_LST(IN CTRL_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT R.RESULT_ID, R.RESULT_INT, R.RESULT_ABBR, R.RESULT_NAME, R.RESULT_PASSFLAG
    FROM decanet.control C LEFT JOIN
         decanet.resset S USING (CONTROL_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID)
    WHERE C.CONTROL_ID = CTRL_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CONTROLRESULT_LST TO A,D,Z,S,V $$

-- список ин. языков
DROP PROCEDURE IF EXISTS decanet.FOREIGNLAN_LST $$
CREATE PROCEDURE decanet.FOREIGNLAN_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT L.FOREIGNLAN_ID, L.FOREIGNLAN_NAME
    FROM decanet.foreignlan L;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FOREIGNLAN_LST TO A,D,Z,S,V $$

-- список полов
DROP PROCEDURE IF EXISTS decanet.SEX_LST $$
CREATE PROCEDURE decanet.SEX_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT 1 AS SEX_ID, 'М' AS SEX UNION
  SELECT 2, 'Ж';
END $$
GRANT EXECUTE ON PROCEDURE decanet.SEX_LST TO A,D,Z,S,V $$

-- список семейных положений
DROP PROCEDURE IF EXISTS decanet.FAMSTATE_LST $$
CREATE PROCEDURE decanet.FAMSTATE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT 1 AS FAMSTATE_ID, 'холост' AS FAMSTATE UNION
  SELECT 2, 'не замужем' UNION
  SELECT 3, 'женат' UNION
  SELECT 4, 'замужем';
END $$
GRANT EXECUTE ON PROCEDURE decanet.FAMSTATE_LST TO A,D,Z,S,V $$

-- список типов обучения
DROP PROCEDURE IF EXISTS decanet.EDUTYPE_LST $$
CREATE PROCEDURE decanet.EDUTYPE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT EDUTYPE_ID, EDUTYPE_ABBR, EDUTYPE_NAME
    FROM decanet.edutype;
END $$
GRANT EXECUTE ON PROCEDURE decanet.EDUTYPE_LST TO A,D,Z,S,V $$

-- список форм обучения
DROP PROCEDURE IF EXISTS decanet.EDUFORM_LST $$
CREATE PROCEDURE decanet.EDUFORM_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT E.EDUFORM_ID, E.EDUFORM_ABBR, E.EDUFORM_NAME
    FROM decanet.eduform E;
END $$
GRANT EXECUTE ON PROCEDURE decanet.EDUFORM_LST TO A,D,Z,S,V $$


-- количество семестров у студента
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDSEM_CNT $$
CREATE PROCEDURE decanet.STUDSEM_CNT(SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT R.STREAM_SEMCOUNT AS MAXSEM, MAX(E.SEMESTR) AS FILLSEM
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING(STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID)
  WHERE SG.STUDSGRP_ID = SSG_ID AND
        M.MAINPROG_ID IS NOT NULL
  GROUP BY SG.STUDSGRP_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEM_CNT TO A,D,Z,S,V $$

-- учебный год студента в группе по семестру
-- ##SSG
DROP FUNCTION IF EXISTS decanet.FSTUDUYEAR $$
CREATE FUNCTION decanet.FSTUDUYEAR(SSG_ID INT, SEM INT) RETURNS VARCHAR(25)
BEGIN
  RETURN (SELECT CONCAT(R.STREAM_FROMYEAR + FLOOR(SEM / 2 + 0.5) - 1, '/', R.STREAM_FROMYEAR + FLOOR(SEM / 2 + 0.5))
            FROM decanet.studsgrp SG LEFT JOIN
                 decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
                 decanet.stream R USING (STREAM_ID)
            WHERE SG.STUDSGRP_ID = SSG_ID);
END$$

-- курс по семестру
-- ##SSG
DROP FUNCTION IF EXISTS decanet.FKURS $$
CREATE FUNCTION decanet.FKURS(SEM INT) RETURNS INT
BEGIN
  RETURN FLOOR(SEM / 2 + 0.5);
END$$

-- количество семестров у группы
DROP PROCEDURE IF EXISTS decanet.SGROUPSEM_CNT $$
CREATE PROCEDURE decanet.SGROUPSEM_CNT(SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT R.STREAM_SEMCOUNT AS MAXSEM, MAX(E.SEMESTR) AS FILLSEM
    FROM decanet.stream R LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID)
  WHERE G.SGROUP_ID = SGRP_ID AND
         M.MAINPROG_ID IS NOT NULL
  GROUP BY G.SGROUP_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SGROUPSEM_CNT TO A,D,Z,S,V $$

-- кол-во видов контроля CNT
DROP PROCEDURE IF EXISTS decanet.CONTROL_CNT $$
CREATE PROCEDURE decanet.CONTROL_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(CONTROL_ID) AS CNT
    FROM decanet.control;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CONTROL_CNT TO A,D,Z,S,V $$

-- список видов контроля LIST
DROP PROCEDURE IF EXISTS decanet.CONTROL_LST $$
CREATE PROCEDURE decanet.CONTROL_LST(IN PATT BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT CONTROL_ID, CONTROL_ENDFLAG, CONTROL_ABBR, CONTROL_NAME, CONTROL_DESC
    FROM decanet.control  LEFT JOIN
         decanet.phasectrl PC USING (CONTROL_ID)
    WHERE IF(PATT IS NULL, TRUE, IF(PATT, PC.SESSPHASE_ID = 1, PC.SESSPHASE_ID > 1))
    ORDER BY CONTROL_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CONTROL_LST TO A,D,Z,S,V $$

-- кол-во этапов сессии CNT
DROP PROCEDURE IF EXISTS decanet.SESSPHASE_CNT $$
CREATE PROCEDURE decanet.SESSPHASE_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(SESSPHASE_ID) AS CNT
    FROM decanet.sessphase;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SESSPHASE_CNT TO A,D,Z,S,V $$

-- список этапов сессии LIST
DROP PROCEDURE IF EXISTS decanet.SESSPHASE_LST $$
CREATE PROCEDURE decanet.SESSPHASE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT SESSPHASE_ID, SESSPHASE_ABBR, SESSPHASE_NAME, SESSPHASE_DESC
    FROM decanet.sessphase
    ORDER BY SESSPHASE_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SESSPHASE_LST TO A,D,Z,S,V $$

-- строка этапа сессии ITM
DROP PROCEDURE IF EXISTS decanet.SESSPHASE_ITM $$
CREATE PROCEDURE decanet.SESSPHASE_ITM(IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SESSPHASE_ID, SESSPHASE_ABBR, SESSPHASE_NAME, SESSPHASE_DESC
    FROM decanet.sessphase
    WHERE SESSPHASE_ID = SPHASE;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SESSPHASE_ITM TO A,D,Z,S,V $$

-- список всех контингентных статусов CNT
DROP PROCEDURE IF EXISTS decanet.STUDSTATUS_CNT $$
CREATE PROCEDURE decanet.STUDSTATUS_CNT(IN ST BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(STUDSTATUS_ID) AS CNT
    FROM decanet.studstatus
    WHERE IF(ST IS NULL, TRUE, STUDSTATUS_ACTIVE = ST);
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDSTATUS_CNT TO A,D,Z,S,V $$

-- список всех контингентных статусов LST
DROP PROCEDURE IF EXISTS decanet.STUDSTATUS_LST $$
CREATE PROCEDURE decanet.STUDSTATUS_LST(IN ST BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT *
    FROM decanet.studstatus
    WHERE IF(ST IS NULL, TRUE, STUDSTATUS_ACTIVE = ST)
    ORDER BY STUDSTATUS_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDSTATUS_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . КОРЗИНА (РАБОТАЕМ В ОДНОМ КОННЕКТЕ)
-- ---------------------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS decanet.BASKET_INIT $$
CREATE PROCEDURE decanet.BASKET_INIT()
COMMENT 'ADZSV'
BEGIN
  DROP TEMPORARY TABLE IF EXISTS decanet.sysbasket;
  CREATE TEMPORARY TABLE decanet.sysbasket
    (STUDSGRP_ID INT NOT NULL,
     PRIMARY KEY (STUDSGRP_ID));
  SELECT CONNECTION_ID() AS CONN_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_INIT TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.BASKET_DONE $$
CREATE PROCEDURE decanet.BASKET_DONE()
COMMENT 'ADZSV'
BEGIN
  DROP TEMPORARY TABLE IF EXISTS decanet.sysbasket;
  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_DONE TO A,D,Z,S,V $$

-- ##SSG
DROP PROCEDURE IF EXISTS decanet.BASKET_ADD $$
CREATE PROCEDURE decanet.BASKET_ADD(IN CONN_ID INT, IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    REPLACE INTO decanet.sysbasket(STUDSGRP_ID)
      VALUES (SSG_ID);
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_ADD TO A,D,Z,S,V $$

-- ##SSG
DROP PROCEDURE IF EXISTS decanet.BASKET_DEL $$
CREATE PROCEDURE decanet.BASKET_DEL(IN CONN_ID INT, IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    DELETE FROM decanet.sysbasket
      WHERE STUDSGRP_ID = SSG_ID;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_DEL TO A,D,Z,S,V $$


DROP PROCEDURE IF EXISTS decanet.BASKET_CNT $$
CREATE PROCEDURE decanet.BASKET_CNT(IN CONN_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    SELECT COUNT(STUDSGRP_ID) AS CNT
      FROM decanet.sysbasket;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_CNT TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.BASKET_LST $$
CREATE PROCEDURE decanet.BASKET_LST(IN CONN_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    SELECT C.COUNTRY_ID, N.REGION_ID, Y.CITY_ID, H.SCHOOL_ID, F.FACULTET_ID,
           V.DIVISION_ID, V.DIVISION_ABBR,
           FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
           G.SGROUP_ID, SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
           SG.STUDSGRP_ID, S.STUDENT_ID, E.EDUFORM_ABBR, S.STUDENT_PERSNO, S.STUDENT_ZACHNO,
           S.STUDENT_STRAHNO, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
           FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
      FROM decanet.sysbasket B LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.student S USING (STUDENT_ID) LEFT JOIN
           decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
           decanet.facultet F USING (FACULTET_ID) LEFT JOIN
           decanet.school H USING (SCHOOL_ID) LEFT JOIN
           decanet.city Y USING (CITY_ID) LEFT JOIN
           decanet.region N USING (REGION_ID) LEFT JOIN
           decanet.country C USING (COUNTRY_ID)
      ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
               C.COUNTRY_ABBR, N.REGION_NAME, Y.CITY_NAME,
               H.SCHOOL_ABBR, F.FACULTET_ABBR, V.DIVISION_ABBR, G.SGROUP_ID;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ II. ПОДСИСТЕМА НСД
-- ---------------------------------------------------------------------------------------------------

-- логин в ДекаNet
-- это вызывает guest@localhost
DROP PROCEDURE IF EXISTS decanet.GETRUINFO $$
CREATE PROCEDURE decanet.GETRUINFO(IN DN VARCHAR(255), IN DP VARCHAR(50))
BEGIN
  SELECT DUSER_ID, MANAGERTYPE_NAME, DUSER_FNAME, DUSER_MNAME, DUSER_LNAME,
         DECODE(UNHEX(BUNAME), 'GoNdUrAs') AS BUNAME,
         DECODE(UNHEX(BUPASS), 'PaRaGuWaY') AS BUPASS,
         DECODE(UNHEX(DUSER_2FA), 'PaRaGuWaY') AS DU_2FA,
         DESIGN_ID,
         COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    FROM decanet.duser LEFT JOIN decanet.managertype USING (MANAGERTYPE_ID)
    WHERE (DUNAME = DN) AND (DUPASS = MD5(DP)) LIMIT 1;
END $$

-- test существование логина
DROP PROCEDURE IF EXISTS decanet.LOGINEXISTS $$
CREATE PROCEDURE decanet.LOGINEXISTS(IN DNAME VARCHAR(255))
COMMENT 'A'
BEGIN
  SELECT DUNAME
    FROM decanet.duser
    WHERE UPPER(TRIM(DUNAME)) = UPPER(TRIM(DNAME));
END $$
GRANT EXECUTE ON PROCEDURE decanet.LOGINEXISTS TO A $$

-- создание пользователя
DROP PROCEDURE IF EXISTS decanet.CREATEUSER $$
CREATE PROCEDURE decanet.CREATEUSER(IN MANTYPE INT,
                                    IN DNAME VARCHAR(255), IN DPASS VARCHAR(50),
                                    IN BNAME VARCHAR(255), IN BPASS VARCHAR(50),
                                    IN FN VARCHAR(50), IN MN VARCHAR(50), IN LN VARCHAR(50),
                                    IN DsID INT,
                                    IN CnID INT, IN RgID INT, IN CtID INT, IN ScID INT,
                                    IN FcID INT, IN DvID INT, IN GrID INT, IN StID INT)
BEGIN
  DECLARE UID INT;
  DECLARE MTROLE VARCHAR(25);

  -- DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  DELETE FROM decanet.duser
    WHERE DUNAME = DNAME;

  INSERT INTO decanet.duser (DUSER_ID, MANAGERTYPE_ID, DUSER_FNAME, DUSER_MNAME, DUSER_LNAME,
                             DUNAME, DUPASS, BUNAME, BUPASS,
                             DESIGN_ID,
                             COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID,
                             DIVISION_ID, SGROUP_ID, STUDENT_ID)
    VALUES(NULL, MANTYPE, FN, MN, LN,
           DNAME,
           MD5(DPASS),
           HEX(ENCODE(BNAME, 'GoNdUrAs')),
           HEX(ENCODE(BPASS, 'PaRaGuWaY')),
           DsID,
           CnID, RgID, CtID, ScID, FcID, DvID, GrID, StID);

  SET UID = LAST_INSERT_ID();

  -- CREATE OR REPLACE user
  SET @dcsql = CONCAT('CREATE OR REPLACE USER ', '\'', BNAME, '\'@\'localhost\'', ' IDENTIFIED BY ', '\'', BPASS, '\'');
  PREPARE dcstmt FROM @dcsql;
  EXECUTE dcstmt;
  SET @dcsql = CONCAT('GRANT USAGE ON decanet.* TO ', '\'', BNAME, '\'@\'localhost\'');
  PREPARE dcstmt FROM @dcsql;
  EXECUTE dcstmt;

  SELECT MT.MANAGERTYPE_ABBR
    INTO MTROLE
    FROM decanet.managertype MT
    WHERE MT.MANAGERTYPE_ID = MANTYPE;

  CALL NSD_SET_DUSER_ROLE(BNAME, MTROLE);

  DEALLOCATE PREPARE dcstmt;

/*
  -- создаем пользователя MySQL
  REPLACE INTO MYSQL.USER
    VALUES('localhost', BNAME, PASSWORD(BPASS),
           'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N',
           'N','N','N','N','N','N','N','N', '', '', '', '', 0, 0, 0, 0);
*/

  -- это по системе привилегий по комменту к процедуре
  -- CALL decanet.SETDUSERACCESS(UID, MANTYPE);

  -- FLUSH PRIVILEGES;

  -- возвращаем ID пользователя или 0
  SELECT UID AS RES;
END $$


-- obsolete
-- служебная - ПРОПИСЫВАЕМ ДОСТУП по системе комментариев к процедурам -> пользователям
DROP PROCEDURE IF EXISTS decanet.SETDUSERACCESS $$
/*
CREATE PROCEDURE decanet.SETDUSERACCESS(IN UID INT, IN MANTYPE INT)
BEGIN
  DECLARE BNAME VARCHAR(255);
  DECLARE MT_ABBR VARCHAR(25);
  DECLARE done INT DEFAULT 0;
  DECLARE N VARCHAR(64);
  DECLARE C VARCHAR(64);
  -- DECLARE cRE CURSOR FOR SELECT NAME, COMMENT FROM MYSQL.PROC WHERE DB = 'decanet' AND TYPE = 'PROCEDURE';
  DECLARE cRE CURSOR FOR SELECT ROUTINE_NAME, ROUTINE_COMMENT FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'decanet' AND ROUTINE_TYPE = 'PROCEDURE';
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  SET BNAME = (SELECT DECODE(UNHEX(BUNAME), 'GoNdUrAs') FROM decanet.duser WHERE DUSER_ID = UID);

--  DELETE FROM MYSQL.PROCS_PRIV
--    WHERE USER = SUBSTRING_INDEX(BNAME,'@',1) AND
--          HOST = 'localhost' AND
--          DB = 'decanet';

  SET MT_ABBR = (SELECT MANAGERTYPE_ABBR FROM decanet.managertype WHERE MANAGERTYPE_ID = MANTYPE);

  OPEN cRE;
  REPEAT
    FETCH cRE INTO N, C;
    IF NOT done THEN
      IF LOCATE(MT_ABBR, C) THEN -- анализ доступа по COMMENT
         -- INSERT INTO MYSQL.PROCS_PRIV (HOST, DB, USER, ROUTINE_NAME, ROUTINE_TYPE, GRANTOR, PROC_PRIV)
         --   VALUES('localhost', 'decanet', BNAME, N, 2, USER(), 'EXECUTE');

        -- syntax GRANT EXECUTE ON PROCEDURE decanet.GETRUINFO  TO `salnikov`@`localhost`
        SET @dcsql = CONCAT('GRANT EXECUTE ON PROCEDURE ', N, ' TO ', '\'', BNAME, '\'@\'localhost\'');
        PREPARE dcstmt FROM @dcsql;
        EXECUTE dcstmt;
      END IF;
    END IF;
  UNTIL done END REPEAT;
  CLOSE cRE;
  DEALLOCATE PREPARE dcstmt;
  -- SELECT 1 AS RES;
END $$
*/

-- НСД
-- назначение роли пользователю
DROP PROCEDURE IF EXISTS decanet.NSD_SET_DUSER_ROLE $$
CREATE PROCEDURE decanet.NSD_SET_DUSER_ROLE(IN BUNAME VARCHAR(255), IN UROLE VARCHAR(25))
BEGIN
  -- роль A - admin
  -- нужны GRANT всех ролей (DZSV) для user-ов с ролью A с возможностью предоставлять роли
  IF UROLE = 'A' THEN
    SET @dcsql_r = CONCAT('GRANT A TO \'', BUNAME, '\'@\'localhost\' WITH ADMIN OPTION');
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
    SET @dcsql_r = CONCAT('GRANT D TO \'', BUNAME, '\'@\'localhost\' WITH ADMIN OPTION');
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
    SET @dcsql_r = CONCAT('GRANT Z TO \'', BUNAME, '\'@\'localhost\' WITH ADMIN OPTION');
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
    SET @dcsql_r = CONCAT('GRANT S TO \'', BUNAME, '\'@\'localhost\' WITH ADMIN OPTION');
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
    SET @dcsql_r = CONCAT('GRANT V TO \'', BUNAME, '\'@\'localhost\' WITH ADMIN OPTION');
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
  ELSE  -- остальные роли
    SET @dcsql_r = CONCAT('GRANT ', UROLE, ' TO \'', BUNAME, '\'@\'localhost\'');
    -- SELECT @dcsql;
    PREPARE dcstmt_r FROM @dcsql_r;
    EXECUTE dcstmt_r;
  END IF;
 -- syntax SET DEFAULT ROLE { role | NONE } [ FOR user@host ]
  SET @dcsql_r = CONCAT('SET DEFAULT ROLE ', UROLE, ' FOR \'', BUNAME, '\'@\'localhost\'');
  -- SELECT @dcsql;
  PREPARE dcstmt_r FROM @dcsql_r;
  EXECUTE dcstmt_r;

   DEALLOCATE PREPARE dcstmt_r;
END $$


-- создание пользователя в интерфейсе decanet
DROP PROCEDURE IF EXISTS decanet.DUSER_ADD $$
CREATE PROCEDURE decanet.DUSER_ADD(IN MANTYPE INT,
                                   IN DNAME VARCHAR(255), IN DPASS VARCHAR(50),
                                   IN FN VARCHAR(50), IN MN VARCHAR(50), IN LN VARCHAR(50),
                                   IN DsID INT,
                                   IN CnID INT, IN RgID INT, IN CtID INT, IN ScID INT,
                                   IN FcID INT, IN DvID INT, IN GrID INT, IN StID INT)
COMMENT 'A'
BEGIN
  DECLARE BNAME VARCHAR(255);
  DECLARE BPASS VARCHAR(50);
  DECLARE I, UID INT;

  -- DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS UID;

  SET UID = NULL;
  SET UID = (SELECT DUSER_ID FROM decanet.duser WHERE DUNAME = DNAME);

  IF UID IS NULL THEN
    -- автоматически создаем БД юзера и пароль
    SET BNAME = '';
    SET I = 0;

    WHILE I < 16 DO
      SET BNAME = CONCAT(BNAME, CHAR(FLOOR(97 + (RAND() * 25))));
      SET I = I + 1;
    END WHILE;

    SET BPASS = '';
    SET I = 0;
    WHILE I < 20 DO
      SET BPASS = CONCAT(BPASS, CHAR(FLOOR(97 + (RAND() * 25))));
      SET I = I + 1;
    END WHILE;

    CALL decanet.CREATEUSER(MANTYPE, DNAME, DPASS, BNAME, BPASS, FN, MN, LN, DsID, CnID, RgID, CtID, ScID, FcID, DVID, GrID, StID);
  ELSE
    SELECT 0 AS UID;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_ADD TO A $$

-- изменение собственного пароля
DROP PROCEDURE IF EXISTS decanet.SELFPASS_CNG $$
CREATE PROCEDURE decanet.SELFPASS_CNG(IN OLDPASS VARCHAR(50), IN NEWPASS VARCHAR(50))
COMMENT 'ADZSV'
BEGIN
  DECLARE BPASS VARCHAR(50);
  DECLARE I, UID INT;
  DECLARE BN VARCHAR(255);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  IF MD5(OLDPASS) = (SELECT DUPASS FROM decanet.duser WHERE BUNAME = BN) THEN
    -- придумываем новый БД пароль
    SET BPASS = '';
    SET I = 0;
    WHILE I < 20 DO
      SET BPASS = CONCAT(BPASS, CHAR(FLOOR(97 + (RAND() * 25))));
      SET I = I + 1;
    END WHILE;


    -- поменяли пароль MySQL
    /*
    UPDATE MYSQL.USER
      SET PASSWORD = PASSWORD(BPASS)
      WHERE USER = SUBSTRING_INDEX(USER(),'@',1) AND
            HOST = 'localhost';
    */
    -- ALTER USER 'user-name'@'localhost' IDENTIFIED BY 'new_password'
    SET @dcsql = CONCAT('ALTER USER ', USER(), ' IDENTIFIED BY ', '\'', BPASS, '\'');
    PREPARE dcstmt FROM @dcsql;
    EXECUTE dcstmt;
    DEALLOCATE PREPARE dcstmt;

    -- FLUSH PRIVILEGES;

    -- поменяли пароль ДекаNet
    UPDATE decanet.duser
      SET DUPASS = MD5(NEWPASS),
          BUPASS = HEX(ENCODE(BPASS, 'PaRaGuWaY'))
      WHERE BUNAME = BN;

  SELECT 1 AS RES, BPASS AS NEWPASS;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SELFPASS_CNG TO A,D,Z,S,V $$


-- изменение чужого пароля
DROP PROCEDURE IF EXISTS decanet.DUSERPASS_CNG $$
CREATE PROCEDURE decanet.DUSERPASS_CNG(IN DUID INT, IN NEWPASS VARCHAR(50))
COMMENT 'A'
BEGIN
  DECLARE BPASS VARCHAR(50);
  DECLARE I, UID INT;
  DECLARE RBN, BN VARCHAR(255);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  SET BN = (SELECT BUNAME FROM decanet.duser WHERE DUSER_ID = DUID);
  SET RBN = DECODE(UNHEX(BN), 'GoNdUrAs');

  -- придумываем новый БД пароль
  SET BPASS = '';
  SET I = 0;
  WHILE I < 20 DO
    SET BPASS = CONCAT(BPASS, CHAR(FLOOR(97 + (RAND() * 25))));
    SET I = I + 1;
  END WHILE;

  -- поменяли пароль MySQL
  /*
  UPDATE MYSQL.USER SET PASSWORD = PASSWORD(BPASS)
    WHERE USER = RBN AND HOST = 'localhost';
  FLUSH PRIVILEGES;
  */
    -- ALTER USER 'user-name'@'localhost' IDENTIFIED BY 'new_password'
  SET @dcsql = CONCAT('ALTER USER \'', RBN, '\'@\'localhost\'', ' IDENTIFIED BY ', '\'', BPASS, '\'');
  PREPARE dcstmt FROM @dcsql;
  EXECUTE dcstmt;
  DEALLOCATE PREPARE dcstmt;

  -- поменяли пароль ДекаNet
  UPDATE decanet.duser
    SET DUPASS = MD5(NEWPASS),
        BUPASS = HEX(ENCODE(BPASS, 'PaRaGuWaY'))
    WHERE BUNAME = BN;

  SELECT 1 AS RES, BPASS AS NEWPASS;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSERPASS_CNG TO A $$


-- установка 2FA ключа
DROP PROCEDURE IF EXISTS decanet.DUSER2FASEC_CNG $$
CREATE PROCEDURE decanet.DUSER2FASEC_CNG(IN DUID INT, IN _2FASEC VARCHAR(50))
COMMENT 'A'
BEGIN

  -- поменяли 2fa ключ
  UPDATE decanet.duser
    SET DUSER_2FA = HEX(ENCODE(_2FASEC, 'PaRaGuWaY'))
    WHERE DUSER_ID = DUID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER2FASEC_CNG TO A $$


-- удаление пользователя
DROP PROCEDURE IF EXISTS decanet.DUSER_DEL $$
CREATE PROCEDURE decanet.DUSER_DEL(IN UID INT)
COMMENT 'A'
BEGIN
  DECLARE BNAME VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  SET BNAME = (SELECT BUNAME FROM decanet.duser WHERE DUSER_ID = UID);

  DELETE FROM decanet.duser WHERE DUSER_ID = UID;

  -- DELETE FROM MYSQL.PROCS_PRIV WHERE USER = BNAME;
  -- DELETE FROM MYSQL.USER WHERE USER = BNAME;
  -- FLUSH PRIVILEGES;
  SET @dcsql = CONCAT('DROP USER \'', BNAME, '\'@\'localhost\'');
  PREPARE dcstmt FROM @dcsql;
  EXECUTE dcstmt;
  DEALLOCATE PREPARE dcstmt;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_DEL TO A $$

-- получить параметры пользователя
DROP PROCEDURE IF EXISTS decanet.DUSER_ITM $$
CREATE PROCEDURE decanet.DUSER_ITM(IN UID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT MANAGERTYPE_ID, DUNAME,
         DUSER_FNAME, DUSER_MNAME, DUSER_LNAME,
         DUSER_PHONE1, DUSER_PHONE2, DUSER_EMAIL, DUSER_ICQ,
         DESIGN_ID, COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID,
     FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID,
     DUSER_DESC, DUSER_2FA IS NOT NULL AS DUSER_2FA_EXISTS
   FROM decanet.duser
   WHERE DUSER_ID = UID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_ITM TO A,D,Z,S,V $$

/*
-- получить 2FA ключ пользователя
DROP PROCEDURE IF EXISTS decanet.DUSER_2FA $$
CREATE PROCEDURE decanet.DUSER_2FA(IN UID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DUSER_ID, DECODE(UNHEX(DUSER_2FA), 'PaRaGuWaY') AS DU_2FA
   FROM decanet.duser
   WHERE DUSER_ID = UID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_2FA TO A,D,Z,S,V $$
*/


-- сброить 2FA ключ пользователя
DROP PROCEDURE IF EXISTS decanet.DUSER_2FA_DEL $$
CREATE PROCEDURE decanet.DUSER_2FA_DEL(IN DUID INT)
COMMENT 'A'
BEGIN
    -- поменяли 2fa ключ
  UPDATE decanet.duser
    SET DUSER_2FA = NULL
    WHERE DUSER_ID = DUID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_2FA_DEL TO A $$


-- изменить параметры пользователя
DROP PROCEDURE IF EXISTS decanet.DUSER_CNG $$
CREATE PROCEDURE decanet.DUSER_CNG(IN UID INT,
                                   IN MtID INT,
                                   IN FN VARCHAR(50),
                                   IN MN VARCHAR(50),
                                   IN LN VARCHAR(50),
                                   IN PHN1 VARCHAR(15),
                                   IN PHN2 VARCHAR(15),
                                   IN EM VARCHAR(100),
                                   IN ICQ VARCHAR(15),
                                   -- IN DN VARCHAR(255),
                                   -- IN DP VARCHAR(255),
                                   IN DsID INT, IN CnID INT, IN RgID INT, IN CtID INT, IN ScID INT,
                                   IN FcID INT, IN DvID INT, IN GrID INT, IN StID INT,
                                   IN UDesc TINYTEXT)
COMMENT 'A'
BEGIN

  DECLARE BNAME VARCHAR(255);
  DECLARE MTROLE VARCHAR(25);

  UPDATE decanet.duser
    SET MANAGERTYPE_ID = MtID,
        DUSER_FNAME = FN,
        DUSER_MNAME = MN,
        DUSER_LNAME = LN,
        DUSER_PHONE1 = PHN1,
        DUSER_PHONE2 = PHN2,
        DUSER_EMAIL = EM,
        DUSER_ICQ = ICQ,
       -- DUNAME = DN,
        DESIGN_ID = DsID,
        COUNTRY_ID = CnID,
        REGION_ID = RgID,
        CITY_ID = CtID,
        SCHOOL_ID = ScID,
        FACULTET_ID = FcID,
        DIVISION_ID = DvID,
        SGROUP_ID = GrID,
        STUDENT_ID = StID,
        DUSER_DESC = UDesc
   WHERE DUSER_ID = UID;

  -- CALL decanet.duserpass_cng (UID, DP);
  -- obsolete
  -- CALL decanet.SETDUSERACCESS(UID, MtID);

  SELECT DECODE(UNHEX(U.BUNAME), 'GoNdUrAs'), MT.MANAGERTYPE_ABBR
    INTO BNAME, MTROLE
    FROM decanet.duser U LEFT JOIN
         decanet.managertype MT USING (MANAGERTYPE_ID)
    WHERE U.DUSER_ID = UID;

  CALL NSD_SET_DUSER_ROLE(BNAME, MTROLE);

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_CNG TO A $$

-- кол-во пользователей (работаем только в пределах своих ограничений)
DROP PROCEDURE IF EXISTS decanet.DUSER_CNT $$
CREATE PROCEDURE decanet.DUSER_CNT()
COMMENT 'A'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

    SELECT COUNT(U.DUSER_ID) AS CNT
    FROM decanet.duser U
    WHERE IF(CNT_ID IS NULL, TRUE, U.COUNTRY_ID = CNT_ID) AND
          IF(REG_ID IS NULL, TRUE, U.REGION_ID = REG_ID) AND
          IF(CTY_ID IS NULL, TRUE, U.CITY_ID = CTY_ID) AND
          IF(SCH_ID IS NULL, TRUE, U.SCHOOL_ID = SCH_ID) AND
          IF(FAC_ID IS NULL, TRUE, U.FACULTET_ID = FAC_ID) AND
          IF(DIV_ID IS NULL, TRUE, U.DIVISION_ID = DIV_ID) AND
          IF(SGR_ID IS NULL, TRUE, U.SGROUP_ID = SGR_ID) AND
          IF(STD_ID IS NULL, TRUE, U.STUDENT_ID = STD_ID);
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_CNT TO A $$


-- список пользователей (работаем только в пределах своих ограничений)
DROP PROCEDURE IF EXISTS decanet.DUSER_LST $$
CREATE PROCEDURE decanet.DUSER_LST(IN NMASK VARCHAR(50))
COMMENT 'A'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  IF NOT LOCATE('%', NMASK) THEN
    SET NMASK = CONCAT('%', NMASK, '%');
  END IF;


  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

    SELECT U.DUSER_ID, U.DUNAME,
           U.DUSER_FNAME, U.DUSER_MNAME, U.DUSER_LNAME, M.MANAGERTYPE_NAME,
           U.DUSER_2FA IS NOT NULL AS DUSER_2FA_EXISTS
      FROM decanet.duser U LEFT JOIN
           decanet.managertype M USING (MANAGERTYPE_ID)
      WHERE IF(CNT_ID IS NULL, TRUE, U.COUNTRY_ID = CNT_ID) AND
            IF(REG_ID IS NULL, TRUE, U.REGION_ID = REG_ID) AND
            IF(CTY_ID IS NULL, TRUE, U.CITY_ID = CTY_ID) AND
            IF(SCH_ID IS NULL, TRUE, U.SCHOOL_ID = SCH_ID) AND
            IF(FAC_ID IS NULL, TRUE, U.FACULTET_ID = FAC_ID) AND
            IF(DIV_ID IS NULL, TRUE, U.DIVISION_ID = DIV_ID) AND
            IF(SGR_ID IS NULL, TRUE, U.SGROUP_ID = SGR_ID) AND
            IF(STD_ID IS NULL, TRUE, U.STUDENT_ID = STD_ID) AND
            IF(NMASK IS NULL, TRUE, (DUNAME LIKE NMASK OR DUSER_LNAME LIKE NMASK))
      ORDER BY U.DUSER_LNAME, U.DUSER_FNAME, U.DUSER_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DUSER_LST TO A $$


/*
-- список пользователей (работаем только в пределах своих ограничений)
-- CТАРЫЙ ВАРИАНТ
DROP PROCEDURE IF EXISTS decanet.duser_LST $$
CREATE PROCEDURE decanet.duser_LST()
COMMENT 'A'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

    SELECT U.DUSER_ID, U.DUNAME,
           U.DUSER_FNAME, U.DUSER_MNAME, U.DUSER_LNAME, M.MANAGERTYPE_NAME
      FROM decanet.duser U LEFT JOIN
           decanet.managertype M USING (MANAGERTYPE_ID)
      WHERE IF(CNT_ID IS NULL, TRUE, U.COUNTRY_ID = CNT_ID) AND
            IF(REG_ID IS NULL, TRUE, U.REGION_ID = REG_ID) AND
            IF(CTY_ID IS NULL, TRUE, U.CITY_ID = CTY_ID) AND
            IF(SCH_ID IS NULL, TRUE, U.SCHOOL_ID = SCH_ID) AND
            IF(FAC_ID IS NULL, TRUE, U.FACULTET_ID = FAC_ID) AND
            IF(DIV_ID IS NULL, TRUE, U.DIVISION_ID = DIV_ID) AND
            IF(SGR_ID IS NULL, TRUE, U.SGROUP_ID = SGR_ID) AND
            IF(STD_ID IS NULL, TRUE, U.STUDENT_ID = STD_ID)
      ORDER BY U.DUSER_LNAME, U.DUSER_FNAME, U.DUSER_MNAME;
END $$
*/

-- =========================================================== нсд

-- кол-во схем оформления
DROP PROCEDURE IF EXISTS decanet.DESIGN_CNT $$
CREATE PROCEDURE decanet.DESIGN_CNT()
COMMENT 'A'
BEGIN
  SELECT COUNT(DESIGN_ID) AS CNT
    FROM decanet.design;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DESIGN_CNT TO A $$

-- список схем оформления
DROP PROCEDURE IF EXISTS decanet.DESIGN_LST $$
CREATE PROCEDURE decanet.DESIGN_LST()
COMMENT 'A'
BEGIN
  SELECT *
    FROM decanet.design
    ORDER BY DESIGN_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DESIGN_LST TO A $$

-- параметры схемы оформления
DROP PROCEDURE IF EXISTS decanet.DESIGN_ITM $$
CREATE PROCEDURE decanet.DESIGN_ITM(IN DES_ID INT)
COMMENT 'A'
BEGIN
  SELECT *
    FROM decanet.design
    WHERE DESIGN_ID = DES_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DESIGN_ITM TO A $$

-- смена дизайна
DROP PROCEDURE IF EXISTS decanet.UDESIGN_CNG $$
CREATE PROCEDURE decanet.UDESIGN_CNG(IN UID INT, IN DsID INT)
COMMENT 'A'
BEGIN
  UPDATE decanet.duser
    SET DESIGN_ID = DsID
    WHERE DUSER_ID = UID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.UDESIGN_CNG TO A $$

-- кол-во типов пользователей
DROP PROCEDURE IF EXISTS decanet.MANTYPE_CNT $$
CREATE PROCEDURE decanet.MANTYPE_CNT()
COMMENT 'A'
BEGIN
  SELECT COUNT(MANAGERTYPE_ID) AS CNT
    FROM decanet.managertype;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MANTYPE_CNT TO A $$

-- список типов пользователей
DROP PROCEDURE IF EXISTS decanet.MANTYPE_LST $$
CREATE PROCEDURE decanet.MANTYPE_LST()
COMMENT 'A'
BEGIN
  SELECT *
    FROM decanet.managertype
    ORDER BY MANAGERTYPE_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MANTYPE_LST TO A $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ III. ОБЪЕКТЫ ПОДСИСТЕМЫ ВЫБОРА
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . СТРАНЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во стран
DROP PROCEDURE IF EXISTS decanet.COUNTRY_CNT $$
CREATE PROCEDURE decanet.COUNTRY_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(COUNTRY_ID) AS CNT
    FROM decanet.country;
END $$
GRANT EXECUTE ON PROCEDURE decanet.COUNTRY_CNT TO A,D,Z,S,V $$

-- список стран
DROP PROCEDURE IF EXISTS decanet.COUNTRY_LST $$
CREATE PROCEDURE decanet.COUNTRY_LST(IN EARTH_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNTRY_ID, COUNTRY_ABBR, COUNTRY_SNAME, COUNTRY_BNAME
    FROM decanet.country
    ORDER BY COUNTRY_SNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.COUNTRY_LST TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.COUNTRY_ITM $$
CREATE PROCEDURE decanet.COUNTRY_ITM(IN CNT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNTRY_ID, COUNTRY_ABBR, COUNTRY_SNAME, COUNTRY_BNAME
    FROM decanet.country
    WHERE COUNTRY_ID = CNT_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.COUNTRY_ITM TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . РЕГИОНЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во регионов
DROP PROCEDURE IF EXISTS decanet.REGION_CNT $$
CREATE PROCEDURE decanet.REGION_CNT(IN CNT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(REGION_ID) AS CNT FROM decanet.region
    WHERE COUNTRY_ID = CNT_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.REGION_CNT TO A,D,Z,S,V $$

-- список регионов
DROP PROCEDURE IF EXISTS decanet.REGION_LST $$
CREATE PROCEDURE decanet.REGION_LST(IN CNT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT REGION_ID, REGION_NAME FROM
    decanet.region WHERE COUNTRY_ID = CNT_ID
    ORDER BY REGION_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.REGION_LST TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.REGION_ITM $$
CREATE PROCEDURE decanet.REGION_ITM(IN REG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT REGION_ID, REGION_NAME
    FROM decanet.region
    WHERE REGION_ID = REG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.REGION_ITM TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ГОРОДА
-- ---------------------------------------------------------------------------------------------------

-- кол-во городов
DROP PROCEDURE IF EXISTS decanet.CITY_CNT $$
CREATE PROCEDURE decanet.CITY_CNT(IN REG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(CITY_ID) AS CNT
    FROM decanet.city
    WHERE REGION_ID = REG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CITY_CNT TO A,D,Z,S,V $$

-- список городов
DROP PROCEDURE IF EXISTS decanet.CITY_LST $$
CREATE PROCEDURE decanet.CITY_LST(IN REG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT CITY_ID, CITY_NAME
    FROM decanet.city
    WHERE REGION_ID = REG_ID
    ORDER BY CITY_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CITY_LST TO A,D,Z,S,V $$

-- кол-во всех городов
DROP PROCEDURE IF EXISTS decanet.ALLCITY_CNT $$
CREATE PROCEDURE decanet.ALLCITY_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(CITY_ID) AS CNT
    FROM decanet.city;
END $$
GRANT EXECUTE ON PROCEDURE decanet.ALLCITY_CNT TO A,D,Z,S,V $$

-- список всех городов
DROP PROCEDURE IF EXISTS decanet.ALLCITY_LST $$
CREATE PROCEDURE decanet.ALLCITY_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT C.CITY_ID, CONCAT(C.CITY_NAME, ' (', R.REGION_NAME, ')') AS CITY_NAME
    FROM decanet.city C LEFT JOIN
         decanet.region R USING (REGION_ID)
    ORDER BY C.CITY_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.ALLCITY_LST TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.CITY_ITM $$
CREATE PROCEDURE decanet.CITY_ITM(IN CIT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT CITY_ID, CITY_NAME
    FROM decanet.city
    WHERE CITY_ID = CIT_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.CITY_ITM TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ВУЗЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во ВУЗов
DROP PROCEDURE IF EXISTS decanet.SCHOOL_CNT $$
CREATE PROCEDURE decanet.SCHOOL_CNT(IN CIT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(SCHOOL_ID) AS CNT
    FROM decanet.school
    WHERE CITY_ID = CIT_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_CNT TO A,D,Z,S,V $$

-- список ВУЗов
DROP PROCEDURE IF EXISTS decanet.SCHOOL_LST $$
CREATE PROCEDURE decanet.SCHOOL_LST(IN CIT_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SCHOOL_ID, SCHOOL_ABBR, SCHOOL_NAME
    FROM decanet.school
    WHERE CITY_ID = CIT_ID
    ORDER BY SCHOOL_ABBR;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_LST TO A,D,Z,S,V $$

-- строка ВУЗа
DROP PROCEDURE IF EXISTS decanet.SCHOOL_ITM $$
CREATE PROCEDURE decanet.SCHOOL_ITM(IN SCH_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT H.SCHOOL_ID, C.CITY_NAME, H.SCHOOL_DEPT, H.SCHOOL_ABBR, H.SCHOOL_NAME,
         H.SCHOOL_STREET, H.SCHOOL_BLDNO, H.SCHOOL_OFFNO, H.SCHOOL_DESC,
         P.PERSON_FNAME, P.PERSON_MNAME, P.PERSON_LNAME
    FROM decanet.school H LEFT JOIN
         decanet.person P USING (PERSON_ID) LEFT JOIN
         decanet.city C USING (CITY_ID)
    WHERE H.SCHOOL_ID = SCH_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_ITM TO A,D,Z,S,V $$

-- добавить ВУЗ
DROP PROCEDURE IF EXISTS decanet.SCHOOL_ADD $$
CREATE PROCEDURE decanet.SCHOOL_ADD(IN CITYID INT,
                                    IN SDEPT VARCHAR(255),
                                    IN SABBR VARCHAR(25),
                                    IN SNAME VARCHAR(255),
                                    IN SSTREET VARCHAR(100),
                                    IN SBNO VARCHAR(10),
                                    IN SOFNO VARCHAR(10),
                                    IN SDESC TINYTEXT,
                                    IN RFNAME VARCHAR(50),
                                    IN RMNAME VARCHAR(50),
                                    IN RLNAME VARCHAR(50))
COMMENT 'A'
BEGIN
  DECLARE RID INT;

  INSERT INTO decanet.person(PERSON_ID, PERSTATUS_ID, PERSON_FNAME, PERSON_MNAME, PERSON_LNAME)
    VALUES (NULL, 1, RFNAME, RMNAME, RLNAME);

  SET RID = Last_Insert_ID();

  INSERT INTO decanet.school(SCHOOL_ID, CITY_ID, PERSON_ID, SCHOOL_DEPT, SCHOOL_ABBR, SCHOOL_NAME, SCHOOL_STREET, SCHOOL_BLDNO, SCHOOL_OFFNO, SCHOOL_DECS)
    VALUES (NULL, CITYID, RID, SDEPT, SABBR, SNAME, SSTREET, SBNO, SOFNO, SDESC);

  SELECT Last_Insert_ID() AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_ADD TO A $$

DROP PROCEDURE IF EXISTS decanet.SCHOOL_CNG $$
CREATE PROCEDURE decanet.SCHOOL_CNG(IN SID INT,
                                    IN SDEPT VARCHAR(255),
                                    IN SABBR VARCHAR(25),
                                    IN SNAME VARCHAR(255),
                                    IN SSTREET VARCHAR(100),
                                    IN SBNO VARCHAR(10),
                                    IN SOFNO VARCHAR(10),
                                    IN SDESC TINYTEXT,
                                    IN RFNAME VARCHAR(50),
                                    IN RMNAME VARCHAR(50),
                                    IN RLNAME VARCHAR(50))
COMMENT 'A'
BEGIN
  UPDATE decanet.school S LEFT JOIN
         decanet.person P USING (PERSON_ID)
    SET P.PERSON_FNAME = RFNAME,
        P.PERSON_MNAME = MFNAME,
        P.PERSON_LNAME = LFNAME
    WHERE S.SCHOOL_ID = SID;

  UPDATE decanet.school
    SET SCHOOL_DEPT = SDEPT,
        SCHOOL_ABBR = SABBR,
        SCHOOL_NAME = SNAME,
        SCHOOL_STREET = SSTREET,
        SCHOOL_BLDNO = SBNO,
        SCHOOL_OFFNO = SOFNO,
        SCHOOL_DECS = SDESC
    WHERE S.SCHOOL_ID = SID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_CNG TO A $$

DROP PROCEDURE IF EXISTS decanet.SCHOOL_DEL $$
CREATE PROCEDURE decanet.SCHOOL_DEL(IN SID INT)
COMMENT 'A'
BEGIN
  SET FOREIGN_KEY_CHECKS = 0;

  -- multidelete syntax
  DELETE decanet.school, decanet.person
    FROM decanet.school LEFT JOIN
         decanet.person USING (PERSON_ID)
    WHERE SCHOOL_ID = SID;

  SET FOREIGN_KEY_CHECKS = 1;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SCHOOL_DEL TO A $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ФАКУЛЬТEТЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во факультетов
DROP PROCEDURE IF EXISTS decanet.FACULTET_CNT $$
CREATE PROCEDURE decanet.FACULTET_CNT(IN SCH_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(FACULTET_ID) AS CNT
    FROM decanet.facultet
    WHERE SCHOOL_ID = SCH_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FACULTET_CNT TO A,D,Z,S,V $$

-- список факультетов
DROP PROCEDURE IF EXISTS decanet.FACULTET_LST $$
CREATE PROCEDURE decanet.FACULTET_LST(IN SCH_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT FACULTET_ID, FACULTET_ABBR, FACULTET_NAME
    FROM decanet.facultet
    WHERE SCHOOL_ID = SCH_ID
    ORDER BY FACULTET_ABBR;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FACULTET_LST TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.FACULTET_ITM $$
CREATE PROCEDURE decanet.FACULTET_ITM (IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT F.FACULTET_ID, F.FACULTET_ABBR, F.FACULTET_NAME, FET.EDUTYPE_ABBR, FET.EDUTYPE_NAME
    FROM decanet.facultet F LEFT JOIN
         decanet.edutype FET USING (EDUTYPE_ID)
    WHERE F.FACULTET_ID = FAC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FACULTET_ITM TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ОТДЕЛЕНИЯ
-- ---------------------------------------------------------------------------------------------------

-- отделение активно (есть хоть один активный студент)
DROP FUNCTION IF EXISTS FDIVISION_ACTIVE $$
CREATE FUNCTION FDIVISION_ACTIVE(DIV_ID INT) RETURNS tinyint(1)
BEGIN
  DECLARE DSTAT BOOL;

  SET DSTAT = NULL;

  SELECT D.DIVISION_ID
    INTO DSTAT
  FROM division D LEFT JOIN
       stream S USING (DIVISION_ID) LEFT JOIN
       sgroup SG USING (STREAM_ID) LEFT JOIN
       studsgrp SSG ON SSG.SGROUP_ID = SG.SGROUP_ID AND FSTUDENT_ACTIVE(SSG.STUDSGRP_ID)
  WHERE D.DIVISION_ID = DIV_ID AND
        SSG.STUDSGRP_ID IS NOT NULL
  LIMIT 1;

  RETURN IFNULL(DSTAT, 0)>0;
END $$


-- кол-во отделений
DROP PROCEDURE IF EXISTS decanet.DIVISION_CNT $$
CREATE PROCEDURE decanet.DIVISION_CNT(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DIVISION_ID) AS CNT
    FROM decanet.division
    WHERE FACULTET_ID = FAC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_CNT TO A,D,Z,S,V $$

/*
-- список отделений
DROP PROCEDURE IF EXISTS decanet.DIVISION_LST $$
CREATE PROCEDURE decanet.DIVISION_LST(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DIVISION_ID, DIVISION_ABBR, DIVISION_NAME
    FROM decanet.division
    WHERE FACULTET_ID = FAC_ID
    ORDER BY DIVISION_ABBR;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_LST TO A,D,Z,S,V $$
*/

-- кол-во отделений
DROP PROCEDURE IF EXISTS decanet.DIVISION_ACNT $$
CREATE PROCEDURE decanet.DIVISION_ACNT(IN FAC_ID INT, IN DIVACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DIVISION_ID) AS CNT
    FROM decanet.division
    WHERE FACULTET_ID = FAC_ID AND
          IF(ACTIVE IS NULL, TRUE, FDIVISION_ACTIVE(DIVISION_ID) = ACTIVE);
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_ACNT TO A,D,Z,S,V $$

/*
-- список отделений
DROP PROCEDURE IF EXISTS decanet.DIVISION_LST $$
CREATE PROCEDURE decanet.DIVISION_LST(IN FAC_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT DIVISION_ID, DIVISION_ABBR, DIVISION_NAME, FDIVISION_ACTIVE(DIVISION_ID) AS DIVISION_ACTIVE
    FROM decanet.division
    WHERE FACULTET_ID = FAC_ID AND
          IF(ACTIVE IS NULL, TRUE, FDIVISION_ACTIVE(DIVISION_ID) = ACTIVE)
    ORDER BY DIVISION_ABBR;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_LST TO A,D,Z,S,V $$
*/

-- список отделений
DROP PROCEDURE IF EXISTS decanet.DIVISION_LST $$
CREATE PROCEDURE decanet.DIVISION_LST (IN FAC_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN

  DROP TEMPORARY TABLE IF EXISTS decanet.ttstudstat;
  CREATE TEMPORARY TABLE decanet.ttstudstat AS
      SELECT STUDENT_ID, STUDSGRP_ID, V.DIVISION_ID, T.STUDSTATUS_ACTIVE
      FROM decanet.contingent C LEFT JOIN
           decanet.studsgrp SSG USING (STUDSGRP_ID) LEFT JOIN
           decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
           decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
           decanet.document D USING (DOCUMENT_ID)
      WHERE V.FACULTET_ID = FAC_ID AND
            D.DOCUMENT_INDATE IS NOT NULL AND
            NOT D.DOCUMENT_TEMPFLAG
      ORDER BY STUDENT_ID, DOCUMENT_INDATE DESC, T.STUDSTATUS_ACTIVE DESC;

  CREATE INDEX IDX_TTSS ON decanet.ttstudstat(STUDENT_ID, STUDSGRP_ID);

  DROP TEMPORARY TABLE IF EXISTS decanet.ttstudactive;
  CREATE TEMPORARY TABLE decanet.ttstudactive AS
    SELECT * FROM ttstudstat
    GROUP BY STUDENT_ID, STUDSGRP_ID;

  CREATE INDEX IDX_TTSA ON decanet.ttstudactive(DIVISION_ID);

  SELECT V.DIVISION_ID, V.DIVISION_ABBR, V.DIVISION_NAME, MAX(SA.STUDSTATUS_ACTIVE) AS DIVISION_ACTIVE
    FROM division V LEFT JOIN
         decanet.ttstudactive SA USING (DIVISION_ID)
    WHERE V.FACULTET_ID = FAC_ID
    GROUP BY V.DIVISION_ID HAVING IF(ACTIVE IS NULL, TRUE, MAX(SA.STUDSTATUS_ACTIVE) = ACTIVE)
    ORDER BY V.DIVISION_ABBR;

END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_LST TO A,D,Z,S,V $$


DROP PROCEDURE IF EXISTS decanet.DIVISION_ITM $$
CREATE PROCEDURE decanet.DIVISION_ITM (IN DIV_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT D.DIVISION_ID, D.DIVISION_ABBR, D.DIVISION_NAME,
         I.GOSDIR_CODE, I.GOSDIR_NAME,
         T.GOSTITLE_ID, T.GOSTITLE_CODE, T.GOSTITLE_NAME,
         D.SUBSPEC_ID, B.SUBSPEC_CODE, B.SUBSPEC_NAME,
         D.EDUTYPE_ID, E.EDUTYPE_ABBR, E.EDUTYPE_NAME,
         D.DIVISION_UYEAR, D.DIVISION_HALFUYEAR, D.DIVISION_NPREFIX, D.DIVISION_ALGNO, D.DIVISION_DESC
    FROM decanet.division D LEFT JOIN
         decanet.gostitle T USING (GOSTITLE_ID) LEFT JOIN
         decanet.gosdir I USING (GOSDIR_ID) LEFT JOIN
         decanet.subspec B USING (SUBSPEC_ID) LEFT JOIN
         decanet.edutype E USING (EDUTYPE_ID)
    WHERE D.DIVISION_ID = DIV_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_ITM TO A,D,Z,S,V $$

-- добавление отделения
DROP PROCEDURE IF EXISTS decanet.DIVISION_ADD $$
CREATE PROCEDURE decanet.DIVISION_ADD (IN FAC_ID INT, IN GOST_ID INT, IN EDUT_ID INT, IN SSPEC_ID INT,
                                       IN DIVABBR VARCHAR(25), IN DIVNM VARCHAR(255), IN DIVUY INT, IN DIVHUY INT,
                                       IN DIVNMPFX VARCHAR(25), IN DIVALG INT, IN DIVDESC TINYTEXT)
COMMENT 'DZ'
BEGIN
  INSERT INTO decanet.division(FACULTET_ID, GOSTITLE_ID, EDUTYPE_ID, SUBSPEC_ID, DIVISION_ABBR, DIVISION_NAME,
                               DIVISION_UYEAR, DIVISION_HALFUYEAR, DIVISION_NPREFIX, DIVISION_ALGNO, DIVISION_DESC)
    VALUES (FAC_ID, GOST_ID, EDUT_ID, SSPEC_ID, DIVABBR, DIVNM, DIVUY, DIVHUY, DIVNMPFX, DIVALG, DIVDESC);

  SELECT Last_Insert_ID() AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_ADD TO D,Z $$

-- изменение отделения
DROP PROCEDURE IF EXISTS decanet.DIVISION_CNG $$
CREATE PROCEDURE decanet.DIVISION_CNG (IN DIV_ID INT,
                                       IN GOST_ID INT, IN EDUT_ID INT, IN SSPEC_ID INT,
                                       IN DIVABBR VARCHAR(25), IN DIVNM VARCHAR(255), IN DIVUY INT, IN DIVHUY INT,
                                       IN DIVNMPFX VARCHAR(25), IN DIVALG INT, IN DIVDESC TINYTEXT)
COMMENT 'DZ'
BEGIN
  UPDATE decanet.division
    SET GOSTITLE_ID = GOST_ID,
        EDUTYPE_ID = EDUT_ID,
        SUBSPEC_ID = SSPEC_ID,
        DIVISION_ABBR = DIVABBR,
        DIVISION_NAME = DIVNM,
        DIVISION_UYEAR = DIVUY,
        DIVISION_HALFUYEAR = DIVHUY,
        DIVISION_NPREFIX = DIVNMPFX,
        DIVISION_ALGNO = DIVALG,
        DIVISION_DESC = DIVDESC
    WHERE DIVISION_ID = DIV_ID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DIVISION_CNG TO D,Z $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ГРУППЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во групп
DROP PROCEDURE IF EXISTS decanet.SGROUP_CNT $$
CREATE PROCEDURE decanet.SGROUP_CNT(IN DIV_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(G.SGROUP_ID) AS CNT
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
    IF(ACTIVE IS NULL, TRUE, FSGROUP_ACTIVE(G.SGROUP_ID) = ACTIVE);
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUP_CNT TO A,D,Z,S,V $$

-- наименование группы
DROP FUNCTION IF EXISTS SGROUPAUTONAME $$
CREATE FUNCTION SGROUPAUTONAME(SGR_ID INT) RETURNS VARCHAR(50)
BEGIN
  DECLARE NI, DN, FA, DA, KURSC VARCHAR(25);
  DECLARE GAN VARCHAR(50);
  DECLARE DI, DS, DL, KURSN INT;
  DECLARE FY, UYEAR YEAR;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION RETURN '-'; -- SQL - ошибка

  IF SGR_ID IS NULL THEN
    RETURN '';
  END IF;

  SELECT F.FACULTET_ABBR, D.DIVISION_ID, D.DIVISION_ABBR, R.STREAM_SEMCOUNT, D.DIVISION_NPREFIX, D.DIVISION_ALGNO,
         G.SGROUP_NAMEINDEX, R.STREAM_FROMYEAR, GETUYEAR(DI, CURDATE())
    INTO FA, DI, DA, DS, DN, DL, NI, FY, UYEAR
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID)
    WHERE G.SGROUP_ID = SGR_ID LIMIT 1;

  -- SET UYEAR = GETUYEAR(DI, CURDATE());

  SET KURSN = UYEAR - FY + 1;

  IF KURSN > DS / 2 THEN
    SET KURSN = ROUND(DS / 2);
  END IF;

  SET KURSC = CAST(KURSN AS CHAR);

  IF KURSN < 1 THEN
    SET KURSC = '#';
  END IF;

  SET GAN = CASE DL
            WHEN 0 THEN
              CONCAT(FA, '-', DA, '-', KURSC, '-', CAST(NI AS CHAR))
            WHEN 1 THEN
              CONCAT(FA, '-', KURSC, CAST(NI AS CHAR))
            WHEN 2 THEN
              CONCAT(KURSC, RIGHT(CONCAT('00', CAST(NI AS CHAR)), 2))
            WHEN 3 THEN
              CONCAT(DN, '-', RIGHT(CAST(FY AS CHAR), 2), IF(NI='-', '', CONCAT('/', CAST(NI AS CHAR))))
            WHEN 4 THEN
              CONCAT(DN, '-', KURSC, NI)
            ELSE
              CONCAT(FA, '-', KURSC, CAST(NI AS CHAR))
            END;

  RETURN GAN;
END $$


-- список групп
DROP PROCEDURE IF EXISTS decanet.SGROUP_LST $$
CREATE PROCEDURE decanet.SGROUP_LST(IN DIV_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  DECLARE UYEAR YEAR;

  SET UYEAR = GETUYEAR(DIV_ID, CURDATE());

  SELECT G.SGROUP_ID, FSGROUP_ACTIVE(G.SGROUP_ID) AS SGROUP_ACTIVE,
         R.STREAM_FROMYEAR,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         (SELECT COUNT(STUDSGRP_ID) FROM decanet.studsgrp WHERE SGROUP_ID = G.SGROUP_ID) AS SCNT
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID)
    WHERE D.DIVISION_ID = DIV_ID AND
          IF(ACTIVE IS NULL, TRUE, FSGROUP_ACTIVE(G.SGROUP_ID) = ACTIVE)
    ORDER BY R.STREAM_FROMYEAR DESC, SGROUP_AUTONAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUP_LST TO A,D,Z,S,V $$

-- строка группы
DROP PROCEDURE IF EXISTS decanet.SGROUP_ITM $$
CREATE PROCEDURE decanet.SGROUP_ITM (IN SGR_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT G.SGROUP_ID,
         SGROUPAUTONAME(SGR_ID) AS SGROUP_AUTONAME,
         R.STREAM_FROMYEAR,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD
    FROM decanet.division D LEFT JOIN
         decanet.stream R USING (DIVISION_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGR_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUP_ITM TO A,D,Z,S,V $$

-- определение статуса группы
DROP FUNCTION IF EXISTS decanet.FSGROUP_ACTIVE $$
CREATE FUNCTION decanet.FSGROUP_ACTIVE(SGR_ID INT) RETURNS BOOL
BEGIN
  RETURN EXISTS (SELECT SG.STUDENT_ID
                   FROM decanet.studsgrp SG
                   WHERE SG.SGROUP_ID = SGR_ID AND
                         FSTUDENT_ACTIVE(SG.STUDSGRP_ID));
END $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . СТУДЕНТЫ
-- ---------------------------------------------------------------------------------------------------

-- кол-во студентов
DROP PROCEDURE IF EXISTS decanet.STUDENT_CNT $$
CREATE PROCEDURE decanet.STUDENT_CNT(IN SGRP_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(SG.STUDENT_ID) AS CNT
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                 C.STUDSTATUS_ID = 27
    WHERE SG.SGROUP_ID = SGRP_ID AND
          CASE FSGROUP_ACTIVE(G.SGROUP_ID)
            WHEN TRUE THEN
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                ELSE FSTUDENT_ACTIVE(SG.STUDSGRP_ID) = ACTIVE
              END
            ELSE
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                WHEN ACTIVE THEN C.CONTINGENT_ID IS NOT NULL
                ELSE C.CONTINGENT_ID IS NULL
              END
            END;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDENT_CNT TO A,D,Z,S,V $$

-- список студентов
DROP PROCEDURE IF EXISTS decanet.STUDENT_LST $$
CREATE PROCEDURE decanet.STUDENT_LST(IN SGRP_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT DISTINCT SG.STUDSGRP_ID, S.STUDENT_ID, E.EDUFORM_ABBR, S.STUDENT_PERSNO, S.STUDENT_ZACHNO,
         S.STUDENT_STRAHNO, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
    FROM decanet.student S LEFT JOIN
         decanet.studsgrp SG USING (STUDENT_ID) LEFT JOIN
         decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                 C.STUDSTATUS_ID = 27
    WHERE SG.SGROUP_ID = SGRP_ID AND
          CASE FSGROUP_ACTIVE(G.SGROUP_ID)
            WHEN TRUE THEN
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                ELSE FSTUDENT_ACTIVE(SG.STUDSGRP_ID) = ACTIVE
              END
            ELSE
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                WHEN ACTIVE THEN C.CONTINGENT_ID IS NOT NULL
                ELSE C.CONTINGENT_ID IS NULL
              END
          END
    ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDENT_LST TO A,D,Z,S,V $$

-- строка студента
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDENT_ITM $$
CREATE PROCEDURE decanet.STUDENT_ITM (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT N.COUNTRY_ID, N.REGION_ID, Y.CITY_ID, H.SCHOOL_ID, F.FACULTET_ID, V.DIVISION_ID, R.STREAM_ID, G.SGROUP_ID,
         SG.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_PERSNO, S.STUDENT_ZACHNO,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school H USING (SCHOOL_ID) LEFT JOIN
         decanet.city Y USING (CITY_ID) LEFT JOIN
         decanet.region N USING (REGION_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDENT_ITM TO A,D,Z,S,V $$



-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ IV. ДАННЫЕ АКАДЕМИЧЕСКОЙ УСПЕВАЕМОСТИ СТУДЕНТА
-- ---------------------------------------------------------------------------------------------------

-- инд. программа и оценки студента по семестрам - CNT
-- если семестр NULL - то по всем семестрам
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDSEMACAD_CNT $$
CREATE PROCEDURE decanet.STUDSEMACAD_CNT(IN SSG_ID INT, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(P.PERSPROG_ID) AS CNT
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          IF(SEM IS NULL, TRUE, E.SEMESTR = SEM);
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEMACAD_CNT TO A,D,Z,S,V $$


DROP FUNCTION IF EXISTS decanet.FLEFTMPROG$$
CREATE FUNCTION decanet.FLEFTMPROG(SSG_ID INT, MP_ID INT) RETURNS BOOL
BEGIN
  RETURN NOT EXISTS (SELECT M.MAINPROG_ID
                     FROM decanet.studsgrp SG LEFT JOIN
                          decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
                          decanet.stream R USING (STREAM_ID) LEFT JOIN
                          decanet.dsession E USING (STREAM_ID) LEFT JOIN
                          decanet.mainprog M USING (DSESSION_ID)
                     WHERE SG.STUDSGRP_ID = SSG_ID AND
                           M.MAINPROG_ID = MP_ID);
END$$


-- инд. программа и оценки студента по семестрам - LIST
-- если семестр NULL - то по всем семестрам
-- *КОНТРОЛЬ СТРОКОВОГО БЛОКА ПО PERSPROG_ID
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDSEMACAD_LST $$
CREATE PROCEDURE decanet.STUDSEMACAD_LST(IN SSG_ID INT, IN SEM INT, IN ALLR BOOL, IN PATT BOOL) -- PATT - Промеж. аттестация
COMMENT 'ADZSV'
BEGIN
  SELECT P.PERSPROG_ID, M.MAINPROG_ID, J.SUBJ_ABBR, J.SUBJ_NAME, E.SEMESTR,
        (SELECT COUNT(SUBJ_ID) FROM decanet.mprogsubj S WHERE S.MAINPROG_ID = M.MAINPROG_ID) AS SUBJSEL,
         FLEFTMPROG(STUDSGRP_ID, P.MAINPROG_ID) AS LEFTMPROG,
         M.CONTROL_ID, C.CONTROL_ABBR, C.CONTROL_NAME, P.VOLUME, R.RESULT_ABBR, R.RESULT_INT, R.RESULT_NAME, R.RESULT_PASSFLAG,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.mprogsubj S USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.mainprog M ON M.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl PC USING (CONTROL_ID) LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          IF(SEM IS NULL, TRUE, E.SEMESTR = SEM) AND
          IF(PATT IS NULL, TRUE, IF(PATT, PC.SESSPHASE_ID = 1, PC.SESSPHASE_ID > 1)) AND
          IF(ALLR, TRUE,
             (A.ACAD_ID IS NULL OR
              D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                    FROM  decanet.acad A1 LEFT JOIN
                                          decanet.document D1 USING (DOCUMENT_ID)
                                    WHERE A1.PERSPROG_ID = P.PERSPROG_ID)))
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR, D.DOCUMENT_INDATE DESC, D.DOCUMENT_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEMACAD_LST TO A,D,Z,S,V $$

-- пункт инд. программы - ITEM
DROP PROCEDURE IF EXISTS decanet.STUDSEMACAD_ITM $$
CREATE PROCEDURE decanet.STUDSEMACAD_ITM(IN PPRG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT S.MAINPROG_ID, P.VOLUME, E.SEMESTR, J.SUBJ_ABBR, J.SUBJ_NAME,
         (SELECT COUNT(SUBJ_ID) FROM decanet.mprogsubj S WHERE S.MAINPROG_ID = M.MAINPROG_ID) AS SUBJSEL,
         M.CONTROL_ID, C.CONTROL_ENDFLAG, C.CONTROL_ABBR, C.CONTROL_NAME, C.CONTROL_NAMED, N.PERSNAME_NAME
    FROM decanet.persprog P LEFT JOIN
         decanet.mprogsubj S USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.persname N USING (PERSPROG_ID) LEFT JOIN
         decanet.mainprog M ON M.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID)
    WHERE P.PERSPROG_ID = PPRG_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEMACAD_ITM TO A,D,Z,S,V $$

-- ввод наименования работы по пункту инд. программы
DROP PROCEDURE IF EXISTS decanet.PPROGNAME_ADD $$
CREATE PROCEDURE decanet.PPROGNAME_ADD(IN PPRG_ID INT, IN PPROGNAME VARCHAR(255))
COMMENT 'DZS'
BEGIN
  DELETE FROM decanet.persname WHERE PERSPROG_ID = PPRG_ID;
  IF PPROGNAME IS NOT NULL AND TRIM(PPROGNAME) <> '' THEN
    INSERT INTO decanet.persname(PERSNAME_ID, PERSPROG_ID, PERSNAME_NAME)
      VALUES (NULL, PPRG_ID, PPROGNAME);

      SELECT Last_Insert_ID() AS RES;
  ELSE
      SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.PPROGNAME_ADD TO D,Z,S $$

-- кол-во оценок по пункту инд. программы
DROP PROCEDURE IF EXISTS decanet.STUDSEMACADITEM_CNT $$
CREATE PROCEDURE decanet.STUDSEMACADITEM_CNT(IN PPRG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DOCUMENT_ID) AS CNT
    FROM decanet.progdoc P
    WHERE P.PERSPROG_ID = PPRG_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEMACADITEM_CNT TO A,D,Z,S,V $$

-- оценки по пункту инд. программы - LIST
DROP PROCEDURE IF EXISTS decanet.STUDSEMACADITEM_LST $$
CREATE PROCEDURE decanet.STUDSEMACADITEM_LST(IN PPRG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT R.RESULT_INT, R.RESULT_NAME, R.RESULT_ABBR, RESULT_PASSFLAG,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         DATE_FORMAT(D.DOCUMENT_OUTDATE, '%d.%m.%Y %H:%i') AS DOCUMENT_OUTDATE
    FROM decanet.progdoc P LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.acad USING (PERSPROG_ID, DOCUMENT_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE P.PERSPROG_ID = PPRG_ID
    ORDER BY D.DOCUMENT_INDATE, D.DOCUMENT_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDSEMACADITEM_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ. УЧЕБНАЯ КАРТОЧКА И АКАДЕМИЧЕСКАЯ СПРАВКА СТУДЕНТА
-- ---------------------------------------------------------------------------------------------------

-- регистрация академической справки
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.ASPR_ADD $$
CREATE PROCEDURE decanet.ASPR_ADD(IN SSG_ID INT)
COMMENT 'DZS'
BEGIN
  DECLARE FID, DIV_ID, STD_ID, DOC_ID INT;

  SELECT D.FACULTET_ID
    INTO FID
    FROM decanet.studsgrp SSG LEFT JOIN
         decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
    WHERE SG.STUDSGRP_ID = SSG_ID;

  INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_INDATE)
    SELECT NULL, 11, FID, FALSE, NOW(), NOW();

  SET DOC_ID = LAST_INSERT_ID();

  UPDATE decanet.document D
    SET D.DOCUMENT_BARNO = CONCAT(FID, DOC_ID),
        D.DOCUMENT_NO = CONCAT(FID, DOC_ID)
    WHERE D.DOCUMENT_ID = DOC_ID;

  INSERT INTO decanet.studdoc (STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
    VALUES (NULL, SSG_ID, DOC_ID);

  SELECT DOC_ID AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.ASPR_ADD TO D,Z,S $$

-- инд. программа и оценки студента по семестрам
-- (только последние оценки) для карточки и акадсправки
-- только
-- ##SSG
-- CTG_ID 1 - экз зач            может быть NULL
--        2 - курсовые
--        3 - практики
--        4 - выпуск
--        5 - проч.
-- KURS иожет быть NULL

DROP PROCEDURE IF EXISTS decanet.REP_STUDSEMACAD_LST $$
CREATE PROCEDURE decanet.REP_STUDSEMACAD_LST(IN SSG_ID INT, IN CTG_ID INT, IN KRS INT)
COMMENT 'ADZSV'
BEGIN
  SELECT J.SUBJ_ABBR, J.SUBJ_NAME, E.SEMESTR,
         FKURS(E.SEMESTR) AS KURS,
         FSTUDUYEAR(SSG_ID, E.SEMESTR) AS UYEAR,
         C.CONTROL_ABBR, C.CONTROL_NAME, P.VOLUME,
         R.RESULT_ABBR, R.RESULT_INT, R.RESULT_NAME, R.RESULT_PASSFLAG,
         N.PERSNAME_NAME,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, T.DOCTYPE_NAME, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.persname N USING (PERSPROG_ID) LEFT JOIN
         decanet.mprogsubj S USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.mainprog M ON M.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D ON D.DOCUMENT_ID = A.DOCUMENT_ID LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          IF(KRS IS NULL, TRUE, FLOOR(E.SEMESTR / 2 + 0.5) = KRS) AND
          IF(CTG_ID IS NULL, TRUE, C.CTRLGRP_ID = CTG_ID) AND
          EXISTS (SELECT A1.ACAD_ID
                    FROM decanet.acad A1 LEFT JOIN
                         decanet.persprog P1 USING (PERSPROG_ID) LEFT JOIN
                         decanet.studsgrp SG1 USING (STUDSGRP_ID) LEFT JOIN
                         decanet.mainprog M1 USING (MAINPROG_ID) LEFT JOIN
                         decanet.dsession E1 USING (DSESSION_ID)
                    WHERE  E1.SEMESTR = E.SEMESTR AND
                           SG1.STUDSGRP_ID = SSG_ID) AND
         (A.ACAD_ID IS NULL OR
          D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                 FROM  decanet.acad A1 LEFT JOIN
                                       decanet.document D1 USING (DOCUMENT_ID)
                                 WHERE A1.PERSPROG_ID = P.PERSPROG_ID))
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_NAME;
END$$
GRANT EXECUTE ON PROCEDURE decanet.REP_STUDSEMACAD_LST TO A,D,Z,S,V $$

-- #SSG
-- перечень состоявшихся контингентный операций студента для карточки
DROP PROCEDURE IF EXISTS decanet.REP_STUDCONT_LST $$
CREATE PROCEDURE decanet.REP_STUDCONT_LST (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT D.DOCUMENT_ID, S.STUDSTATUS_NAME, S.STUDSTATUS_ACTIVE,
         V.DIVISION_ID, V.DIVISION_ABBR, C.STUDSTATUS_VALUE, C.CONTINGENT_DATE, C.CONTINGENT_DESC,
         T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         CAST(D.DOCUMENT_INDATE AS DATE) AS DOCUMENT_INDATE
    FROM decanet.studsgrp SSG LEFT JOIN
         decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.contingent C USING (STUDSGRP_ID) LEFT JOIN
         decanet.studstatus S USING (STUDSTATUS_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE SSG.STUDSGRP_ID = SSG_ID AND
          C.CONTINGENT_ID IS NOT NULL AND
          D.DOCUMENT_ID IS NOT NULL AND
          NOT D.DOCUMENT_TEMPFLAG
    ORDER BY C.CONTINGENT_DATE, S.STUDSTATUS_ACTIVE;
END $$
GRANT EXECUTE ON PROCEDURE decanet.REP_STUDCONT_LST TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ВЫПИСКА К ДИПЛОМУ
-- ---------------------------------------------------------------------------------------------------

-- ПО ПРОГРАММЕ ОТДЕЛЕНИЯ
DROP PROCEDURE IF EXISTS decanet.REP_STUDACAD_LST $$
CREATE PROCEDURE decanet.REP_STUDACAD_LST(IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN

  DROP TEMPORARY TABLE IF EXISTS decanet.ttsa_studacad;
  CREATE TEMPORARY TABLE decanet.ttsa_studacad AS
    SELECT SSG.STUDSGRP_ID, V.FACULTET_ID, V.DIVISION_ID, V.GOSTITLE_ID, S.SUBJ_ID,
           SUM(P.VOLUME) AS VOLUME,
           MIN(A.RESULT_ID) AS RESULT_ID -- ???
      FROM decanet.studsgrp SSG LEFT JOIN
           decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
           decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
           decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
           decanet.mprogsubj S USING (MPROGSUBJ_ID) LEFT JOIN
           decanet.acad A USING (PERSPROG_ID) LEFT JOIN
           decanet.document D ON D.DOCUMENT_ID = A.DOCUMENT_ID AND
                                 NOT D.DOCUMENT_TEMPFLAG
      WHERE SSG.STUDSGRP_ID = SSG_ID AND
            M.CONTROL_ID IN (1,2,3) AND
            NOT M.MAINPROG_HIDFLAG -- исключая скрытые
      GROUP BY S.SUBJ_ID;

  SELECT DISTINCT T.SUBJ_ID, J.SUBJ_NAME, T.VOLUME, R.RESULT_NAME
    FROM decanet.ttsa_studacad T LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.gos G USING (GOSTITLE_ID) LEFT JOIN
         decanet.gsubj GS USING (FACULTET_ID, GOS_ID, SUBJ_ID)
    ORDER BY GSUBJ_ID, J.SUBJ_NAME;

END$$
GRANT EXECUTE ON PROCEDURE decanet.REP_STUDACAD_LST TO A,D,Z,S,V $$


-- курсовые работы
DROP PROCEDURE IF EXISTS decanet.REP_STUDKR_LST $$
CREATE PROCEDURE decanet.REP_STUDKR_LST(IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN

  DROP TEMPORARY TABLE IF EXISTS decanet.ttsa_studkr;
  CREATE TEMPORARY TABLE decanet.ttsa_studkr AS
    SELECT SSG.STUDSGRP_ID, V.FACULTET_ID, V.DIVISION_ID, V.GOSTITLE_ID, S.SUBJ_ID, N.PERSNAME_ID,
           SUM(P.VOLUME) AS VOLUME,
           MIN(A.RESULT_ID) AS RESULT_ID
      FROM decanet.studsgrp SSG LEFT JOIN
           decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
           decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
           decanet.persname N USING (PERSPROG_ID) LEFT JOIN
           decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
           decanet.mprogsubj S USING (MPROGSUBJ_ID) LEFT JOIN
           decanet.acad A USING (PERSPROG_ID) LEFT JOIN
           decanet.document D ON D.DOCUMENT_ID = A.DOCUMENT_ID AND
                                 NOT D.DOCUMENT_TEMPFLAG
      WHERE SSG.STUDSGRP_ID = SSG_ID AND
            M.CONTROL_ID IN (4,5)
      GROUP BY S.SUBJ_ID;

  -- CREATE INDEX ...

  SELECT DISTINCT T.SUBJ_ID, J.SUBJ_NAME, T.VOLUME, R.RESULT_NAME, N.PERSNAME_NAME
    FROM decanet.ttsa_studkr T LEFT JOIN
         decanet.persname N USING (PERSNAME_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.gos G USING (GOSTITLE_ID) LEFT JOIN
         decanet.gsubj GS USING (FACULTET_ID, GOS_ID, SUBJ_ID)
    ORDER BY GSUBJ_ID, J.SUBJ_NAME;

END$$
GRANT EXECUTE ON PROCEDURE decanet.REP_STUDKR_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ V. ПЕРСОНАЛЬНАЯ ПРОГРАММА СТУДЕНТА
-- ---------------------------------------------------------------------------------------------------

-- изменение дисциплины из набора по выбору у студента
DROP PROCEDURE IF EXISTS decanet.PPROGSUBJ_CNG $$
CREATE PROCEDURE decanet.PPROGSUBJ_CNG(IN PP_ID INT, IN MPS_ID INT)
COMMENT 'DZS'
BEGIN
  DECLARE MP_ID INT;
  SELECT M.MAINPROG_ID INTO MP_ID
    FROM decanet.persprog P JOIN
         decanet.mprogsubj S USING (MPROGSUBJ_ID) JOIN
         decanet.mainprog M ON M.MAINPROG_ID = P.MAINPROG_ID
    WHERE P.PERSPROG_ID = PP_ID;
  IF MPS_ID IN (SELECT MPROGSUBJ_ID FROM decanet.mprogsubj WHERE MAINPROG_ID = MP_ID) THEN
    UPDATE decanet.persprog SET MPROGSUBJ_ID = MPS_ID WHERE PERSPROG_ID = PP_ID;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.PPROGSUBJ_CNG TO D,Z,S $$

-- изменение дисциплины из набора по выбору у группы
DROP PROCEDURE IF EXISTS decanet.SGRPPROGSUBJ_CNG $$
CREATE PROCEDURE decanet.SGRPPROGSUBJ_CNG(IN SGRP_ID INT, IN MP_ID INT, IN MPS_ID INT)
COMMENT 'DZS'
BEGIN
  IF MPS_ID IN (SELECT MPROGSUBJ_ID FROM decanet.mprogsubj WHERE MAINPROG_ID = MP_ID) THEN
    UPDATE decanet.persprog P LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      SET P.MPROGSUBJ_ID = MPS_ID
      WHERE P.MAINPROG_ID = MP_ID AND
            FSGROUP_ACTIVE(SG.SGROUP_ID) AND
            SG.SGROUP_ID = SGRP_ID AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID);
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SGRPPROGSUBJ_CNG TO D,Z,S $$

-- синхронизация персональной программы согласно основной для студента по семестру
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.PERSPROGSYNC $$
CREATE PROCEDURE decanet.PERSPROGSYNC(IN SSG_ID INT, IN SEM INT)
COMMENT 'DZS'
BEGIN
  INSERT INTO decanet.persprog (PERSPROG_ID, STUDSGRP_ID, MAINPROG_ID, MPROGSUBJ_ID, VOLUME)
    SELECT NULL, SG.STUDSGRP_ID, M.MAINPROG_ID, MIN(U.MPROGSUBJ_ID), M.VOLUME
      FROM decanet.mainprog M LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
      WHERE SG.STUDSGRP_ID = SSG_ID AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            E.SEMESTR = SEM AND
            P.PERSPROG_ID IS NULL
      GROUP BY M.MAINPROG_ID, SG.STUDSGRP_ID, E.SEMESTR;
  -- синхрочасы
  UPDATE decanet.mainprog M LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
    SET P.VOLUME = M.VOLUME
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          E.SEMESTR = SEM;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.PERSPROGSYNC TO D,Z,S $$

-- автоматический перезачет при восстановлении на другую программу
-- (студент уже в новой группе, поэтому известна его новая программа)
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.NEWMAINPROGSYNC $$
CREATE PROCEDURE decanet.NEWMAINPROGSYNC(IN SSG_ID INT)
BEGIN
  -- удалить перспрог без оценок
  SET FOREIGN_KEY_CHECKS = 0;
  DELETE decanet.persprog, decanet.progdoc
    FROM decanet.studsgrp LEFT JOIN
         decanet.persprog USING (STUDSGRP_ID) LEFT JOIN
         decanet.progdoc USING (PERSPROG_ID) LEFT JOIN
         decanet.acad USING (PERSPROG_ID)
    WHERE STUDSGRP_ID = SSG_ID AND
          ACAD_ID IS NULL;
  SET FOREIGN_KEY_CHECKS = 1;
  -- перезачесть
  UPDATE decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj J USING (MAINPROG_ID) LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.mprogsubj Q ON Q.MPROGSUBJ_ID = P.MPROGSUBJ_ID LEFT JOIN
         decanet.mainprog N ON N.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.dsession I ON I.DSESSION_ID = N.DSESSION_ID
    SET P.MAINPROG_ID = IFNULL(M.MAINPROG_ID, P.MAINPROG_ID),
        P.MPROGSUBJ_ID = IFNULL(J.MPROGSUBJ_ID, P.MPROGSUBJ_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          Q.SUBJ_ID = J.SUBJ_ID AND
          N.CONTROL_ID = M.CONTROL_ID AND
          E.SEMESTR = I.SEMESTR;
  -- синхронизировать
  INSERT INTO decanet.persprog (PERSPROG_ID, STUDSGRP_ID, MAINPROG_ID, MPROGSUBJ_ID, VOLUME)
    SELECT NULL, SG.STUDSGRP_ID, M.MAINPROG_ID, MIN(U.MPROGSUBJ_ID), M.VOLUME
      FROM decanet.mainprog M LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
      WHERE SG.STUDSGRP_ID = SSG_ID AND
            P.PERSPROG_ID IS NULL
      GROUP BY M.MAINPROG_ID, SG.STUDSGRP_ID, E.SEMESTR;

  SELECT 1 AS RES;
END$$

-- список пунктов персональной программы других семестров в которые возможен перезачет "повисшей" оценки
DROP PROCEDURE IF EXISTS decanet.MANUALPPSYNC_LST $$
CREATE PROCEDURE decanet.MANUALPPSYNC_LST(IN PPRG_ID INT)
COMMENT 'ADZSV'
BEGIN
--  SELECT P.PERSPROG_ID, E.SEMESTR, J.SUBJ_ID, M.CONTROL_ID, Pm.PERSPROG_ID, Em.SEMESTR, Jm.SUBJ_ID, Mm.CONTROL_ID
  SELECT Pm.PERSPROG_ID, Em.SEMESTR, Jm.SUBJ_ID, Mm.CONTROL_ID, C.CONTROL_ABBR, U.SUBJ_ABBR, U.SUBJ_NAME, Pm.VOLUME,
         R.RESULT_ABBR, R.RESULT_INT, R.RESULT_NAME, R.RESULT_PASSFLAG,
         D.DOCUMENT_ID, Y.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.persprog P LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj J USING (MAINPROG_ID) LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream T ON T.STREAM_ID = G.STREAM_ID LEFT JOIN
         decanet.dsession Em ON Em.STREAM_ID = T.STREAM_ID LEFT JOIN
         decanet.mainprog Mm ON Mm.DSESSION_ID = Em.DSESSION_ID LEFT JOIN
         decanet.control C ON C.CONTROL_ID = Mm.CONTROL_ID LEFT JOIN
         decanet.mprogsubj Jm ON Jm.MAINPROG_ID = Mm.MAINPROG_ID LEFT JOIN
         decanet.subj U ON U.SUBJ_ID = Jm.SUBJ_ID LEFT JOIN
         decanet.persprog Pm ON Pm.MAINPROG_ID = Mm.MAINPROG_ID AND
                                Pm.STUDSGRP_ID = SG.STUDSGRP_ID LEFT JOIN
         decanet.acad A ON A.PERSPROG_ID = Pm.PERSPROG_ID LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype Y USING (DOCTYPE_ID)
    WHERE P.PERSPROG_ID = PPRG_ID AND
          Jm.SUBJ_ID = J.SUBJ_ID AND
          Mm.CONTROL_ID = M.CONTROL_ID AND
          Em.SEMESTR <> E.SEMESTR AND
          (A.ACAD_ID IS NULL OR
             D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                    FROM  decanet.acad A1 LEFT JOIN
                                          decanet.document D1 USING (DOCUMENT_ID)
                                    WHERE A1.PERSPROG_ID = Pm.PERSPROG_ID))
    ORDER BY Em.SEMESTR, Mm.CONTROL_ID, U.SUBJ_ABBR;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MANUALPPSYNC_LST TO A,D,Z,S,V $$


-- список пунктов персональной программы других семестров в которые возможен перезачет ПО ВЫБОРУ ПОЛЬЗОВАТЕЛЯ "повисшей" оценки
DROP PROCEDURE IF EXISTS decanet.ALLPPSYNC_LST $$
CREATE PROCEDURE decanet.ALLPPSYNC_LST(IN PPRG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT P.PERSPROG_ID, E.SEMESTR, J.SUBJ_ID, M.CONTROL_ID, C.CONTROL_ABBR, J.SUBJ_ABBR, J.SUBJ_NAME, P.VOLUME,
         R.RESULT_ABBR, R.RESULT_INT, R.RESULT_NAME, R.RESULT_PASSFLAG,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.persprog PS LEFT JOIN
         decanet.mainprog MS USING (MAINPROG_ID) LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.mprogsubj S ON S.MPROGSUBJ_ID = P.MPROGSUBJ_ID LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.mainprog M ON M.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.dsession E ON E.DSESSION_ID = M.DSESSION_ID LEFT JOIN
         decanet.control C ON C.CONTROL_ID = M.CONTROL_ID LEFT JOIN
         decanet.acad A ON A.PERSPROG_ID = P.PERSPROG_ID LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE PS.PERSPROG_ID = PPRG_ID AND
          NOT FLEFTMPROG(STUDSGRP_ID, P.MAINPROG_ID) AND
          MS.CONTROL_ID = M.CONTROL_ID AND
         (A.ACAD_ID IS NULL OR
            D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                   FROM  decanet.acad A1 LEFT JOIN
                                         decanet.document D1 USING (DOCUMENT_ID)
                                   WHERE A1.PERSPROG_ID = P.PERSPROG_ID))
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR, D.DOCUMENT_INDATE, D.DOCUMENT_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.ALLPPSYNC_LST TO A,D,Z,S,V $$

-- ручной перезачет
-- варианты TPPRG берутся из MANUALPPSYNC_LST
DROP PROCEDURE IF EXISTS decanet.MANUALPPSYNC_CNG $$
CREATE PROCEDURE decanet.MANUALPPSYNC_CNG(IN FPPRG_ID INT, TPPRG_ID INT)
COMMENT 'DZ'
BEGIN
  DECLARE MPID, MPSBJID INT;

  SELECT MAINPROG_ID, MPROGSUBJ_ID
    INTO MPID, MPSBJID
    FROM decanet.persprog
    WHERE PERSPROG_ID = TPPRG_ID;

  UPDATE decanet.progdoc
    SET PERSPROG_ID = TPPRG_ID
    WHERE PERSPROG_ID = FPPRG_ID;

  UPDATE decanet.acad
    SET PERSPROG_ID = TPPRG_ID
    WHERE PERSPROG_ID = FPPRG_ID;

  DELETE FROM decanet.persprog
     WHERE PERSPROG_ID = FPPRG_ID;

  UPDATE decanet.persprog P
    SET MAINPROG_ID = MPID,
        MPROGSUBJ_ID = MPSBJID
    WHERE PERSPROG_ID = FPPRG_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MANUALPPSYNC_CNG TO D,Z $$

-- изменение пункта персональной программы
DROP PROCEDURE IF EXISTS decanet.PERSPROG_CNG $$
CREATE PROCEDURE decanet.PERSPROG_CNG(IN PPRG_ID INT, IN VOL INT)
COMMENT 'DZS'
BEGIN
   UPDATE decanet.persprog
     SET VOLUME = VOL
     WHERE PERSPROG_ID = PPRG_ID;
    SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.PERSPROG_CNG TO D,Z,S $$

-- удаление пункта персональной программы
DROP PROCEDURE IF EXISTS decanet.PERSPROG_DEL $$
CREATE PROCEDURE decanet.PERSPROG_DEL(IN PPRG_ID INT)
COMMENT 'DZS'
BEGIN
  IF NOT EXISTS (SELECT A.ACAD_ID
                   FROM decanet.persprog P JOIN
                        decanet.acad A USING (PERSPROG_ID)
                   WHERE P.PERSPROG_ID = PPRG_ID) THEN
    DELETE FROM decanet.progdoc
      WHERE PERSPROG_ID = PPRG_ID;
    DELETE FROM decanet.persprog
      WHERE PERSPROG_ID = PPRG_ID;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.PERSPROG_DEL TO D,Z,S $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ VI. ДАННЫЕ АКАДЕМИЧЕСКОЙ УСПЕВАЕМОСТИ ГРУППЫ
-- ---------------------------------------------------------------------------------------------------

-- основная программа для учебной группы - CNT
DROP PROCEDURE IF EXISTS decanet.GRPSEMMPROG_CNT $$
CREATE PROCEDURE decanet.GRPSEMMPROG_CNT(SGRP_ID INT, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(M.MAINPROG_ID) AS CNT
    FROM decanet.mainprog M LEFT JOIN
         decanet.mprogsubj S USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGRP_ID AND E.SEMESTR = SEM;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPSEMMPROG_CNT TO A,D,Z,S,V $$

-- основная программа для учебной группы - LIST
-- *КОНТРОЛЬ СТРОКОВОГО БЛОКА ПО MAINPROG_ID
DROP PROCEDURE IF EXISTS decanet.GRPSEMMPROG_LST $$
CREATE PROCEDURE decanet.GRPSEMMPROG_LST(SGRP_ID INT, IN SEM INT, IN PATT BOOL)  -- PATT - Пром. аттестация
COMMENT 'ADZSV'
BEGIN

  -- вычисляем последние ведомости по пунктам основной программы
  DROP TEMPORARY TABLE IF EXISTS decanet.ttmprogved;
  CREATE TEMPORARY TABLE decanet.ttmprogved AS
    SELECT M.MAINPROG_ID, MAX(D.DOCUMENT_ID) AS DOCUMENT_ID
      FROM decanet.mainprog M LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream T USING (STREAM_ID) LEFT JOIN
           decanet.division V USING (DIVISION_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.mprogsubj S USING (MAINPROG_ID) LEFT JOIN
           decanet.persprog P USING (STUDSGRP_ID, MPROGSUBJ_ID) LEFT JOIN
           decanet.progdoc R USING (PERSPROG_ID) LEFT JOIN
           decanet.document D ON D.DOCUMENT_ID = R.DOCUMENT_ID AND D.DOCTYPE_ID = 1
      WHERE E.SEMESTR = SEM AND
            G.SGROUP_ID = SGRP_ID
      GROUP BY M.MAINPROG_ID;

  SELECT M.MAINPROG_ID, S.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME,
         M.VOLUME, M.CONTROL_ID, C.CONTROL_ABBR, C.CONTROL_NAME,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO, DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.ttmprogved E LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.mprogsubj S USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl PC USING (CONTROL_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.document D ON D.DOCUMENT_ID = E.DOCUMENT_ID LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE IF(PATT IS NULL, TRUE, IF(PATT, PC.SESSPHASE_ID = 1, PC.SESSPHASE_ID > 1))
    ORDER BY CONTROL_ID, MAINPROG_ID, SUBJ_NAME;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttMPROGVED;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPSEMMPROG_LST TO A,D,Z,S,V $$


-- оценки группы по дисциплине (MAINPROG_ID) - CNT
DROP PROCEDURE IF EXISTS decanet.GRPACADMPROG_CNT $$
CREATE PROCEDURE decanet.GRPACADMPROG_CNT(SGRP_ID INT, IN MPROG_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(S.STUDENT_ID) AS CNT
    FROM decanet.student S LEFT JOIN
         decanet.studsgrp SG USING (STUDENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream T USING (STREAM_ID) LEFT JOIN
         decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                 C.STUDSTATUS_ID = 27 LEFT JOIN
         decanet.persprog P ON P.STUDSGRP_ID = SG.STUDSGRP_ID LEFT JOIN
         decanet.mprogsubj U ON U.MPROGSUBJ_ID = P.MPROGSUBJ_ID AND
                                U.MAINPROG_ID = MPROG_ID JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.acad A USING (PERSPROG_ID)
    WHERE G.SGROUP_ID = SGRP_ID AND
          CASE FSGROUP_ACTIVE(G.SGROUP_ID)
            WHEN TRUE THEN
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                ELSE FSTUDENT_ACTIVE(SG.STUDSGRP_ID) = ACTIVE
              END
            ELSE
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                WHEN ACTIVE THEN C.CONTINGENT_ID IS NOT NULL
                ELSE C.CONTINGENT_ID IS NULL
              END
          END
       ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPACADMPROG_CNT TO A,D,Z,S,V $$

-- оценки группы по дисциплине (MAINPROG_ID) - LIST
-- *КОНТРОЛЬ СТРОКОВОГО БЛОКА ПО STUDENT_ID
DROP PROCEDURE IF EXISTS decanet.GRPACADMPROG_LST $$
CREATE PROCEDURE decanet.GRPACADMPROG_LST(SGRP_ID INT, IN MPROG_ID INT, IN ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT SG.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME, S.STUDENT_ZACHNO,
         J.SUBJ_ABBR, R.RESULT_INT, R.RESULT_ABBR, R.RESULT_NAME, R.RESULT_PASSFLAG,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         P.PERSPROG_ID, N.PERSNAME_NAME
    FROM decanet.student S LEFT JOIN
         decanet.studsgrp SG ON SG.STUDENT_ID = S.STUDENT_ID LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream M USING (STREAM_ID) LEFT JOIN
         decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                 C.STUDSTATUS_ID = 27 LEFT JOIN
         decanet.persprog P ON P.STUDSGRP_ID = SG.STUDSGRP_ID LEFT JOIN
         decanet.persname N USING (PERSPROG_ID) LEFT JOIN
         decanet.mprogsubj U ON U.MPROGSUBJ_ID = P.MPROGSUBJ_ID AND
                                U.MAINPROG_ID = MPROG_ID JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D ON D.DOCUMENT_ID = A.DOCUMENT_ID LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE SG.SGROUP_ID = SGRP_ID AND
          CASE FSGROUP_ACTIVE(G.SGROUP_ID)
            WHEN TRUE THEN
              CASE
                WHEN ACTIVE IS NULL THEN TRUE
                ELSE FSTUDENT_ACTIVE(SG.STUDSGRP_ID) = ACTIVE
              END
              ELSE
                CASE
                  WHEN ACTIVE IS NULL THEN TRUE
                  WHEN ACTIVE THEN C.CONTINGENT_ID IS NOT NULL
                  ELSE C.CONTINGENT_ID IS NULL
                END
              END
    ORDER BY STUDENT_LNAME, STUDENT_FNAME, D.DOCUMENT_INDATE;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPACADMPROG_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ VII. ПРОЦЕСС ЭКЗАМЕНАЦИОННОЙ ВЕДОМОСТИ
-- ---------------------------------------------------------------------------------------------------

-- регистрация экзаменационной ведомости  на группу
-- !возвращает несколько строк в случае если обслуживается набор дисциплин по выбору!
-- DTYPE
DROP PROCEDURE IF EXISTS decanet.EKZVED_ADD $$
CREATE PROCEDURE decanet.EKZVED_ADD (IN SGRP_ID INT, IN MPROG_ID INT, IN DTYPE INT)
COMMENT 'DZS'
BEGIN
  DECLARE CURSEM, MPROGSEM, DOC_ID, FID, DID INT;
  DECLARE VDT DATETIME;
  DECLARE UY, UYR, FY YEAR;
  DECLARE SGRP_ACTIVE BOOL;

  -- факультет
  SELECT D.FACULTET_ID, D.DIVISION_ID
    INTO FID, DID
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE G.SGROUP_ID = SGRP_ID;

  SET SGRP_ACTIVE = FSGROUP_ACTIVE(SGRP_ID);
  SET MPROGSEM = (SELECT E.SEMESTR
                    FROM decanet.mainprog M LEFT JOIN
                         decanet.dsession E USING (DSESSION_ID)
                    WHERE M.MAINPROG_ID = MPROG_ID);

  SET CURSEM = FGETCURSEM(SGRP_ID);

-- !!!!!! ДЛЯ ПАССИВ ГРУПП VDT IS NULL - починить

  IF SGRP_ACTIVE AND MPROGSEM >= CURSEM THEN
    SET VDT = NOW();
  ELSE
    -- учебный год
    SET UYR = FY + ROUND(MPROGSEM / 2) - 1;
    -- определить дату ведомости при 'заочном' вводе как дату НАЧАЛА (ПЛОХО) соотв. семестра
    IF MOD(MPROGSEM, 2) THEN -- дата по нечетному семестру
      SET VDT = GETNCHETBEGSEM(DID, UYR);
    ELSE                     -- дата по четному семестру
      SET VDT = GETCHETBEGSEM(DID, UYR);
    END IF;
  END IF;

  INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE)
    SELECT NULL, DTYPE, FID, TRUE, IFNULL(VDT, Now());   -- тип документа - 1 - экзаменационная ведомость
                                                                         -- 12 - ведомость тем
  SET DOC_ID = LAST_INSERT_ID();

  UPDATE decanet.document D
    SET D.DOCUMENT_BARNO = CONCAT(FID, DOC_ID),
        D.DOCUMENT_NO = CONCAT(FID, DOC_ID)
    WHERE D.DOCUMENT_ID = DOC_ID;

  INSERT INTO decanet.progdoc (PROGDOC_ID, DOCUMENT_ID, PERSPROG_ID)
    SELECT NULL, DOC_ID, P.PERSPROG_ID
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.persprog P ON P.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                 P.MAINPROG_ID = MPROG_ID
      WHERE P.PERSPROG_ID IS NOT NULL AND
            SG.SGROUP_ID = SGRP_ID AND
            IF(FSGROUP_ACTIVE(G.SGROUP_ID), FSTUDENT_ACTIVE(SG.STUDSGRP_ID), TRUE);

  SELECT DOC_ID AS RES;

END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZVED_ADD TO D,Z,S $$

-- регистрация экзаменационной ведомости должников
-- !возвращает несколько строк в случае если обслуживается набор дисциплин по выбору!
DROP PROCEDURE IF EXISTS decanet.DOLGVED_ADD $$
CREATE PROCEDURE decanet.DOLGVED_ADD (IN MPROG_ID INT)
COMMENT 'DZS'
BEGIN
  DECLARE FID, DOC_ID INT;
  DECLARE SGRP_ACTIVE BOOL;
  DECLARE UY, UYR, FY YEAR;

  -- факультет
  SELECT D.FACULTET_ID
    INTO FID
    FROM decanet.mainprog M LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE M.MAINPROG_ID = MPROG_ID;

  INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE)
    SELECT NULL, 8, FID, TRUE, NOW(); -- 8 - тип документа - ведомость должников

  SET DOC_ID = LAST_INSERT_ID();

  UPDATE decanet.document D
    SET D.DOCUMENT_NO = CONCAT(FID, DOC_ID),
        D.DOCUMENT_BARNO = CONCAT(FID, DOC_ID)
    WHERE D.DOCUMENT_ID = DOC_ID;

  INSERT INTO decanet.progdoc (PROGDOC_ID, DOCUMENT_ID, PERSPROG_ID) -- привязка к ведомости пунктов персональной программы
    SELECT NULL, DOC_ID, P.PERSPROG_ID   -- отлов пунктов персональной программы должников
       FROM decanet.mainprog M LEFT JOIN
            decanet.persprog P USING (MAINPROG_ID) LEFT JOIN
            decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
            decanet.acad A USING (PERSPROG_ID) LEFT JOIN
            decanet.document D USING (DOCUMENT_ID) LEFT JOIN
            decanet.result R USING (RESULT_ID)
       WHERE M.MAINPROG_ID = MPROG_ID AND
             FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            (A.ACAD_ID IS NULL OR
              (D.DOCUMENT_INDATE = (SELECT MAX(U.DOCUMENT_INDATE)
                                      FROM decanet.acad C LEFT JOIN
                                           decanet.document U USING (DOCUMENT_ID)
                                      WHERE C.PERSPROG_ID = P.PERSPROG_ID) AND
               NOT R.RESULT_PASSFLAG));

  SELECT DOC_ID AS RES;

END $$
GRANT EXECUTE ON PROCEDURE decanet.DOLGVED_ADD TO D,Z,S $$

-- выдача экзаменационной ведомости (список группы в отчет)
-- результат сортируется по SUBJ_NAME - для
-- группировки в отчете-ведомости при использовании дисциплины-по-выбору
DROP PROCEDURE IF EXISTS decanet.EKZVED_LST $$
CREATE PROCEDURE decanet.EKZVED_LST(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT M.PERSPROG_ID, M.SUBJ_ABBR, M.MPROGSUBJ_ID,
         M.SGROUPAUTONAME,
         M.STUDSGRP_ID,
         M.STUDENT_LNAME, M.STUDENT_FNAME, M.STUDENT_MNAME,
         M.STUDENT_PERSNO, M.STUDENT_ZACHNO,
         R.RESULT_ABBR, R.RESULT_PASSFLAG, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         -- сущ. результат по этой ведомости (для повторного ввода)
         AC.RESULT_ID AS CURRES_ID, RC.RESULT_ABBR AS CURRES_ABBR, RC.RESULT_PASSFLAG AS CURRES_PASSFLAG
  FROM
    (SELECT P.PERSPROG_ID, J.SUBJ_ABBR, U.MPROGSUBJ_ID,
            SG.STUDSGRP_ID,
            S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
            S.STUDENT_PERSNO, S.STUDENT_ZACHNO, SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUPAUTONAME,
            (SELECT A.ACAD_ID -- предыдущая оценка
               FROM decanet.document D LEFT JOIN
                    decanet.acad A USING (DOCUMENT_ID)
               WHERE D.DOCUMENT_INDATE = (SELECT MAX(U.DOCUMENT_INDATE)
                                            FROM decanet.acad C LEFT JOIN
                                                 decanet.document U USING (DOCUMENT_ID)
                                            WHERE C.PERSPROG_ID = A.PERSPROG_ID AND
                                                  U.DOCUMENT_ID <> DOC_ID) AND
                     A.PERSPROG_ID = P.PERSPROG_ID
               ORDER BY DOCUMENT_ID DESC LIMIT 1) AS ACAD_ID
       FROM decanet.document D LEFT JOIN
            decanet.progdoc G USING (DOCUMENT_ID) LEFT JOIN
            decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
            decanet.mprogsubj U USING (MPROGSUBJ_ID) LEFT JOIN
            decanet.subj J USING (SUBJ_ID) LEFT JOIN
            decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
            decanet.student S USING (STUDENT_ID)
       WHERE D.DOCUMENT_ID = DOC_ID) M LEFT JOIN
     decanet.acad A USING (ACAD_ID) LEFT JOIN
     decanet.document D USING (DOCUMENT_ID) LEFT JOIN
     decanet.acad AC ON AC.DOCUMENT_ID = DOC_ID AND
                        AC.PERSPROG_ID = M.PERSPROG_ID LEFT JOIN
     decanet.doctype T USING(DOCTYPE_ID) LEFT JOIN
     decanet.result R ON R.RESULT_ID = A.RESULT_ID LEFT JOIN
     decanet.result RC ON RC.RESULT_ID = AC.RESULT_ID -- введенные результаты этой ведомости (повт. ввод / отображ.)
  WHERE M.PERSPROG_ID IS NOT NULL
  ORDER BY M.SUBJ_ABBR, M.SGROUPAUTONAME, M.STUDENT_LNAME, M.STUDENT_FNAME, M.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZVED_LST TO A,D,Z,S,V $$


-- данные экзаменационной ведомости для формирования
-- несколько строк при дисциплине по выбору
DROP PROCEDURE IF EXISTS decanet.EKZVED_ITM $$
CREATE PROCEDURE decanet.EKZVED_ITM (IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE SA, FA, DA VARCHAR(25);
  DECLARE SN, FN, DN VARCHAR(255);
  DECLARE SGRP_ACTIVE BOOL;
  DECLARE CNT, MPROG_ID, SGRP_ID, DID, KURS, DS INT;
  DECLARE VDT DATETIME;
  DECLARE UY, FY YEAR;

  -- определяем группу
  SELECT SG.SGROUP_ID, COUNT(SG.STUDENT_ID)
    INTO SGRP_ID, CNT
    FROM decanet.progdoc D LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID)
    WHERE D.DOCUMENT_ID = DOC_ID
    GROUP BY SG.SGROUP_ID
    ORDER BY 2 DESC
    LIMIT 1;

  SELECT P.MAINPROG_ID, COUNT(P.PERSPROG_ID)
    INTO MPROG_ID, CNT
    FROM decanet.progdoc D LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID)
    WHERE D.DOCUMENT_ID = DOC_ID
    GROUP BY P.MAINPROG_ID
    ORDER BY 2 DESC
    LIMIT 1;

  SELECT H.SCHOOL_ABBR, H.SCHOOL_NAME,
         F.FACULTET_ABBR, F.FACULTET_NAME,
         D.DIVISION_ID, D.DIVISION_ABBR, D.DIVISION_NAME, R.STREAM_SEMCOUNT,
         R.STREAM_FROMYEAR
    INTO SA, SN, FA, FN, DID, DA, DN, DS, FY
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school H USING (SCHOOL_ID)
    WHERE G.SGROUP_ID = SGRP_ID;

  SET VDT = (SELECT DOCUMENT_OUTDATE
               FROM decanet.document
               WHERE DOCUMENT_ID = DOC_ID);

  -- учебный год
  SET UY = GETUYEAR(DID, VDT);
  -- курс группы на момент ведомости
  -- ПРОВЕРИТЬ ! на соответствие KURS = ROUND(MPROGSEM / 2)
  SET KURS = UY - FY + 1;
  IF KURS > DS / 2 THEN
    SET KURS = ROUND(DS / 2);
  END IF;

  SELECT DISTINCT D.DOCTYPE_ID, D.DOCUMENT_ID, D.DOCUMENT_NO, D.DOCUMENT_TEMPFLAG,
         -- повт. ввод / отображение
         DATE_FORMAT(D.DOCUMENT_OUTDATE, '%d.%m.%Y') AS DOCUMENT_OUTDATE,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         CONCAT(UY, '/', UY + 1) AS UYEAR,
         KURS,
         E.SEMESTR, M.VOLUME,
         C.CONTROL_ID, C.CONTROL_ABBR, C.CONTROL_NAME,
         SN, FN, DN,
         SGROUPAUTONAME(SGRP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         U.MPROGSUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME
    FROM decanet.document D LEFT JOIN
         decanet.progdoc G USING (DOCUMENT_ID) LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.sgroup O USING (STREAM_ID) LEFT JOIN
         decanet.mprogsubj U ON U.MAINPROG_ID = P.MAINPROG_ID LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID)
    WHERE IF(SGRP_ID IS NULL, TRUE, O.SGROUP_ID = SGRP_ID) AND
          D.DOCUMENT_ID = DOC_ID AND
          D.DOCTYPE_ID IN (1, 8, 12);
END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZVED_ITM TO A,D,Z,S $$


-- установка дисциплины-по-выбору при вводе ведомости
DROP PROCEDURE IF EXISTS decanet.EKZVEDMPS_CNG $$
CREATE PROCEDURE decanet.EKZVEDMPS_CNG(IN PPROG_ID INT, IN MPS_ID INT)
COMMENT 'DZS'
BEGIN
  UPDATE decanet.persprog P LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID)
    SET P.MPROGSUBJ_ID = U.MPROGSUBJ_ID
    WHERE P.PERSPROG_ID = PPROG_ID AND
          U.MPROGSUBJ_ID = MPS_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.EKZVEDMPS_CNG TO D,Z,S $$


-- ввод одной оценки по ведомости
-- ДЛЯ ОБЕСПЕЧЕНИЯ ПОВТОРНОГО ВВОДА оценки NULL тоже допустимы
DROP PROCEDURE IF EXISTS decanet.EKZVED_CNG $$
CREATE PROCEDURE decanet.EKZVED_CNG(IN DOC_ID INT, IN PPROG_ID INT, IN RES_ID INT)
COMMENT 'DZS'
BEGIN
  DECLARE ORID INT;

  SET ORID = (SELECT A.RESULT_ID
                FROM decanet.persprog P LEFT JOIN
                     decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                     decanet.result R USING (RESULT_ID) LEFT JOIN
                     decanet.document D USING (DOCUMENT_ID)
                WHERE P.PERSPROG_ID = PPROG_ID AND
                      A.RESULT_ID = RES_ID AND
                      R.RESULT_PASSFLAG AND
                      NOT D.DOCUMENT_TEMPFLAG AND
                      D.DOCUMENT_ID <> DOC_ID);

  IF ORID IS NULL THEN -- проверка имеющейся такой же оценки

    -- повторный ввод - удаление оценки
    DELETE FROM decanet.acad
      WHERE DOCUMENT_ID = DOC_ID AND
            PERSPROG_ID = PPROG_ID;

    IF RES_ID IS NOT NULL AND RES_ID > 0 THEN
      INSERT INTO decanet.acad (ACAD_ID, PERSPROG_ID, RESULT_ID, DOCUMENT_ID)
        VALUES (NULL, PPROG_ID, RES_ID, DOC_ID);
    END IF;

    SELECT 1 AS RES;

  ELSE
    SELECT 0 AS RES;
  END IF;

END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZVED_CNG TO D,Z,S $$

-- закрытие только-что введенной ведомости
DROP PROCEDURE IF EXISTS decanet.EKZVED_CLOSE $$
CREATE PROCEDURE decanet.EKZVED_CLOSE(IN DOC_ID INT, IN DOCNO VARCHAR(25), IN VDATE DATETIME)
COMMENT 'DZS'
BEGIN
  DECLARE MAXINDT DATETIME;

  -- контроль совпадения дат
  SELECT MAX(D.DOCUMENT_INDATE) INTO MAXINDT
    FROM decanet.progdoc P LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D ON A.DOCUMENT_ID = D.DOCUMENT_ID
    WHERE P.DOCUMENT_ID = DOC_ID AND
          D.DOCUMENT_ID <> DOC_ID AND
          NOT D.DOCUMENT_TEMPFLAG;

  IF DATE_FORMAT(MAXINDT, '%d.%m.%Y') = DATE_FORMAT(VDATE, '%d.%m.%Y') THEN
    SET VDATE = MAXINDT + INTERVAL 1 SECOND;
  END IF;

  UPDATE decanet.document D
    SET D.DOCUMENT_TEMPFLAG = FALSE,
        D.DOCUMENT_NO = DOCNO,
        D.DOCUMENT_INDATE = IFNULL(VDATE, NOW())
    WHERE D.DOCUMENT_ID = DOC_ID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZVED_CLOSE TO D,Z,S $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ПРОЦЕСС ВЕДОМОСТИ ТЕМ
-- ---------------------------------------------------------------------------------------------------

-- Прочие операции для ведомости тем производятся инструментами
-- экзаменационной ведомости (REGISTEREKZV, LOCEKZV, CLOSEVED)

-- выдача ведомости тем (список группы c темами в отчет)
-- результат сортируется по SUBJ_NAME - для
-- группировки в отчете-ведомости при использовании дисциплины-по-выбору
DROP PROCEDURE IF EXISTS decanet.TEMVED_LST $$
CREATE PROCEDURE decanet.TEMVED_LST(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT P.PERSPROG_ID, J.SUBJ_ABBR, M.MPROGSUBJ_ID,
         SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUP_AUTONAME,
         SG.STUDSGRP_ID,
         S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
         S.STUDENT_PERSNO, S.STUDENT_ZACHNO,
         N.PERSNAME_NAME
  FROM decanet.document D LEFT JOIN
       decanet.progdoc G USING (DOCUMENT_ID) LEFT JOIN
       decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
       decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
       decanet.student S USING (STUDENT_ID) LEFT JOIN
       decanet.mprogsubj M USING (MPROGSUBJ_ID) LEFT JOIN
       decanet.subj J USING (SUBJ_ID) LEFT JOIN
       decanet.persname N USING (PERSPROG_ID)
  WHERE D.DOCUMENT_ID = DOC_ID
  ORDER BY J.SUBJ_ABBR, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.TEMVED_LST TO A,D,Z,S,V $$

-- ввод одной темы по ведомости тем
-- ДЛЯ ОБЕСПЕЧЕНИЯ ПОВТОРНОГО ВВОДА оценки NULL тоже PUT-тим
DROP PROCEDURE IF EXISTS decanet.TEMVED_CNG $$
CREATE PROCEDURE decanet.TEMVED_CNG(IN DOC_ID INT, IN PPROG_ID INT, IN PNAME VARCHAR(255))
COMMENT 'DZS'
BEGIN
  -- повторный ввод - удаление темы
  DELETE FROM decanet.persname
    WHERE DOCUMENT_ID = DOC_ID AND
          PERSPROG_ID = PPROG_ID;
  IF PNAME IS NOT NULL THEN
    INSERT INTO decanet.persname (PERSNAME_ID, PERSPROG_ID, DOCUMENT_ID, PERSNAME_NAME)
      VALUES (NULL, PPROG_ID, DOC_ID, PNAME);
  END IF;
  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.TEMVED_CNG TO D,Z,S $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ VIII. УЧЕБНАЯ ПРОГРАММА ОТДЕЛЕНИЯ
-- ---------------------------------------------------------------------------------------------------

-- кол-во дисциплин в пункте основной программы (IN - MPROG_ID)
DROP PROCEDURE IF EXISTS decanet.MPROGITEM_CNT $$
CREATE PROCEDURE decanet.MPROGITEM_CNT(IN MP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(MPROGSUBJ_ID) AS CNT
    FROM decanet.mprogsubj
    WHERE MAINPROG_ID = MP_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MPROGITEM_CNT TO A,D,Z,S,V $$

-- список дисциплин в пункте основной программы (IN - MPROG_ID)
DROP PROCEDURE IF EXISTS decanet.MPROGITEM_LST $$
CREATE PROCEDURE decanet.MPROGITEM_LST(IN MP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT U.MPROGSUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, C.CONTROL_NAME, C.CONTROL_NAMED, M.VOLUME, M.MAINPROG_HIDFLAG
    FROM decanet.subj J JOIN
         decanet.mprogsubj U USING (SUBJ_ID) LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID)
    WHERE U.MAINPROG_ID = MP_ID
    ORDER BY J.SUBJ_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MPROGITEM_LST TO A,D,Z,S,V $$

-- список оценок активных студентов по пункту основной программы (IN - MPROG_ID)
-- для анализа невозможности удаления
DROP PROCEDURE IF EXISTS decanet.MPROGACAD_LST $$
CREATE PROCEDURE decanet.MPROGACAD_LST(IN MP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SG.STUDSGRP_ID, DS.SEMESTR,
         SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         S.STUDENT_ZACHNO, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         U.MPROGSUBJ_ID, J.SUBJ_ABBR,
         DT.DOCTYPE_ID, DT.DOCTYPE_ABBR,
         D.DOCUMENT_ID, D.DOCUMENT_NO, D.DOCUMENT_INDATE,
         DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS,
         R.RESULT_ID, R.RESULT_ABBR
    FROM decanet.mainprog M LEFT JOIN
         decanet.persprog P USING (MAINPROG_ID) LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.dsession DS USING (STREAM_ID, DSESSION_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.mprogsubj U USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype DT USING (DOCTYPE_ID)
    WHERE M.MAINPROG_ID = MP_ID AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          A.ACAD_ID IS NOT NULL
    ORDER BY SGROUPAUTONAME(G.SGROUP_ID), S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MPROGACAD_LST TO A,D,Z,S,V $$


-- сроки сессий ITM
DROP PROCEDURE IF EXISTS decanet.DSESSION_ITM $$
CREATE PROCEDURE decanet.DSESSION_ITM(IN DIV_ID INT, IN FY YEAR, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  SELECT E.DSESSION_ID, E.DSESSION_BEGDATE, E.DSESSION_ENDDATE,
         IF(E.SEMESTR MOD 2, 'Зимняя', 'Летняя') AS DSESSTYPE,
         CONCAT(R.STREAM_FROMYEAR + FLOOR(E.SEMESTR / 2 + 0.5) - 1, '/', R.STREAM_FROMYEAR + FLOOR(E.SEMESTR / 2 + 0.5)) AS UYEAR
    FROM decanet.stream R LEFT JOIN
         decanet.dsession E USING (STREAM_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = FY AND
          E.SEMESTR = SEM;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DSESSION_ITM TO A,D,Z,S,V $$

-- сроки сессий CNG
DROP PROCEDURE IF EXISTS decanet.DSESSION_CNG $$
CREATE PROCEDURE decanet.DSESSION_CNG(IN DSESS_ID INT, IN BD DATE, IN ED DATE)
COMMENT 'DZ'
BEGIN
  UPDATE decanet.dsession
    SET DSESSION_BEGDATE = BD,
        DSESSION_ENDDATE = ED
    WHERE DSESSION_ID = DSESS_ID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DSESSION_CNG TO D,Z $$

-- задание кол-ва семестров потока
DROP PROCEDURE IF EXISTS decanet.STREAM_CNG $$
CREATE PROCEDURE decanet.STREAM_CNG(IN DIV_ID INT, IN FY YEAR, IN SEMCNT INT)
COMMENT 'DZ'
BEGIN
  DECLARE FILLSEM INT;

  SELECT MAX(E.SEMESTR)
    INTO FILLSEM
    FROM decanet.stream R LEFT JOIN
         decanet.dsession E USING(STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = FY AND
          M.MAINPROG_ID IS NOT NULL
    GROUP BY R.STREAM_ID;

  IF (SEMCNT > 1) AND (SEMCNT < 21) AND (SEMCNT >= IFNULL(FILLSEM, 0)) THEN
    UPDATE decanet.stream
      SET STREAM_SEMCOUNT = SEMCNT
      WHERE DIVISION_ID = DIV_ID AND
            STREAM_FROMYEAR = FY;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.STREAM_CNG TO D,Z $$

-- диапазон годов для основной программы отделения LIST
DROP PROCEDURE IF EXISTS decanet.MPROGYEAR_LST $$
CREATE PROCEDURE decanet.MPROGYEAR_LST(IN DIV_ID INT, ACTIVE BOOL)
COMMENT 'ADZSV'
BEGIN
  SELECT DISTINCT R.STREAM_ID, R.STREAM_FROMYEAR,
         R.STREAM_FROMYEAR + FLOOR(STREAM_SEMCOUNT / 2 + 0.5) - 1 AS STREAM_TOYEAR
    FROM decanet.stream R LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID)
    WHERE D.DIVISION_ID = DIV_ID AND
          IF(ACTIVE IS NULL, TRUE, FSGROUP_ACTIVE(G.SGROUP_ID) = ACTIVE)
    ORDER BY R.STREAM_FROMYEAR DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MPROGYEAR_LST TO A,D,Z,S,V $$

-- основная программа семестра CNT
DROP PROCEDURE IF EXISTS decanet.MAINPROG_CNT $$
CREATE PROCEDURE decanet.MAINPROG_CNT(IN DIV_ID INT, IN FY YEAR, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(M.MAINPROG_ID) AS CNT
    FROM decanet.stream R LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = FY AND
          E.SEMESTR = SEM;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MAINPROG_CNT TO A,D,Z,S,V $$

-- основная программа семестра LIST
-- *КОНТРОЛЬ СТРОКОВОГО БЛОКА ПО MAINPROG_ID
DROP PROCEDURE IF EXISTS decanet.MAINPROG_LST $$
CREATE PROCEDURE decanet.MAINPROG_LST(IN DIV_ID INT, FY YEAR, IN SEM INT, IN PATT BOOL)  -- PATT - Пром. аттестация
COMMENT 'ADZSV'
BEGIN
  SELECT M.MAINPROG_ID,
         J.SUBJ_ABBR, J.SUBJ_NAME,
         M.VOLUME, M.CONTROL_ID, C.CONTROL_ABBR, C.CONTROL_NAME,
         M.MAINPROG_HIDFLAG,
         EXISTS (SELECT A.ACAD_ID
                   FROM decanet.persprog P JOIN
                        decanet.acad A USING (PERSPROG_ID)
                   WHERE P.MAINPROG_ID = M.MAINPROG_ID AND
                         FSTUDENT_ACTIVE(P.STUDSGRP_ID)) AS NOTDEL
    FROM decanet.mainprog M LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl PC USING (CONTROL_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = FY AND
          E.SEMESTR = SEM AND
          IF(PATT IS NULL, TRUE, IF(PATT, PC.SESSPHASE_ID = 1, PC.SESSPHASE_ID > 1))
    ORDER BY CONTROL_ID, MAINPROG_ID, SUBJ_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MAINPROG_LST TO A,D,Z,S,V $$


-- пункт основной программы CNT
-- (тут несколько строк при работе с набором дисциплин)
DROP PROCEDURE IF EXISTS decanet.GRPSEMMPROGITEM_CNT $$
CREATE PROCEDURE decanet.GRPSEMMPROGITEM_CNT(IN MPROG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(U.MPROGSUBJ_ID) AS CNT
    FROM decanet.mainprog M LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID)
    WHERE M.MAINPROG_ID = MPROG_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPSEMMPROGITEM_CNT TO A,D,Z,S,V $$

-- пункт основной программы
-- (тут несколько строк при работе с набором дисциплин)
DROP PROCEDURE IF EXISTS decanet.GRPSEMMPROGITEM_LST $$
CREATE PROCEDURE decanet.GRPSEMMPROGITEM_LST(IN MPROG_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE DOC_ID INT;

  -- определить ведомость
  SET DOC_ID = (SELECT MAX(D.DOCUMENT_ID)
                FROM decanet.mainprog M LEFT JOIN
                     decanet.mprogsubj S USING (MAINPROG_ID) LEFT JOIN
                     decanet.persprog P USING (MPROGSUBJ_ID) LEFT JOIN
                     decanet.progdoc R USING (PERSPROG_ID) LEFT JOIN
                     decanet.document D ON D.DOCUMENT_ID = R.DOCUMENT_ID AND
                                           D.DOCTYPE_ID = 1
                WHERE M.MAINPROG_ID = MPROG_ID);

  SELECT J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME,
         M.VOLUME, M.CONTROL_ID, C.CONTROL_ABBR, C.CONTROL_NAME,
         M.MAINPROG_HIDFLAG,
         D.DOCUMENT_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO, DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE
    FROM decanet.mainprog M LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.document D ON D.DOCUMENT_ID = DOC_ID LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE M.MAINPROG_ID = MPROG_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GRPSEMMPROGITEM_LST TO A,D,Z,S,V $$

-- добавление пункта основной программы с полными параметрами
DROP PROCEDURE IF EXISTS decanet.MAINPROG_ADD $$
CREATE PROCEDURE decanet.MAINPROG_ADD(IN DIV_ID INT, FY YEAR, IN SEM INT,
                                      IN CTRL_ID INT, IN SBJ_ID INT, IN VOL INT, IN HF BOOL)
COMMENT 'DZ'
BEGIN
  DECLARE MPROG_ID INT;
  DECLARE SBEG, SEND DATE;

  -- создание потока по необходимости
  IF NOT EXISTS (SELECT STREAM_ID FROM decanet.stream WHERE DIVISION_ID = DIV_ID AND STREAM_FROMYEAR = FY) THEN
    INSERT INTO decanet.stream (STREAM_ID, DIVISION_ID, STREAM_FROMYEAR, STREAM_SEMCOUNT)
      SELECT NULL, DIV_ID, FY, IFNULL(MAX(STREAM_SEMCOUNT), 10)
        FROM decanet.stream
        WHERE DIVISION_ID = DIV_ID;
  END IF;

  -- создание сессии по необходимости
  IF NOT EXISTS (SELECT DSESSION_ID
                   FROM decanet.dsession E LEFT JOIN
                        decanet.stream R USING (STREAM_ID)
                   WHERE R.DIVISION_ID = DIV_ID AND
                         R.STREAM_FROMYEAR = FY AND
                         E.SEMESTR = SEM) THEN
    INSERT INTO decanet.dsession (DSESSION_ID, STREAM_ID, SEMESTR)
      SELECT NULL, STREAM_ID, SEM
        FROM decanet.stream
        WHERE DIVISION_ID = DIV_ID AND
              STREAM_FROMYEAR = FY;
  END IF;

  INSERT INTO decanet.mainprog (MAINPROG_ID, DSESSION_ID, CONTROL_ID, VOLUME, MAINPROG_HIDFLAG)
    SELECT NULL, DSESSION_ID, CTRL_ID, VOL, HF
      FROM decanet.dsession E LEFT JOIN
           decanet.stream R USING (STREAM_ID)
      WHERE R.DIVISION_ID = DIV_ID AND
            R.STREAM_FROMYEAR = FY AND
            E.SEMESTR = SEM;

  SET MPROG_ID = LAST_INSERT_ID();

  INSERT INTO decanet.mprogsubj (MPROGSUBJ_ID, MAINPROG_ID, SUBJ_ID)
    VALUES (NULL, MPROG_ID, SBJ_ID);

  -- автосинхронизация персональной программы
  INSERT INTO decanet.persprog (PERSPROG_ID, STUDSGRP_ID, MAINPROG_ID, MPROGSUBJ_ID, VOLUME)
    SELECT NULL, SG.STUDSGRP_ID, M.MAINPROG_ID, MIN(U.MPROGSUBJ_ID), M.VOLUME
      FROM decanet.mainprog M LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
      WHERE FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            M.MAINPROG_ID = MPROG_ID AND
            P.PERSPROG_ID IS NULL
      GROUP BY M.MAINPROG_ID, SG.STUDENT_ID, E.SEMESTR;

  SELECT MPROG_ID AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MAINPROG_ADD TO D,Z $$

-- редактирование пункта основной программы
DROP PROCEDURE IF EXISTS decanet.MAINPROG_CNG $$
CREATE PROCEDURE decanet.MAINPROG_CNG(IN MPRG_ID INT, IN CTRL_ID INT, IN VOL INT, IN HIDF BOOL)
COMMENT 'DZ'
BEGIN
  UPDATE decanet.mainprog
    SET CONTROL_ID = CTRL_ID,
        VOLUME = VOL,
        MAINPROG_HIDFLAG = HIDF
  WHERE MAINPROG_ID = MPRG_ID;
  -- синхрочасы
  UPDATE decanet.persprog P LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID)
    SET P.VOLUME = M.VOLUME
    WHERE M.MAINPROG_ID = MPRG_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MAINPROG_CNG TO A,D,Z $$

-- удаление пункта основной программы
DROP PROCEDURE IF EXISTS decanet.MAINPROG_DEL $$
CREATE PROCEDURE decanet.MAINPROG_DEL(IN MPRG_ID INT)
COMMENT 'ADZ'
BEGIN
  -- удалять если нет оценок у активных студентов
  IF NOT EXISTS (SELECT A.ACAD_ID
                   FROM decanet.persprog P JOIN
                        decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                        decanet.studsgrp SG USING (STUDSGRP_ID)
                   WHERE P.MAINPROG_ID = MPRG_ID AND
                         FSTUDENT_ACTIVE(SG.STUDSGRP_ID)) THEN
    SET FOREIGN_KEY_CHECKS = 0;
    -- multidelete syntax
    DELETE decanet.acad, decanet.document, decanet.progdoc, decanet.persprog, decanet.mprogsubj, decanet.mainprog
      FROM decanet.mainprog LEFT JOIN
           decanet.mprogsubj USING (MAINPROG_ID) LEFT JOIN
           decanet.persprog USING (MAINPROG_ID) LEFT JOIN
           decanet.progdoc USING (PERSPROG_ID) LEFT JOIN
           decanet.document USING (DOCUMENT_ID) LEFT JOIN
           decanet.acad USING (PERSPROG_ID, DOCUMENT_ID)
      WHERE MAINPROG_ID = MPRG_ID;
    SET FOREIGN_KEY_CHECKS = 1;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.MAINPROG_DEL TO D,Z $$

-- строка пункта основной программы (вид контроля и часы)
DROP PROCEDURE IF EXISTS decanet.MPROGITEM_ITM $$
CREATE PROCEDURE decanet.MPROGITEM_ITM(IN MPID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT CONTROL_ID, VOLUME, MAINPROG_HIDFLAG
    FROM decanet.mainprog
    WHERE MAINPROG_ID = MPID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MPROGITEM_ITM TO A,D,Z,S,V $$

-- добавление дисциплины в пункт основной программы
DROP PROCEDURE IF EXISTS decanet.MPROGITEM_ADD $$
CREATE PROCEDURE decanet.MPROGITEM_ADD(IN MPROG_ID INT, IN SBJ_ID INT)
COMMENT 'DZ'
BEGIN
  -- проверка есть ли такая дисциплина в пункте основной программы
  IF NOT EXISTS (SELECT SUBJ_ID
                 FROM decanet.mprogsubj
                   WHERE MAINPROG_ID = MPROG_ID AND
                         SUBJ_ID = SBJ_ID) THEN
    INSERT INTO decanet.mprogsubj (MPROGSUBJ_ID, MAINPROG_ID, SUBJ_ID)
      VALUES (NULL, MPROG_ID, SBJ_ID);
    SELECT Last_Insert_ID() AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MPROGITEM_ADD TO D,Z $$

-- удаление дисциплины из пункта основной программы
DROP PROCEDURE IF EXISTS decanet.MPROGITEM_DEL $$
CREATE PROCEDURE decanet.MPROGITEM_DEL(IN MPSID INT)
COMMENT 'DZ'
BEGIN
  DECLARE MPID INT;
  IF NOT EXISTS (SELECT A.ACAD_ID
                   FROM decanet.mprogsubj U LEFT JOIN
                        decanet.persprog P USING (MPROGSUBJ_ID) JOIN
                        decanet.acad A USING (PERSPROG_ID)
                   WHERE U.MPROGSUBJ_ID = MPSID) THEN
    SET MPID = (SELECT MAINPROG_ID FROM decanet.mprogsubj WHERE MPROGSUBJ_ID = MPSID);
    IF (SELECT COUNT(MPROGSUBJ_ID) -- удалять только когда в пункте осн. программы есть два и более предмета
          FROM MPROGSUBJ
          WHERE MAINPROG_ID = MPID) > 1 THEN
      DELETE FROM decanet.mprogsubj
        WHERE MPROGSUBJ_ID = MPSID;
      SELECT 1 AS RES;
    ELSE
      SELECT 0 AS RES;
    END IF;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.MPROGITEM_DEL TO D,Z $$

-- посеместровый импорт основной программы другого года (на том-же отделении)
DROP PROCEDURE IF EXISTS decanet.IMPORTMPROG $$
CREATE PROCEDURE decanet.IMPORTMPROG(DIV_ID INT, IN SEM INT, IN FROMY YEAR, IN TOY YEAR)
COMMENT 'DZ'
BEGIN
  DECLARE NMPID, MPID, CTID, VL, HF INT;
  DECLARE done INT DEFAULT 0;

  DECLARE cTTMP CURSOR FOR
    SELECT DISTINCT M.MAINPROG_ID, M.CONTROL_ID, M.VOLUME, M.MAINPROG_HIDFLAG
      FROM decanet.mainprog M LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID)
      WHERE R.DIVISION_ID = DIV_ID AND
            R.STREAM_FROMYEAR = FROMY AND
            E.SEMESTR = SEM AND
           (M.CONTROL_ID, U.SUBJ_ID) NOT IN (SELECT M1.CONTROL_ID, U1.SUBJ_ID
                                               FROM decanet.mainprog M1 LEFT JOIN
                                                    decanet.mprogsubj U1 USING (MAINPROG_ID) LEFT JOIN
                                                    decanet.dsession E1 USING (DSESSION_ID) LEFT JOIN
                                                    decanet.stream R1 USING (STREAM_ID)
                                               WHERE R1.DIVISION_ID = DIV_ID AND
                                                     R1.STREAM_FROMYEAR = TOY AND
                                                     E1.SEMESTR = SEM);

  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

  -- создание потока по необходимости
  IF NOT EXISTS (SELECT STREAM_ID FROM decanet.stream WHERE DIVISION_ID = DIV_ID AND STREAM_FROMYEAR = TOY) THEN
    INSERT INTO decanet.stream (STREAM_ID, DIVISION_ID, STREAM_FROMYEAR, STREAM_SEMCOUNT)
      SELECT NULL, DIV_ID, FY, IFNULL(MAX(STREAM_SEMCOUNT), 10)
        FROM decanet.stream
        WHERE DIVISION_ID = DIV_ID;
  END IF;

  -- создание сессии по необходимости
  IF NOT EXISTS (SELECT DSESSION_ID
                   FROM decanet.dsession E LEFT JOIN
                        decanet.stream R USING (STREAM_ID)
                   WHERE R.DIVISION_ID = DIV_ID AND
                         R.STREAM_FROMYEAR = TOY AND
                         E.SEMESTR = SEM) THEN
    INSERT INTO decanet.dsession (DSESSION_ID, STREAM_ID, SEMESTR)
      SELECT NULL, STREAM_ID, SEM
        FROM decanet.stream
        WHERE DIVISION_ID = DIV_ID AND
              STREAM_FROMYEAR = TOY;
  END IF;

  OPEN cTTMP;
  REPEAT
    FETCH cTTMP INTO MPID, CTID, VL, HF;
    IF NOT done THEN
      INSERT INTO decanet.mainprog (MAINPROG_ID, DSESSION_ID, CONTROL_ID, VOLUME, MAINPROG_HIDFLAG)
        SELECT NULL, DSESSION_ID, CTID, VL, HF
          FROM decanet.dsession E LEFT JOIN
               decanet.stream R USING (STREAM_ID)
          WHERE R.DIVISION_ID = DIV_ID AND
                R.STREAM_FROMYEAR = TOY AND
                E.SEMESTR = SEM;
      SET NMPID = LAST_INSERT_ID();
      INSERT INTO decanet.mprogsubj (MPROGSUBJ_ID, MAINPROG_ID, SUBJ_ID)
        SELECT NULL, NMPID, SUBJ_ID
          FROM decanet.mprogsubj
          WHERE MAINPROG_ID = MPID;
    END IF;
  UNTIL done END REPEAT;
  CLOSE cTTMP;

  -- автосинхронизация персональной программы
  INSERT INTO decanet.persprog (PERSPROG_ID, STUDSGRP_ID, MAINPROG_ID, MPROGSUBJ_ID, VOLUME)
    SELECT NULL, SG.STUDSGRP_ID, M.MAINPROG_ID, MIN(U.MPROGSUBJ_ID), M.VOLUME
      FROM decanet.mainprog M LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
      WHERE R.DIVISION_ID = DIV_ID AND
            R.STREAM_FROMYEAR = TOY AND
            E.SEMESTR = SEM AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            P.PERSPROG_ID IS NULL
      GROUP BY M.MAINPROG_ID, SG.STUDENT_ID, E.SEMESTR;

  -- синхрочасы
  UPDATE decanet.mainprog M LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
    SET P.VOLUME = M.VOLUME
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = TOY AND
          E.SEMESTR = SEM AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID);

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.IMPORTMPROG TO D,Z $$


-- для отчета - основная программа отделения
DROP PROCEDURE IF EXISTS decanet.REP_MPROG $$
CREATE PROCEDURE decanet.REP_MPROG(DIV_ID INT, IN FROMY YEAR)
COMMENT 'ADZSV'
BEGIN
  SELECT M.MAINPROG_ID, E.SEMESTR, J.SUBJ_ABBR, J.SUBJ_NAME, C.CONTROL_ABBR, C.CONTROL_NAME, M.VOLUME
    FROM decanet.mainprog M LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID)
    WHERE R.DIVISION_ID = DIV_ID AND
          R.STREAM_FROMYEAR = FROMY
    ORDER BY E.SEMESTR, M.CONTROL_ID, M.MAINPROG_ID, J.SUBJ_NAME;
END$$
GRANT EXECUTE ON PROCEDURE decanet.REP_MPROG TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ОБРАЗОВАТЕЛЬНЫЕ СТАНДАРТЫ
-- ---------------------------------------------------------------------------------------------------
-- описание интерфейса:
-- в меню учебной программы отделения вставляем команду Стандарт
-- на странице:
--      CALL decanet.DIVGOS_ITM(DIVID INT) (DIVID - ID отделения)
-- Заголовок: Государственный образовательный стандарт:
--            GOSTITLE_CODE GOSTITLE_NAME
-- и состав разделов стандарта в таблице:
--      CALL decanet.gos_LST(GTITID INT)
-- столбцы таблицы:
-- Компонент (GOSCOMP_CODE); Цикл (GOSCYCLE_CODE); Раздел (GOS_NAME); Объем, час (GOS_VOL)

-- Каждая строка это ссылка на GOS_ID (в столбце Раздел) по которой отображаем состав раздела стандарта:
-- на странице:
--      CALL decanet.DIVGOS_ITM(DIVID INT);
--      CALL decanet.gos_ITM(GOSID INT);
-- Заголовок:  GOSTITLE_CODE GOSTITLE_NAME
--             Раздел: GOS_NAME Объем, час: GOS_VOL
-- и состав дисциплин в разделе:
--      CALL decanet.gsubj_LST(FID INT, GOSID INT)
--        FID - ID факультета
--        GOSID - ID раздела стандарта
-- столбцы таблицы:
-- Код (GSUBJ_CODE); Дисциплина (SUBJ_NAME); Аббревиатура (SUBJ_ABBR)

-- Каждая строка это ссылка на GSUBJ_ID (в солбце Дисциплтна) по которой отображаем форму для смены кода дисциплины:
-- в форме:
--      CALL decanet.gsubj_ITM(GSBJ_ID INT)
-- Заголовок: GOSTITLE_CODE GOSTITLE_NAME
--            Раздел: GOS_NAME Объем, час: GOS_VOL
--            Дисциплина: SUBJ_NAME (SUBJ_ABBR)
--
--      CALL decanet.gsubj_CNG(GSBJ_ID INT, CODE VARCHAR(10))

-- Каждую дисциплину раздела умеем удалять:
--      CALL decanet.gsubj_DEL(GSBJ_ID INT)
-- и добалять через выбор дисциплины по команде опций Добавить:
--      CALL decanet.gsubj_ADD(FID INT, GOSID INT, SBJ_ID INT)
--        FID - ID факультета из session,
--        GOSID - ID раздела стандарта
--        SBJ_ID - выбор дисциплины из CALL decanet.subj_LST(NULL)
--          механизм в точности повторяет выбор дисциплины по команде Добавить в Учебной программе отделения


-- список специализаций ГОС стандарта
DROP PROCEDURE IF EXISTS decanet.SUBSPEC_LST $$
CREATE PROCEDURE decanet.SUBSPEC_LST(GOSTID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SUBSPEC_ID, SUBSPEC_CODE, SUBSPEC_NAME
    FROM decanet.subspec
    WHERE GOSTITLE_ID = GOSTID
    ORDER BY SUBSPEC_CODE;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GOSTITLE_LST TO A,D,Z,S,V $$

-- стандарт отделения
DROP PROCEDURE IF EXISTS decanet.DIVGOS_ITM $$
CREATE PROCEDURE decanet.DIVGOS_ITM(DIVID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT GOSTITLE_ID, GOSTITLE_CODE, GOSTITLE_NAME
    FROM decanet.gostitle T LEFT JOIN
         decanet.division V USING (GOSTITLE_ID)
    WHERE V.DIVISION_ID = DIVID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.DIVGOS_ITM TO A,D,Z,S,V $$

-- состав разделов стандарта
DROP PROCEDURE IF EXISTS decanet.GOS_LST $$
CREATE PROCEDURE decanet.GOS_LST(GTITID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT GOS_ID, GOSTITLE_ID,
         GOSCOMP_ID, GOSCOMP_CODE, GOSCOMP_NAME,
         GOSCYCLE_ID, GOSCYCLE_CODE, GOSCYCLE_NAME,
         GOS_CODE, GOS_NAME, GOS_VOL,
         COUNT(J.GSUBJ_ID) AS GOS_CNT
    FROM decanet.gos G LEFT JOIN
         decanet.goscomp C USING (GOSCOMP_ID) LEFT JOIN
         decanet.goscycle Y USING (GOSCYCLE_ID) LEFT JOIN
         decanet.gsubj J USING (GOS_ID)
    WHERE G.GOSTITLE_ID = GTITID
    GROUP BY G.GOS_ID
    ORDER BY G.GOS_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GOS_LST TO A,D,Z,S,V $$

-- строка раздела стандарта
DROP PROCEDURE IF EXISTS decanet.GOS_ITM $$
CREATE PROCEDURE decanet.GOS_ITM(GOSID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT GOS_ID, GOSTITLE_ID,
         GOSCOMP_ID, GOSCOMP_CODE, GOSCOMP_NAME,
         GOSCYCLE_ID, GOSCYCLE_CODE, GOSCYCLE_NAME,
         GOS_NAME, GOS_VOL
    FROM decanet.gos G LEFT JOIN
         decanet.goscomp C USING (GOSCOMP_ID) LEFT JOIN
         decanet.goscycle Y USING (GOSCYCLE_ID)
    WHERE G.GOS_ID = GOSID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GOS_ITM TO A,D,Z,S,V $$

-- состав дисциплин стандарта
DROP PROCEDURE IF EXISTS decanet.GSUBJ_LST $$
CREATE PROCEDURE decanet.GSUBJ_LST(FID INT, GOSID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT GSUBJ_ID, GSUBJ_CODE, SUBJ_ID, SUBJ_ABBR, SUBJ_NAME
    FROM decanet.gsubj J LEFT JOIN
         decanet.subj USING (SUBJ_ID)
    WHERE J.GOS_ID = GOSID AND
          J.FACULTET_ID = FID
    ORDER BY GSUBJ_CODE;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GSUBJ_LST TO A,D,Z,S,V $$

-- строка дисциплины в разделе стандарта
DROP PROCEDURE IF EXISTS decanet.GSUBJ_ITM $$
CREATE PROCEDURE decanet.GSUBJ_ITM(GSBJ_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT GSUBJ_ID, GSUBJ_CODE, SUBJ_ID, SUBJ_ABBR, SUBJ_NAME
    FROM decanet.gsubj J LEFT JOIN
         decanet.subj USING (SUBJ_ID)
    WHERE J.GSUBJ_ID = GSBJ_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GSUBJ_ITM TO A,D,Z,S,V $$

-- добавить дисциплину в стандарт
DROP PROCEDURE IF EXISTS decanet.GSUBJ_ADD $$
CREATE PROCEDURE decanet.GSUBJ_ADD(FID INT, GOSID INT, SBJ_ID INT)
COMMENT 'DZ'
BEGIN
  DECLARE GC VARCHAR(10);
  DECLARE GJID, GJCNT INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES; -- SQL - ошибка

  INSERT INTO decanet.gsubj(GSUBJ_ID, FACULTET_ID, GOS_ID, SUBJ_ID, GSUBJ_CODE)
    VALUES (NULL, FID, GOSID, SBJ_ID, '');
  SET GJID = Last_Insert_Id();

  SELECT COUNT(GSUBJ_ID)
    INTO GJCNT
    FROM decanet.gsubj
    WHERE GOS_ID = GOSID AND
          FACULTET_ID = FID;

  SELECT GOS_CODE
    INTO GC
    FROM decanet.gos
    WHERE GOS_ID = GOSID;

  SET GC = CONCAT(GC, '.', GJCNT);
  UPDATE decanet.gsubj
    SET GSUBJ_CODE = GC
    WHERE GSUBJ_ID = GJID;

  SELECT GJID AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GSUBJ_ADD TO D,Z $$

-- изменить код дисциплины в стандарте
DROP PROCEDURE IF EXISTS decanet.GSUBJ_CNG $$
CREATE PROCEDURE decanet.GSUBJ_CNG(GSBJ_ID INT, CODE VARCHAR(25))
COMMENT 'DZ'
BEGIN
  UPDATE decanet.gsubj
    SET GSUBJ_CODE = CODE
    WHERE GSUBJ_ID = GSBJ_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GSUBJ_ADD TO D,Z $$

-- удалить дисциплину из стандарта
DROP PROCEDURE IF EXISTS decanet.GSUBJ_DEL $$
CREATE PROCEDURE decanet.GSUBJ_DEL(GSBJ_ID INT)
COMMENT 'DZ'
BEGIN
  DELETE FROM decanet.gsubj
    WHERE GSUBJ_ID = GSBJ_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GSUBJ_DEL TO D,Z $$

-- для отчета ГОС
DROP PROCEDURE IF EXISTS decanet.GOS_REP $$
CREATE PROCEDURE decanet.GOS_REP(DIVID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT C.GOSCOMP_CODE, Y.GOSCYCLE_CODE, G.GOS_CODE, G.GOS_NAME, G.GOS_VOL, -- подзаголовок
         GSUBJ_CODE, SUBJ_NAME, SUBJ_ABBR
    FROM decanet.division V LEFT JOIN
         decanet.gos G USING (GOSTITLE_ID) LEFT JOIN
         decanet.goscomp C USING (GOSCOMP_ID) LEFT JOIN
         decanet.goscycle Y USING (GOSCYCLE_ID) LEFT JOIN
         decanet.gsubj U USING (GOS_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID)
    WHERE V.DIVISION_ID = DIVID
    ORDER BY Y.GOSCYCLE_ID, G.GOS_ID, G.GOS_NAME, J.SUBJ_NAME;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GOS_REP TO A,D,Z,S,V $$

/*
-- список групп стандартов
DROP PROCEDURE IF EXISTS decanet.GOSGROUP_LST $$
CREATE PROCEDURE decanet.GOSGROUP_LST()
COMMENT 'ADZ'
BEGIN
  DECLARE BN VARCHAR(255);
  DECLARE SCH_ID, FAC_ID, DIV_ID INT;

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT SCHOOL_ID, FACULTET_ID, DIVISION_ID
    INTO SCH_ID, FAC_ID, DIV_ID
    FROM decanet.duser
--      WHERE DUSER_ID = 3 LIMIT 1;
    WHERE BUNAME = BN LIMIT 1;

  SELECT DISTINCT GOSGROUP_ID, GOSGROUP_CODE, GOSGROUP_NAME
    FROM decanet.gosgroup G LEFT JOIN
         decanet.gosdir D USING (GOSGROUP_ID) LEFT JOIN
         decanet.gostitle T USING (GOSDIR_ID) LEFT JOIN
         decanet.division V USING (GOSTITLE_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school S USING (SCHOOL_ID)
    WHERE IF(SCH_ID IS NULL, true, SCH_ID = S.SCHOOL_ID) AND
          IF(FAC_ID IS NULL, true, FAC_ID = F.FACULTET_ID) AND
          IF(DIV_ID IS NULL, true, DIV_ID = V.DIVISION_ID);
END$$
*/
/*
-- список направлений стандартов
DROP PROCEDURE IF EXISTS decanet.GOSDIR_LST $$
CREATE PROCEDURE decanet.GOSDIR_LST(GGRPID INT)
COMMENT 'ADZ'
BEGIN
  DECLARE BN VARCHAR(255);
  DECLARE SCH_ID, FAC_ID, DIV_ID INT;

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT SCHOOL_ID, FACULTET_ID, DIVISION_ID
    INTO SCH_ID, FAC_ID, DIV_ID
    FROM decanet.duser
--      WHERE DUSER_ID = 3 LIMIT 1;
    WHERE BUNAME = BN LIMIT 1;

  SELECT DISTINCT GOSDIR_ID, GOSDIR_CODE, GOSDIR_NAME
    FROM decanet.gosdir D LEFT JOIN
         decanet.gostitle T USING (GOSDIR_ID) LEFT JOIN
         decanet.division V USING (GOSTITLE_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school S USING (SCHOOL_ID)
    WHERE IF(SCH_ID IS NULL, true, SCH_ID = S.SCHOOL_ID) AND
          IF(FAC_ID IS NULL, true, FAC_ID = F.FACULTET_ID) AND
          IF(DIV_ID IS NULL, true, DIV_ID = V.DIVISION_ID) AND
          D.GOSGROUP_ID = GGRPID;
END$$
*/

-- список ГОС стандартов
DROP PROCEDURE IF EXISTS decanet.GOSTITLE_LST $$
CREATE PROCEDURE decanet.GOSTITLE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT GOSTITLE_ID, GOSTITLE_CODE, GOSTITLE_NAME, CONCAT(GOSTITLE_CODE, ' ', GOSTITLE_NAME) AS GOSTITLE_CODENAME
    FROM decanet.gostitle
    ORDER BY GOSTITLE_CODE;
END$$
GRANT EXECUTE ON PROCEDURE decanet.GOSTITLE_LST TO A,D,Z,S,V $$

/*
-- список ГОС стандартов
DROP PROCEDURE IF EXISTS decanet.GOSTITLE_LST $$
CREATE PROCEDURE decanet.GOSTITLE_LST(GDIRID INT)
COMMENT 'ADZ'
BEGIN
  DECLARE BN VARCHAR(255);
  DECLARE SCH_ID, FAC_ID, DIV_ID INT;

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT SCHOOL_ID, FACULTET_ID, DIVISION_ID
    INTO SCH_ID, FAC_ID, DIV_ID
    FROM decanet.duser
--      WHERE DUSER_ID = 3 LIMIT 1;
    WHERE BUNAME = BN LIMIT 1;

  SELECT DISTINCT GOSTITLE_ID, GOSTITLE_CODE, GOSTITLE_NAME
    FROM decanet.gostitle T LEFT JOIN
         decanet.division V USING (GOSTITLE_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school S USING (SCHOOL_ID)
    WHERE IF(SCH_ID IS NULL, true, SCH_ID = S.SCHOOL_ID) AND
          IF(FAC_ID IS NULL, true, FAC_ID = F.FACULTET_ID) AND
          IF(DIV_ID IS NULL, true, DIV_ID = V.DIVISION_ID) AND
          T.GOSTITLE_ID = GDIRID;
END$$
*/

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . СПРАВОЧНИК ДИСЦИПЛИН
-- ---------------------------------------------------------------------------------------------------

/*
-- список дисциплин c разнесением по предметным областям CNT
DROP PROCEDURE IF EXISTS decanet.subj_CNT $$
CREATE PROCEDURE decanet.subj_CNT (IN SREG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(L.ID) AS CNT FROM
    (SELECT S.SUBREG_ID AS ID
       FROM SUBREG S WHERE SREG_ID IS NULL
     UNION ALL
     SELECT J.SUBJ_ID
       FROM SUBREGSUB R JOIN decanet.subj J ON J.SUBJ_ID = R.SUBJ_ID
       WHERE R.SUBREG_ID = SREG_ID
     UNION ALL
     SELECT J.SUBJ_ID
       FROM decanet.subj J LEFT JOIN SUBREGSUB R ON J.SUBJ_ID = R.SUBJ_ID
       WHERE R.SUBREG_ID IS NULL AND SREG_ID IS NULL) L;
END $$

-- список дисциплин c разнесением по предметным областям LIST
DROP PROCEDURE IF EXISTS decanet.subj_LST $$
CREATE PROCEDURE decanet.subj_LST (IN SREG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT Y.*,
         EXISTS (SELECT SUBJ_ID FROM decanet.mprogsubj G WHERE G.SUBJ_ID = Y.SUBJ_ID) AS NOTDEL
    FROM
   (SELECT S.SUBREG_ID, NULL AS SUBJ_ID, NULL AS ABBR, S.SUBREG_NAME AS NAME, NULL AS CODE, 0 AS EFLAG
      FROM SUBREG S
      WHERE SREG_ID IS NULL
    UNION ALL
    SELECT R.SUBREG_ID, J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_CODE, 1
      FROM SUBREGSUB R JOIN
           decanet.subj J USING(SUBJ_ID)
      WHERE R.SUBREG_ID = SREG_ID
    UNION ALL
    SELECT NULL, J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_CODE, 1
      FROM decanet.subj J LEFT JOIN
           SUBREGSUB R ON J.SUBJ_ID = R.SUBJ_ID
      WHERE R.SUBREG_ID IS NULL AND SREG_ID IS NULL) Y
  ORDER BY EFLAG, NAME;
END $$
*/

-- глобальный список дисциплин CNT
DROP PROCEDURE IF EXISTS decanet.SUBJ_CNT $$
CREATE PROCEDURE decanet.SUBJ_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(J.SUBJ_ID) AS CNT
    FROM decanet.subj J;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_CNT TO A,D,Z,S,V $$

-- глобальный список дисциплин LIST
DROP PROCEDURE IF EXISTS decanet.SUBJ_LST $$
CREATE PROCEDURE decanet.SUBJ_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_DESC,
         EXISTS (SELECT M.MPROGSUBJ_ID
                   FROM decanet.mprogsubj M
                   WHERE M.SUBJ_ID = J.SUBJ_ID) AS NOTDEL
    FROM decanet.subj J
    ORDER BY J.SUBJ_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_LST TO A,D,Z,S,V $$

-- поиск по глобальному списку дисциплин CNT
DROP PROCEDURE IF EXISTS decanet.FND_SUBJ_CNT $$
CREATE PROCEDURE decanet.FND_SUBJ_CNT(IN PATT VARCHAR(255))
COMMENT 'ADZSV'
BEGIN
  IF NOT LOCATE('%', PATT) THEN
    SET PATT = CONCAT('%', PATT, '%');
  END IF;

  SELECT COUNT(J.SUBJ_ID) AS CNT
    FROM decanet.subj J
    WHERE SUBJ_ABBR LIKE PATT OR
          SUBJ_NAME LIKE PATT;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_SUBJ_CNT TO A,D,Z,S,V $$

-- поиск по глобальному списку дисциплин LIST
-- PATT может быть NULL
DROP PROCEDURE IF EXISTS decanet.FND_SUBJ_LST $$
CREATE PROCEDURE decanet.FND_SUBJ_LST(IN PATT VARCHAR(255))
COMMENT 'ADZSV'
BEGIN
  IF NOT LOCATE('%', PATT) THEN
    SET PATT = CONCAT('%', PATT, '%');
  END IF;

  SELECT J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_DESC,
         EXISTS (SELECT M.MPROGSUBJ_ID
                   FROM decanet.mprogsubj M
                   WHERE M.SUBJ_ID = J.SUBJ_ID) AS NOTDEL
    FROM decanet.subj J
    WHERE IF(PATT IS NULL, true,
                           SUBJ_ABBR LIKE PATT OR SUBJ_NAME LIKE PATT)
    ORDER BY J.SUBJ_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_SUBJ_LST TO A,D,Z,S,V $$

-- поиск по ГОС-списку дисциплин факультта LIST
-- PATT может быть NULL
DROP PROCEDURE IF EXISTS decanet.FND_GSUBJ_LST $$
CREATE PROCEDURE decanet.FND_GSUBJ_LST(IN DIVID INT, IN PATT VARCHAR(255))
COMMENT 'ADZSV'
BEGIN
  IF NOT LOCATE('%', PATT) THEN
    SET PATT = CONCAT('%', PATT, '%');
  END IF;

  SELECT J.SUBJ_ID, G.GSUBJ_CODE, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_DESC,
         EXISTS (SELECT M.MPROGSUBJ_ID
                   FROM decanet.mprogsubj M
                   WHERE M.SUBJ_ID = J.SUBJ_ID) AS NOTDEL
    FROM decanet.subj J LEFT JOIN
         decanet.gsubj G USING (SUBJ_ID) LEFT JOIN
         decanet.gos S USING (GOS_ID) LEFT JOIN
         decanet.division D USING (FACULTET_ID)
    WHERE D.DIVISION_ID = DIVID AND
          IF(PATT IS NULL, true,
                           SUBJ_ABBR LIKE PATT OR SUBJ_NAME LIKE PATT)
    ORDER BY J.SUBJ_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_GSUBJ_LST TO A,D,Z,S,V $$

-- строка дисциплины
DROP PROCEDURE IF EXISTS decanet.SUBJ_ITM $$
CREATE PROCEDURE decanet.SUBJ_ITM(IN SBJID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT J.SUBJ_ID, J.SUBJ_ABBR, J.SUBJ_NAME, J.SUBJ_DESC
    FROM decanet.subj J
    WHERE J.SUBJ_ID = SBJID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_ITM TO A,D,Z,S,V $$

-- правка дисциплины
DROP PROCEDURE IF EXISTS decanet.SUBJ_CNG $$
CREATE PROCEDURE decanet.SUBJ_CNG(IN SBJID INT, IN S_NAME VARCHAR(255), IN S_ABBR VARCHAR(25), IN S_DESC VARCHAR(255))
COMMENT 'DZS'
BEGIN
  UPDATE decanet.subj
    SET SUBJ_ABBR = S_ABBR,
        SUBJ_NAME = S_NAME,
        SUBJ_DESC = S_DESC
    WHERE SUBJ_ID = SBJID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_CNG TO D,Z,S $$

-- добавление дисциплины
DROP PROCEDURE IF EXISTS decanet.SUBJ_ADD $$
CREATE PROCEDURE decanet.SUBJ_ADD(IN S_ABBR VARCHAR(25), IN S_NAME VARCHAR(255), IN S_DESC VARCHAR(255))
COMMENT 'DZS'
BEGIN
  INSERT INTO decanet.subj (SUBJ_ID, SUBJ_ABBR, SUBJ_NAME, SUBJ_DESC)
    VALUES(NULL, S_ABBR, S_NAME, S_DESC);

  SELECT Last_Insert_ID() AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_ADD TO D,Z,S $$

-- удаление дисциплины
DROP PROCEDURE IF EXISTS decanet.SUBJ_DEL $$
CREATE PROCEDURE decanet.SUBJ_DEL(IN SBJID INT)
COMMENT 'DZS'
BEGIN
  DELETE FROM decanet.subj
    WHERE SUBJ_ID = SBJID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SUBJ_DEL TO D,Z,S $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ IX. ОБЩИЕ ДАННЫЕ СТУДЕНТА
-- ---------------------------------------------------------------------------------------------------

-- личные данные студента
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDADD_ITM $$
CREATE PROCEDURE decanet.STUDADD_ITM(IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT H.SCHOOL_NAME, F.FACULTET_NAME, D.DIVISION_NAME,
         SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUP_AUTONAME,
         SG.EDUFORM_ID,
         E.EDUFORM_NAME,
         S.STUDENT_PERSNO, S.STUDENT_ZACHNO, S.STUDENT_STRAHNO,
         S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         CAST(A.STUDENT_SEX AS UNSIGNED) AS STUDENT_SEXID,
         A.STUDENT_SEX,
         A.STUDENT_PASSPNO,
         A.CITY_ID,
         -- CONCAT(C.CITY_NAME, ' (', R.REGION_NAME, ')') AS CITY_NAME,
         A.STUDENT_POSTINDEX,
         A.STUDENT_NPUNKT, A.STUDENT_STREET, A.STUDENT_BLDNO, A.STUDENT_FLATNO, A.STUDENT_BIRTHDAY,
         -- N.COUNTRY_SNAME,
         A.COUNTRY_ID,
         CAST(A.STUDENT_FAMSTATE AS UNSIGNED) AS STUDENT_FAMSTATEID,
         A.STUDENT_FAMSTATE,
         A.STUDENT_FATHER, A.STUDENT_FATHERWORK,
         A.STUDENT_MOTHER, A.STUDENT_MOTHERWORK, A.STUDENT_EMAIL, A.STUDENT_PHONE1,
         A.STUDENT_PHONE2, A.STUDENT_PHONE3, A.STUDENT_OBADDR,
         -- L.FOREIGNLAN_NAME,
         A.FOREIGNLAN_ID,
         A.STUDENT_FIRM, A.STUDENT_ADDWORK, A.STUDENT_FIRSTWORK, A.STUDENT_PHOTOPATH,
         A.STUDENT_DESC
  FROM decanet.school H LEFT JOIN
       decanet.facultet F USING (SCHOOL_ID) LEFT JOIN
       decanet.division D USING (FACULTET_ID) LEFT JOIN
       decanet.stream R USING (DIVISION_ID) LEFT JOIN
       decanet.sgroup G USING (STREAM_ID) LEFT JOIN
       decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
       decanet.student S USING (STUDENT_ID) LEFT JOIN
       decanet.studadd A ON S.STUDENT_ID = A.STUDENT_ID LEFT JOIN
       decanet.eduform E USING (EDUFORM_ID)
       -- LEFT JOIN
       -- decanet.city C ON A.CITY_ID = C.CITY_ID LEFT JOIN
       -- decanet.region R USING (REGION_ID) LEFT JOIN
       -- decanet.country N ON A.COUNTRY_ID = N.COUNTRY_ID LEFT JOIN
       -- decanet.foreignlan L USING (FOREIGNLAN_ID)
  WHERE SG.STUDSGRP_ID = SSG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDADD_ITM TO A,D,Z,S,V $$

-- изменение личных данных студента
DROP PROCEDURE IF EXISTS decanet.STUDADD_CNG $$
CREATE PROCEDURE decanet.STUDADD_CNG(IN SSG_ID INT,
                                     IN EDUF_ID INT,
                                     IN SPERSNO VARCHAR(25),
                                     IN SZACHNO VARCHAR(25),
                                     IN SSTRAHNO VARCHAR(25),
                                     IN SFNAME VARCHAR(50),
                                     IN SMNAME VARCHAR(50),
                                     IN SLNAME VARCHAR(50),
                                     IN SSEX INT,
                                     IN SPASPNO VARCHAR(255),
                                     IN CIT_ID INT,
                                     IN SPOSTIND INT,
                                     IN SNPUNKT VARCHAR(100),
                                     IN SSTR VARCHAR(100),
                                     IN SBLDNO VARCHAR(10),
                                     IN SFLTNO VARCHAR(10),
                                     IN SBDAY DATE,
                                     IN CNT_ID INT,
                                     IN SFAMS INT,
                                     IN SFAT VARCHAR(100),
                                     IN SFATW VARCHAR(100),
                                     IN SMOTH VARCHAR(100),
                                     IN SMOTHW VARCHAR(100),
                                     IN SEMAIL VARCHAR(100),
                                     IN SPH1 VARCHAR(15),
                                     IN SPH2 VARCHAR(15),
                                     IN SPH3 VARCHAR(15),
                                     IN SOBADR VARCHAR(20),
                                     IN FL_ID INT,
                                     IN SFIRM VARCHAR(100),
                                     IN SAWRK VARCHAR(255),
                                     IN SFWRK VARCHAR(255),
                                     IN SPHOTO VARCHAR(255),
                                     IN SDESC TINYTEXT)
COMMENT 'DZS'
BEGIN
  UPDATE decanet.studsgrp SG LEFT JOIN
         decanet.student S USING (STUDENT_ID)
    SET SG.EDUFORM_ID = EDUF_ID,
        S.STUDENT_PERSNO = SPERSNO,
        S.STUDENT_ZACHNO = SZACHNO,
        S.STUDENT_STRAHNO = SSTRAHNO,
        S.STUDENT_FNAME = SFNAME,
        S.STUDENT_MNAME = SMNAME,
        S.STUDENT_LNAME = SLNAME
  WHERE SG.STUDSGRP_ID = SSG_ID;

  UPDATE decanet.studsgrp SG LEFT JOIN
         decanet.studadd S USING (STUDENT_ID)
    SET S.STUDENT_SEX = SSEX,
        S.STUDENT_PASSPNO = SPASPNO,
        S.CITY_ID = CIT_ID,
        S.STUDENT_POSTINDEX = SPOSTIND,
        S.STUDENT_NPUNKT = SNPUNKT,
        S.STUDENT_STREET = SSTR,
        S.STUDENT_BLDNO = SBLDNO,
        S.STUDENT_FLATNO = SFLTNO,
        S.STUDENT_BIRTHDAY = SBDAY,
        S.COUNTRY_ID = CNT_ID,
        S.STUDENT_FAMSTATE = SFAMS,
        S.STUDENT_FATHER = SFAT,
        S.STUDENT_FATHERWORK = SFATW,
        S.STUDENT_MOTHER = SMOTH,
        S.STUDENT_MOTHERWORK = SMOTHW,
        S.STUDENT_EMAIL = SEMAIL,
        S.STUDENT_PHONE1 = SPH1,
        S.STUDENT_PHONE2 = SPH2,
        S.STUDENT_PHONE3 = SPH3,
        S.STUDENT_OBADDR = SOBADR,
        S.FOREIGNLAN_ID = FL_ID,
        S.STUDENT_FIRM = SFIRM,
        S.STUDENT_ADDWORK = SAWRK,
        S.STUDENT_FIRSTWORK = SFWRK,
        S.STUDENT_PHOTOPATH = SPHOTO,
        S.STUDENT_DESC = SDESC
  WHERE SG.STUDSGRP_ID = SSG_ID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDADD_CNG TO D,Z,S $$

-- установить старосту группы
DROP PROCEDURE IF EXISTS decanet.SGROUPBOSS_CNG $$
CREATE PROCEDURE decanet.SGROUPBOSS_CNG (IN SGRP_ID INT, IN STD_ID INT)
COMMENT 'DZS'
BEGIN
  UPDATE decanet.sgroup
    SET SBOSS_ID = STD_ID
    WHERE SGROUP_ID = SGRP_ID;
  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUPBOSS_CNG TO D,Z,S $$

-- ПЕРЕВОД ИЗ ГРУППЫ В ГРУППУ НА ОДНОМ ОТДЕЛЕНИИ
-- кол-во возможных групп для перевода студента в другую группу CNT
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDGROUP_CNT $$
CREATE PROCEDURE decanet.STUDGROUP_CNT (IN SSG_ID INT)
COMMENT 'ADZV'
BEGIN
  SELECT COUNT(P.SGROUP_ID) AS CNT
     FROM decanet.studsgrp SG LEFT JOIN
          decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
          decanet.stream R USING (STREAM_ID) LEFT JOIN
          decanet.sgroup P USING (STREAM_ID)
     WHERE SG.STUDSGRP_ID = SSG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDGROUP_CNT TO A,D,Z,V $$

-- список возможных групп для перевода студента в другую группу LIST
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDGROUP_LST $$
CREATE PROCEDURE decanet.STUDGROUP_LST (IN SSG_ID INT)
COMMENT 'ADZV'
BEGIN
  SELECT P.SGROUP_ID,
         R.STREAM_FROMYEAR,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SGROUPAUTONAME(P.SGROUP_ID) AS SGROUPAUTONAME
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.sgroup P USING (STREAM_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          G.SGROUP_ID <> P.SGROUP_ID
    ORDER BY P.SGROUP_NAMEINDEX;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDGROUP_LST TO A,D,Z,V $$

-- перевод студента в другую группу того-же отделения
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDGROUP_CNG $$
CREATE PROCEDURE decanet.STUDGROUP_CNG (IN SSG_ID INT, IN NEWSGROUP_ID INT)
COMMENT 'DZ'
BEGIN
  IF EXISTS (SELECT P.SGROUP_ID
               FROM decanet.studsgrp SG LEFT JOIN
                    decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
                    decanet.stream R USING (STREAM_ID) LEFT JOIN
                    decanet.sgroup P USING (STREAM_ID)
               WHERE SG.STUDSGRP_ID = SSG_ID AND
                     P.SGROUP_ID = NEWSGROUP_ID) THEN

    UPDATE decanet.studsgrp SG
      SET SG.SGROUP_ID = NEWSGROUP_ID
      WHERE SG.STUDSGRP_ID = SSG_ID;

    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDGROUP_CNG TO D,Z $$

-- перевод студентов из корзины в другую группу того-же отделения

-- тест - студенты в корзине из одного потока? для перевода из группы в группу
-- если не тест, то сообщаем о том,что в корзине находятся студенты из разных потоков
DROP PROCEDURE IF EXISTS decanet.BASKET_STUDGROUP_CNG_TEST $$
CREATE PROCEDURE decanet.BASKET_STUDGROUP_CNG_TEST()
COMMENT 'DZ'
BEGIN
  SELECT COUNT(DISTINCT R.STREAM_ID) = 1 AS RES
    FROM decanet.sysbasket LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID);
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_STUDGROUP_CNG_TEST TO D,Z $$

-- вызываем BASKET_STUDGROUP_CNG_TEST() для проверки возможности группового перевода
-- список возможных групп STUDGROUP_LST (IN DIV_ID INT, IN STD_ID INT) строим по первому студенту в корзине
DROP PROCEDURE IF EXISTS decanet.BASKET_STUDGROUP_CNG $$
CREATE PROCEDURE decanet.BASKET_STUDGROUP_CNG(IN NEWSGROUP_ID INT)
COMMENT 'DZ'
BEGIN
  IF EXISTS (SELECT P.SGROUP_ID
               FROM decanet.sysbasket LEFT JOIN
                    decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
                    decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
                    decanet.stream R USING (STREAM_ID) LEFT JOIN
                    decanet.sgroup P USING (STREAM_ID)
               WHERE P.SGROUP_ID = NEWSGROUP_ID) THEN

    UPDATE decanet.sysbasket B LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      SET SG.SGROUP_ID = NEWSGROUP_ID;

    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_STUDGROUP_CNG TO D,Z $$

-- контингентные состояния студента CNT
-- #SSG
DROP PROCEDURE IF EXISTS decanet.STUDCONT_CNT $$
CREATE PROCEDURE decanet.STUDCONT_CNT (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(C.CONTINGENT_ID) AS CNT
     FROM decanet.studsgrp SG LEFT JOIN
          decanet.contingent C USING (STUDSGRP_ID)
     WHERE SG.STUDSGRP_ID = SSG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDCONT_CNT TO A,D,Z,S,V $$

-- #SSG
-- контингентные состояния студента LST
DROP PROCEDURE IF EXISTS decanet.STUDCONT_LST $$
CREATE PROCEDURE decanet.STUDCONT_LST (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT D.DOCUMENT_ID, S.STUDSTATUS_NAME, S.STUDSTATUS_ACTIVE,
         V.DIVISION_ID, V.DIVISION_ABBR, C.STUDSTATUS_VALUE, C.CONTINGENT_DATE, C.CONTINGENT_DESC,
         T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         CAST(D.DOCUMENT_INDATE AS DATE) AS DOCUMENT_INDATE,
         DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS
    FROM decanet.studsgrp SSG LEFT JOIN
         decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.contingent C USING (STUDSGRP_ID) LEFT JOIN
         decanet.studstatus S USING (STUDSTATUS_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE SSG.STUDSGRP_ID = SSG_ID AND
          C.CONTINGENT_ID IS NOT NULL AND
          D.DOCUMENT_ID IS NOT NULL
    ORDER BY C.CONTINGENT_DATE;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDCONT_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ X. ПРОЦЕСС ЭКЗАМЕНАЦИОННОГО ЛИСТА
-- ---------------------------------------------------------------------------------------------------

-- ввод акад. документа
DROP PROCEDURE IF EXISTS decanet.ACADOCINPUT $$
CREATE PROCEDURE decanet.ACADOCINPUT(IN BARDATA VARCHAR(50))
COMMENT 'DZS'
BEGIN
  DECLARE DOC_NO VARCHAR(25);
  DECLARE RES_ID VARCHAR(25);

  -- парсим из BARDATA DOC_NO и RES_ID
  SET DOC_NO = '';
  SET RES_ID = NULL;
  SET DOC_NO = SUBSTRING_INDEX(BARDATA,'R',1);
  IF LOCATE('R', BARDATA) THEN
    SET RES_ID = SUBSTRING_INDEX(BARDATA,'R',-1);
  END IF;

  -- c проверкой наличия невведенного документа и валидности результата
  SELECT D.DOCUMENT_ID, D.DOCUMENT_NO, D.DOCTYPE_ID, D.DOCUMENT_OUTDATE, D.DOCUMENT_INDATE, RES_ID AS RESULT_ID
    FROM decanet.document D LEFT JOIN
         decanet.progdoc PD USING (DOCUMENT_ID) LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.resset RS USING (CONTROL_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID)
    WHERE D.DOCUMENT_BARNO = DOC_NO AND D.DOCUMENT_TEMPFLAG AND -- !! _BARNO
          IF(RES_ID IS NOT NULL, R.RESULT_ID = RES_ID, TRUE)
    LIMIT 1;

END $$
GRANT EXECUTE ON PROCEDURE decanet.ACADOCINPUT TO D,Z,S $$

-- выдача экзаменационного листа
DROP PROCEDURE IF EXISTS decanet.EKZL_ADD $$
CREATE PROCEDURE decanet.EKZL_ADD(IN PPROG_ID INT)
COMMENT 'DZS'
BEGIN
  DECLARE FID, DOC_ID INT;
  DECLARE CEF BOOL;

  SELECT V.FACULTET_ID, C.CONTROL_ENDFLAG INTO FID, CEF
    FROM decanet.persprog P LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.studsgrp SSG USING (STUDSGRP_ID) LEFT JOIN
         decanet.sgroup SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID
    WHERE P.PERSPROG_ID = PPROG_ID;

  -- 2 - тип документа - экзаменационный лист, 6 - протокол ГЭК
  INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE)
    SELECT NULL, IF(CEF, 6, 2), FID, TRUE, NOW();

  SET DOC_ID = LAST_INSERT_ID();

  UPDATE decanet.document D
    SET D.DOCUMENT_BARNO = CONCAT(FID, DOC_ID),
        D.DOCUMENT_NO = CONCAT(FID, DOC_ID)
    WHERE D.DOCUMENT_ID = DOC_ID;

  INSERT INTO decanet.progdoc (PROGDOC_ID, DOCUMENT_ID, PERSPROG_ID)
    VALUES (NULL, DOC_ID, PPROG_ID);

  SELECT DOC_ID AS RES;

END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZL_ADD TO D,Z,S $$

-- набор штрих кодов для листа / ведомости
DROP PROCEDURE IF EXISTS decanet.BARS_ITM $$
CREATE PROCEDURE decanet.BARS_ITM(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT NULL AS RESULT_ID, NULL AS RESULT_ABBR, D.DOCUMENT_BARNO AS BARCODE
    FROM decanet.document D
    WHERE D.DOCUMENT_ID = DOC_ID AND
          D.DOCTYPE_ID = 1 UNION
  SELECT R.RESULT_ID, R.RESULT_ABBR, CONCAT(D.DOCUMENT_BARNO, 'R', R.RESULT_ID) AS BARCODE
    FROM decanet.progdoc PD LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.resset RS USING (CONTROL_ID) LEFT JOIN
         decanet.result R USING (RESULT_ID)
    WHERE PD.DOCUMENT_ID = DOC_ID
    ORDER BY RESULT_ID
    LIMIT 11;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BARS_ITM TO A,D,Z,S,V $$

-- поиск данных для перерисовки или ввода экзаменационного листа
DROP PROCEDURE IF EXISTS decanet.EKZL_ITM $$
CREATE PROCEDURE decanet.EKZL_ITM(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE OLDDOC_ID, PPROG_ID INT;
  DECLARE DOC_NO, DOC_INDT, DOC_TYPE, RES, PERVPOVT VARCHAR(50);

  SELECT PERSPROG_ID INTO PPROG_ID
    FROM decanet.progdoc
    WHERE DOCUMENT_ID = DOC_ID
    LIMIT 1;

  SET PERVPOVT = 'Первично';
  SET DOC_INDT = NULL;
  SET DOC_TYPE = NULL;
  SET RES = NULL;

  SET OLDDOC_ID = (SELECT MAX(A.DOCUMENT_ID) FROM decanet.acad A
                   WHERE A.PERSPROG_ID = PPROG_ID AND DOCUMENT_ID <> DOC_ID);

  IF OLDDOC_ID IS NOT NULL THEN
    SET PERVPOVT = 'Повторно';
    SELECT D.DOCUMENT_NO,
           -- DATE_FORMAT(D.DOCUMENT_OUTDATE, '%d.%m.%Y') AS DOCUMENT_OUTDATE,
           DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
           T.DOCTYPE_ABBR, R.RESULT_NAME
      INTO DOC_NO, DOC_INDT, DOC_TYPE, RES
      FROM decanet.acad A LEFT JOIN
           decanet.document D USING (DOCUMENT_ID) LEFT JOIN
           decanet.doctype T USING (DOCTYPE_ID) LEFT JOIN
           decanet.result R USING (RESULT_ID)
      WHERE A.DOCUMENT_ID = OLDDOC_ID AND
            A.PERSPROG_ID = PPROG_ID;
  END IF;

  SELECT D.DOCUMENT_ID, D.DOCTYPE_ID, D.DOCUMENT_NO, D.DOCUMENT_TEMPFLAG,
         -- существующая дата ввода (для повт. ввода)
         DATE_FORMAT(D.DOCUMENT_OUTDATE, '%d.%m.%Y') AS DOCUMENT_OUTDATE,
         DATE_FORMAT(D.DOCUMENT_INDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         PERVPOVT, DOC_NO, DOC_INDT, DOC_TYPE, RES,
         A.RESULT_ID, -- существующий результат по этому листу (для повт. ввода)
         M.MAINPROG_ID, P.PERSPROG_ID, U.MPROGSUBJ_ID,
         E.SEMESTR, P.VOLUME, J.SUBJ_NAME, J.SUBJ_ABBR,
         C.CONTROL_ID, C.CONTROL_NAME, C.CONTROL_NAMED,
         H.SCHOOL_NAME, F.FACULTET_NAME, V.DIVISION_NAME,
         SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(T.STREAM_FROMYEAR, T.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         ROUND(GETSTUDCURSEM(SG.STUDSGRP_ID) / 2) AS KURS,
         S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
         S.STUDENT_PERSNO, S.STUDENT_ZACHNO,
         N.PERSNAME_NAME,
         -- существующий результат по этому листу (для повт. ввода)
         A.RESULT_ID AS CURRES_ID, L.RESULT_ABBR AS CURRES_ABBR,
         (SELECT COUNT(S.SUBJ_ID) FROM decanet.mprogsubj S WHERE S.MAINPROG_ID = M.MAINPROG_ID) AS SUBJSEL
    FROM decanet.document D LEFT JOIN
         decanet.progdoc R USING (DOCUMENT_ID) LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID) LEFT JOIN
         decanet.acad A USING (DOCUMENT_ID, PERSPROG_ID) LEFT JOIN
         decanet.result L USING (RESULT_ID) LEFT JOIN
         decanet.persname N USING (PERSPROG_ID) LEFT JOIN
         decanet.mprogsubj U USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream T USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = SG.DIVISION_ID LEFT JOIN
         decanet.facultet F ON F.FACULTET_ID = D.FACULTET_ID LEFT JOIN
         decanet.school H USING (SCHOOL_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.mainprog M ON M.MAINPROG_ID = U.MAINPROG_ID LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID)
    WHERE D.DOCUMENT_ID = DOC_ID AND
          D.DOCTYPE_ID IN (2, 6);
END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZL_ITM TO A,D,Z,S,V $$


-- ввод оценки с экзаменационного листа
DROP PROCEDURE IF EXISTS decanet.EKZL_CNG $$
CREATE PROCEDURE decanet.EKZL_CNG(IN DOC_ID INT, IN DOCNO VARCHAR(25), RES_ID INT, IN LDATE DATETIME)
COMMENT 'DZS'
BEGIN
  DECLARE ORID, PP_ID INT;
  DECLARE MAXINDT DATETIME;

  SELECT P.PERSPROG_ID INTO PP_ID
    FROM decanet.document D LEFT JOIN
         decanet.progdoc R USING (DOCUMENT_ID) LEFT JOIN
         decanet.persprog P USING (PERSPROG_ID)
    WHERE D.DOCUMENT_ID = DOC_ID AND
          D.DOCTYPE_ID IN (2, 6) AND
          D.DOCUMENT_TEMPFLAG;

  SET ORID = (SELECT A.RESULT_ID
                FROM decanet.persprog P LEFT JOIN
                     decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                     decanet.result R USING (RESULT_ID) LEFT JOIN
                     decanet.document D USING (DOCUMENT_ID)
                WHERE P.PERSPROG_ID = PP_ID AND
                      A.RESULT_ID = RES_ID AND
                      R.RESULT_PASSFLAG AND
                      NOT D.DOCUMENT_TEMPFLAG AND
                      D.DOCUMENT_ID <> DOC_ID);

  IF PP_ID IS NOT NULL AND ORID IS NULL THEN -- ORID - проверка имеющейся такой же оценки

    UPDATE decanet.document
      SET DOCUMENT_TEMPFLAG = TRUE,
          DOCUMENT_NO = DOCNO
      WHERE DOCUMENT_ID = DOC_ID;

    -- повторный ввод (сброс имеющейся оценки)
    DELETE FROM decanet.acad
      WHERE DOCUMENT_ID = DOC_ID AND
            PERSPROG_ID = PP_ID;

    IF RES_ID IS NOT NULL AND RES_ID > 0 THEN

      INSERT INTO decanet.acad (ACAD_ID, PERSPROG_ID, RESULT_ID, DOCUMENT_ID)
        VALUES (NULL, PP_ID, RES_ID, DOC_ID);

      UPDATE decanet.document D
        SET DOCUMENT_TEMPFLAG = FALSE,
            DOCUMENT_INDATE = IFNULL(LDATE, NOW())
        WHERE DOCUMENT_ID = DOC_ID;

    END IF;

    -- контроль совпадения дат
    SELECT MAX(D.DOCUMENT_INDATE)
      INTO MAXINDT
      FROM decanet.acad A LEFT JOIN
           decanet.document D USING (DOCUMENT_ID)
      WHERE A.PERSPROG_ID = PP_ID AND
            NOT D.DOCUMENT_TEMPFLAG AND
            D.DOCUMENT_ID <> DOC_ID;

    IF DATE_FORMAT(MAXINDT, '%d.%m.%Y') = DATE_FORMAT(LDATE, '%d.%m.%Y') THEN
      -- SET LDATE = MAXINDT + INTERVAL 1 SECOND;
      UPDATE decanet.document D
        SET DOCUMENT_INDATE = MAXINDT + INTERVAL 1 SECOND
        WHERE DOCUMENT_ID = DOC_ID;
    END IF;

    SELECT 1 AS RES;

  ELSE
    SELECT 0 AS RES;
  END IF;

END $$
GRANT EXECUTE ON PROCEDURE decanet.EKZL_CNG TO D,Z,S $$


-- ---------------------------------------------------------------------------------------------------
-- К О Н Т И Н Г Е Н Т
-- ---------------------------------------------------------------------------------------------------

-- определение статуса студента
-- ##SSG
/*
DROP FUNCTION IF EXISTS decanet.FSTUDENT_ACTIVE $$
CREATE FUNCTION decanet.FSTUDENT_ACTIVE(SSG_ID INT) RETURNS BOOL
BEGIN
  DECLARE FA BOOL;
  SET FA = (SELECT T.STUDSTATUS_ACTIVE
            FROM decanet.contingent C LEFT JOIN
                 decanet.studsgrp SG USING (STUDENT_ID, DIVISION_ID) LEFT JOIN
                 decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
                 decanet.document D USING (DOCUMENT_ID)
            WHERE SG.STUDSGRP_ID = SSG_ID AND
                  D.DOCUMENT_INDATE IS NOT NULL AND
                  NOT D.DOCUMENT_TEMPFLAG
            ORDER BY DOCUMENT_INDATE DESC
            LIMIT 1);
  RETURN IFNULL(FA, FALSE);
END $$
*/

DROP FUNCTION IF EXISTS decanet.FSTUDENT_ACTIVE $$
CREATE FUNCTION decanet.FSTUDENT_ACTIVE(SSG_ID INT) RETURNS BOOL
BEGIN
  DECLARE SSTAT BOOL;

  SET SSTAT = NULL;

  SELECT T.STUDSTATUS_ACTIVE
    INTO SSTAT
    FROM decanet.contingent C LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          D.DOCUMENT_INDATE IS NOT NULL AND
          NOT D.DOCUMENT_TEMPFLAG
    ORDER BY DOCUMENT_INDATE DESC, T.STUDSTATUS_ACTIVE DESC
    LIMIT 1;

  RETURN IFNULL(SSTAT, FALSE);
END $$

-- определение статуса студента на заданную дату
DROP FUNCTION IF EXISTS decanet.FDSTUD_ACTIVE $$
CREATE FUNCTION decanet.FDSTUD_ACTIVE(SSG_ID INT, D DATE) RETURNS BOOL
BEGIN
  RETURN (SELECT IFNULL(T.STUDSTATUS_ACTIVE, false)
            FROM decanet.contingent C LEFT JOIN
                 decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
                 decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
                 decanet.document D USING (DOCUMENT_ID)
            WHERE SG.STUDSGRP_ID = SSG_ID AND
                  D.DOCUMENT_INDATE IS NOT NULL AND
                  IF(D IS NULL, true, D.DOCUMENT_INDATE <= D) AND
                  NOT D.DOCUMENT_TEMPFLAG
            ORDER BY DOCUMENT_INDATE DESC, T.STUDSTATUS_ACTIVE DESC
            LIMIT 1);
END $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ. ПРИКАЗЫ ПО Л/СОСТАВУ
-- ---------------------------------------------------------------------------------------------------

-- новый (временный) приказ по л/составу
DROP PROCEDURE IF EXISTS decanet.LSDOC_ADD $$
CREATE PROCEDURE decanet.LSDOC_ADD(IN FAC_ID INT,
                                  IN D_NM VARCHAR(255),
                                  IN D_DS TINYTEXT)
COMMENT 'DZ'
BEGIN
  DECLARE DOC_ID, D_NO INT;
  DECLARE D_BARNO BIGINT;

  INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_NAME, DOCUMENT_DESC)
    VALUES(NULL, 3, FAC_ID, TRUE, Now(), D_NM, D_DS);

  SET DOC_ID = LAST_INSERT_ID();

  UPDATE decanet.document D
    SET D.DOCUMENT_BARNO = CONCAT(FAC_ID, DOC_ID),
        D.DOCUMENT_NO = CONCAT(FAC_ID, DOC_ID)
    WHERE D.DOCUMENT_ID = DOC_ID;

  SELECT DOC_ID AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOC_ADD TO A,D,Z $$

-- удалить приказ по л/составу
DROP PROCEDURE IF EXISTS decanet.LSDOC_DEL $$
CREATE PROCEDURE decanet.LSDOC_DEL(IN DOC_ID INT)
COMMENT 'ADZ'
BEGIN
  DECLARE DT, SD, CN INT;
  SET SD = NULL;
  SET CN = NULL;
  SET DT = (SELECT DOCTYPE_ID FROM decanet.document WHERE DOCUMENT_ID = DOC_ID);
  SET SD = (SELECT DOCUMENT_ID FROM decanet.STUDOC WHERE DOCUMENT_ID = DOC_ID LIMIT 1);
  SET CN = (SELECT DOCUMENT_ID FROM decanet.contingent WHERE DOCUMENT_ID = DOC_ID LIMIT 1);
  -- Континг
  IF DT = 3 AND SD IS NULL AND CN IS NULL THEN
    DELETE FROM decanet.document
      WHERE DOCUMENT_ID = DOC_ID;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOC_DEL TO D,Z $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ. КОНТИНГЕНТНЫЕ ОПЕРАЦИИ СТУДЕНТА
-- ---------------------------------------------------------------------------------------------------

-- в приказ (отчисенного еще раз в приказ)
-- снять ограничение на только отчисленных
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDDOC_ADD $$
CREATE PROCEDURE decanet.STUDDOC_ADD(IN SSG_ID INT, IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE)
COMMENT 'DZ'
BEGIN
  IF -- NOT FSTUDENT_ACTIVE(SSG_ID) AND
     DOC_ID IS NOT NULL AND
     STAT_ID IS NOT NULL AND
     CONT_DT IS NOT NULL THEN

    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, DOC_ID);
    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, STAT_ID, CONT_DT, DOC_ID);

    SELECT 1 AS RES;

  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDDOC_ADD TO D,Z $$


-- отчисляем (в интерфейсе применять только для активных студентов)
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDOTCH $$
CREATE PROCEDURE decanet.STUDOTCH(IN SSG_ID INT, IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE)
COMMENT 'DZ'
BEGIN
  IF FSTUDENT_ACTIVE(SSG_ID) AND
     DOC_ID IS NOT NULL AND
     STAT_ID IS NOT NULL AND
     CONT_DT IS NOT NULL THEN

    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, DOC_ID);
    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, STAT_ID, CONT_DT, DOC_ID);

    SELECT 1 AS RES;

  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDOTCH TO D,Z $$

-- отчисляем из корзины
DROP PROCEDURE IF EXISTS decanet.BASKET_STUDOTCH $$
CREATE PROCEDURE decanet.BASKET_STUDOTCH(IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE)
COMMENT 'DZ'
BEGIN
  IF DOC_ID IS NOT NULL AND
     STAT_ID IS NOT NULL AND
     CONT_DT IS NOT NULL THEN

    DELETE FROM decanet.sysbasket
      WHERE NOT FSTUDENT_ACTIVE(STUDSGRP_ID);

    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      SELECT NULL, B.STUDSGRP_ID, DOC_ID
        FROM decanet.sysbasket B;

    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      SELECT NULL, B.STUDSGRP_ID, STAT_ID, CONT_DT, DOC_ID
        FROM decanet.sysbasket B;

    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_STUDOTCH TO D,Z $$

-- зачисляем из корзины
-- ЗАЧИСЛЯЕМ ИМЕЮЩЕГОСЯ СТУДЕНТА НА ОБУЧЕНИЕ (например БАКАЛАВРА В МАГИCТРАТУРУ)
-- ! группа - куда зачисляем должна быть выбрана в объектах и берется оттуда (из session)
DROP PROCEDURE IF EXISTS decanet.BASKET_STUDZACH $$
CREATE PROCEDURE decanet.BASKET_STUDZACH(IN SGRP_ID INT, IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE)
COMMENT 'DZ'
BEGIN
  DECLARE DIV_ID INT;

  SELECT R.DIVISION_ID
    INTO DIV_ID
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGRP_ID;


  IF DOC_ID IS NOT NULL AND
     STAT_ID IS NOT NULL AND
     CONT_DT IS NOT NULL THEN

/*
    -- только для пассивных студентов
    DELETE FROM decanet.sysbasket
      WHERE FSTUDENT_ACTIVE(STUDSGRP_ID);
*/

    -- новую группу в актив
    REPLACE INTO decanet.studsgrp(DIVISION_ID, SGROUP_ID, STUDENT_ID, EDUFORM_ID)
      SELECT DIV_ID, SGRP_ID, SG.STUDENT_ID, SG.EDUFORM_ID
        FROM decanet.sysbasket B LEFT JOIN
             decanet.studsgrp SG USING (STUDSGRP_ID);


    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      SELECT NULL, MAX(SG1.STUDSGRP_ID), DOC_ID
        FROM decanet.sysbasket B LEFT JOIN
             decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
             decanet.studsgrp SG1 USING (STUDENT_ID)
        GROUP BY SG1.STUDENT_ID;

    REPLACE INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      SELECT NULL, MAX(SG1.STUDSGRP_ID), STAT_ID, CONT_DT, DOC_ID
        FROM decanet.sysbasket B LEFT JOIN
             decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
             decanet.studsgrp SG1 USING (STUDENT_ID)
        GROUP BY SG1.STUDENT_ID;

    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.BASKET_STUDZACH TO D,Z $$


-- восстанавливаем (в интерфейсе применять только для пассивных студентов)
-- ##SSG
-- !! параметр SSG_ID - текущее состояние студента
-- !!          SGR_ID - группа - куда восстанавливается студент
-- !!
DROP PROCEDURE IF EXISTS decanet.STUDZACH $$
-- ##SSG !! STUDZACH ПЕРЕИМЕНОВАНА В STUDVOSST
DROP PROCEDURE IF EXISTS decanet.STUDVOSST $$
CREATE PROCEDURE decanet.STUDVOSST(IN SSG_ID INT, IN SGR_ID INT, IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE)
COMMENT 'DZ'
BEGIN
  DECLARE STUD_ID, NEWDIV_ID INT;
  SELECT STUDENT_ID
    INTO STUD_ID
    FROM decanet.studsgrp
    WHERE STUDSGRP_ID = SSG_ID;

  SELECT DIVISION_ID
    INTO NEWDIV_ID
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGR_ID;

-- открываем воозможность переводить и активных студентов
--  IF NOT FSTUDENT_ACTIVE(SSG_ID) THEN

    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, DOC_ID);

    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, STAT_ID, CONT_DT, DOC_ID);

    -- а активация статуса при закрытии документа
    UPDATE decanet.studsgrp
      SET SGROUP_ID = SGR_ID
      WHERE STUDSGRP_ID = SSG_ID;
    -- перезачет
    CALL decanet.NEWMAINPROGSYNC(SSG_ID);

    SELECT 1 AS RES;
--  ELSE
--    SELECT 0 AS RES;
--  END IF;
 END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDVOSST TO D,Z $$

-- создание новой учебной группы
DROP PROCEDURE IF EXISTS decanet.SGROUP_ADD $$
CREATE PROCEDURE decanet.SGROUP_ADD(IN DIV_ID INT, IN IDX VARCHAR(10), IN FY YEAR, IN GDESC TINYTEXT)
COMMENT 'DZ'
BEGIN
  SET IDX = TRIM(IDX);

  -- создание потока по необходимости
  IF NOT EXISTS (SELECT STREAM_ID FROM decanet.stream WHERE DIVISION_ID = DIV_ID AND STREAM_FROMYEAR = FY) THEN
    INSERT INTO decanet.stream (STREAM_ID, DIVISION_ID, STREAM_FROMYEAR, STREAM_SEMCOUNT)
      SELECT NULL, DIV_ID, FY, IFNULL(MAX(STREAM_SEMCOUNT), 10)
        FROM decanet.stream
        WHERE DIVISION_ID = DIV_ID;
  END IF;

  IF NOT EXISTS (SELECT SGROUP_ID
                   FROM decanet.sgroup G LEFT JOIN
                        decanet.stream R USING (STREAM_ID)
                   WHERE R.DIVISION_ID = DIV_ID AND
                         G.SGROUP_NAMEINDEX = IDX AND
                         R.STREAM_FROMYEAR = FY) THEN
    INSERT INTO decanet.sgroup(SGROUP_ID, STREAM_ID, SGROUP_NAMEINDEX, SGROUP_DESC)
      SELECT NULL, R.STREAM_ID, IDX, GDESC
        FROM decanet.stream R
        WHERE R.DIVISION_ID = DIV_ID AND
              R.STREAM_FROMYEAR = FY;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUP_ADD TO D,Z $$

-- удаление пустой-новой учебной группы
DROP PROCEDURE IF EXISTS decanet.SGROUP_DEL $$
CREATE PROCEDURE decanet.SGROUP_DEL(IN SGR_ID INT)
COMMENT 'DZ'
BEGIN
  IF (SELECT COUNT(STUDENT_ID)
        FROM decanet.studsgrp
        WHERE SGROUP_ID = SGR_ID) = 0 THEN
    SET FOREIGN_KEY_CHECKS = 0;
    DELETE decanet.studsgrp, decanet.sgroup
      FROM decanet.sgroup LEFT JOIN
           decanet.studsgrp USING (SGROUP_ID)
      WHERE SGROUP_ID = SGR_ID;
    SET FOREIGN_KEY_CHECKS = 1;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SGROUP_DEL TO D,Z $$

-- СОЗДАЕМ и зачисляем нового студента
DROP PROCEDURE IF EXISTS decanet.STUDENT_ADD $$
CREATE PROCEDURE decanet.STUDENT_ADD(IN SGR_ID INT, IN EDUF_ID INT, IN DOC_ID INT, IN STAT_ID INT, CONT_DT DATE,
                                     IN PNO VARCHAR(25), IN FN VARCHAR(50), IN MN VARCHAR(50), IN LN VARCHAR(50))
COMMENT 'DZ'
BEGIN
  DECLARE DIV_ID, STID, SSG_ID INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES; -- SQL - ошибка

  SELECT DIVISION_ID
    INTO DIV_ID
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    WHERE G.SGROUP_ID = SGR_ID;

  IF PNO IS NULL THEN
    SET PNO = IFNULL((SELECT MAX(STUDENT_ID) FROM decanet.student), 0) + 1;
  END IF;

  IF SGR_ID IS NOT NULL AND
     EDUF_ID IS NOT NULL AND
     DOC_ID IS NOT NULL AND
     STAT_ID IS NOT NULL AND
     CONT_DT IS NOT NULL AND
     PNO IS NOT NULL AND
     LN IS NOT NULL AND
     FN IS NOT NULL AND
     MN IS NOT NULL THEN

    -- а активация статуса при закрытии документа
    INSERT INTO decanet.student (STUDENT_ID, STUDENT_PERSNO, STUDENT_FNAME, STUDENT_MNAME, STUDENT_LNAME)
      VALUES (NULL, PNO, FN, MN, LN);

    SET STID = LAST_INSERT_ID();

    INSERT INTO decanet.studadd (STUDENT_ID)
      VALUES (STID);

    INSERT INTO decanet.studsgrp (STUDSGRP_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID, EDUFORM_ID)
      VALUES (NULL, DIV_ID, SGR_ID, STID, EDUF_ID);

    SET SSG_ID = LAST_INSERT_ID();

    REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, DOC_ID);

    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, STAT_ID, CONT_DT, DOC_ID);

    -- синхронизация программы
    INSERT INTO decanet.persprog (PERSPROG_ID, STUDSGRP_ID, MAINPROG_ID, MPROGSUBJ_ID, VOLUME)
      SELECT NULL, SG.STUDSGRP_ID, M.MAINPROG_ID, MIN(U.MPROGSUBJ_ID), M.VOLUME
        FROM decanet.studsgrp SG LEFT JOIN
             decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
             decanet.stream R USING (STREAM_ID) LEFT JOIN
             decanet.dsession E USING (STREAM_ID) LEFT JOIN
             decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
             decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
             decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID)
        WHERE SG.STUDSGRP_ID = SSG_ID AND
              M.MAINPROG_ID IS NOT NULL AND
              P.PERSPROG_ID IS NULL
        GROUP BY M.MAINPROG_ID, SG.STUDSGRP_ID, E.SEMESTR;

    SELECT SSG_ID AS RES;

  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDENT_ADD TO D,Z $$

-- безвозвратно удаляем студента
-- только администратор
-- только с перезапросом
DROP PROCEDURE IF EXISTS decanet.STUDENT_DEL $$
CREATE PROCEDURE decanet.STUDENT_DEL(IN SSG_ID INT)
COMMENT 'D'
BEGIN

  SET FOREIGN_KEY_CHECKS = 0;

  DELETE decanet.studsgrp, decanet.student, decanet.studadd, decanet.duser,
         decanet.persprog, decanet.prolong, decanet.contingent, decanet.studdoc,
         decanet.progdoc, decanet.persname, decanet.acad
    FROM decanet.studsgrp LEFT JOIN
         decanet.student USING (STUDENT_ID) LEFT JOIN
         decanet.studadd USING (STUDENT_ID) LEFT JOIN
         decanet.duser USING (STUDENT_ID) LEFT JOIN
         decanet.persprog USING (STUDSGRP_ID) LEFT JOIN
         decanet.prolong USING (STUDSGRP_ID) LEFT JOIN
         decanet.contingent USING (STUDSGRP_ID) LEFT JOIN
         decanet.studdoc USING (STUDSGRP_ID) LEFT JOIN
         decanet.progdoc USING (PERSPROG_ID) LEFT JOIN
         decanet.persname USING (PERSPROG_ID) LEFT JOIN
         decanet.acad USING (PERSPROG_ID)
    WHERE STUDSGRP_ID = SSG_ID;

  UPDATE decanet.studsgrp S LEFT JOIN
         decanet.sgroup G ON G.SBOSS_ID = S.STUDENT_ID
    SET G.SBOSS_ID = NULL
    WHERE S.STUDSGRP_ID = SSG_ID;

  SET FOREIGN_KEY_CHECKS = 1;

END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDENT_DEL TO D $$


-- завершение обучения по отделению
DROP PROCEDURE IF EXISTS decanet.VIPUSK $$
CREATE PROCEDURE decanet.VIPUSK(IN DIV_ID INT, IN DOC_ID INT, IN CONT_DT DATE)
COMMENT 'DZ'
BEGIN

  -- вяжем приказ со студентами
  REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
    SELECT NULL, SG.STUDSGRP_ID, DOC_ID
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D USING (DIVISION_ID)
      WHERE D.DIVISION_ID = DIV_ID AND
            FGETCURSEM(G.SGROUP_ID) = R.STREAM_SEMCOUNT AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            FSGROUP_ACTIVE(G.SGROUP_ID);

  -- регистрируем статус выпускника
  INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, CONTINGENT_DATE, DOCUMENT_ID)
    SELECT NULL, SG.STUDSGRP_ID, 27, CONT_DT, DOC_ID
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D USING (DIVISION_ID)
      WHERE D.DIVISION_ID = DIV_ID AND
            FGETCURSEM(G.SGROUP_ID) = R.STREAM_SEMCOUNT AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            FSGROUP_ACTIVE(G.SGROUP_ID);

  SELECT 1 AS RES;

END $$
GRANT EXECUTE ON PROCEDURE decanet.VIPUSK TO D,Z $$


-- перевод на следующий курс по отделению
DROP PROCEDURE IF EXISTS decanet.NEXTKURS $$
CREATE PROCEDURE decanet.NEXTKURS(IN DIV_ID INT, IN DOC_ID INT, IN CONT_DT DATE)
COMMENT 'DZ'
BEGIN

  -- вяжем приказ со студентами
  REPLACE INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
    SELECT NULL, SG.STUDSGRP_ID, DOC_ID
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.contingent C ON C.STUSGRP_ID = SG.STUDSGRP_ID AND
                                   C.STUDSTATUS_ID = 5 LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE D.DIVISION_ID = DIV_ID AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            FSGROUP_ACTIVE(G.SGROUP_ID) AND
            SGROUPKURS(G.SGROUP_ID, CONT_DT) > 0 AND
            SGROUPKURS(G.SGROUP_ID, CONT_DT) < R.STREAM_SEMCOUNT / 2
      GROUP BY G.SGROUP_ID, SG.STUDSGRP_ID HAVING MAX(STUDSTATUS_VALUE) IS NULL OR
                                                    MAX(STUDSTATUS_VALUE) < SGROUPKURS(G.SGROUP_ID, CONT_DT) + 1;

  -- регистрируем статус перевода
  INSERT INTO decanet.contingent(CONTINGENT_ID, STUDSGRP_ID, STUDSTATUS_ID, STUDSTATUS_VALUE, CONTINGENT_DATE, DOCUMENT_ID)
    SELECT NULL, SG.STUDSGRP_ID, 5, SGROUPKURS(G.SGROUP_ID, CONT_DT) + 1, CONT_DT, DOC_ID
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                   C.STUDSTATUS_ID = 5 LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE D.DIVISION_ID = DIV_ID AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            FSGROUP_ACTIVE(G.SGROUP_ID) AND
            SGROUPKURS(G.SGROUP_ID, CONT_DT) > 0 AND
            SGROUPKURS(G.SGROUP_ID, CONT_DT) < R.STREAM_SEMCOUNT / 2
      GROUP BY G.SGROUP_ID, SG.STUDSGRP_ID HAVING MAX(STUDSTATUS_VALUE) IS NULL OR
                                                    MAX(STUDSTATUS_VALUE) < SGROUPKURS(G.SGROUP_ID, CONT_DT) + 1;

  SELECT 1 AS RES;

END $$
GRANT EXECUTE ON PROCEDURE decanet.NEXTKURS TO D,Z $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ XI. ЗАЧИСЛЕНИЕ АБИТУРИЕНТОВ
-- ---------------------------------------------------------------------------------------------------

/*
-- зачисление абитуриентов на первый курс отделения
-- сначала создаем временную таблицу
DROP PROCEDURE IF EXISTS decanet.PREPAREZACHABIT $$
CREATE PROCEDURE decanet.PREPAREZACHABIT()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS DECANAT.ttZACHABIT;
  CREATE TEMPORARY TABLE DECANAT.ttZACHABIT(SGRP_NIDX INT NOT NULL,
                                            EFORM INT,
                                            LNAME VARCHAR(25) NOT NULL,
                                            FNAME VARCHAR(25) NOT NULL,
                                            MNAME VARCHAR(25) NOT NULL,
                                            PERS_NO VARCHAR(25) NOT NULL,
                                            BUCH_NO VARCHAR(25),
                                            ZACH_NO VARCHAR(25),
                                            STRAH_NO VARCHAR(25));
END$$
*/

-- потом из основного интерфейса вызываем LOAD DATA
-- или заполняем вр. таблицу из формы
/*
  IF LocalLoad THEN
    LOAD DATA LOCAL INFILE FILENAME INTO TABLE DECANAT.ttZACHABIT
       FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
       LINES TERMINATED BY '\r\n';
  ELSE
    LOAD DATA INFILE FILENAME INTO TABLE DECANAT.ttZACHABIT
       FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
       LINES TERMINATED BY '\r\n';
  END IF;
*/

/*
-- и в том же коннекте, что и PREPAREZACHABIT выполняем зачисление
DROP PROCEDURE IF EXISTS decanet.ZACHABIT $$
CREATE PROCEDURE decanet.ZACHABIT(IN DIV_ID INT,
                                  IN P_NO VARCHAR(25),
                                  IN P_DT DATE,
                                  IN DTEMP BOOL,
                                  IN SGRP_FY YEAR)
BEGIN
  DECLARE DDESC VARCHAR(255);
  DECLARE SA, FA, DA VARCHAR(25);
  DECLARE DT_ID, DOC_ID, SS_ID INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0; -- SQL - ошибка

  -- проверка на существование групп
  IF EXISTS(SELECT SGROUP_ID FROM decanet.sgroup G JOIN
                                  decanet.ttZACHABIT ON G.DIVISION_ID = DIV_ID AND
                                                        G.SGROUP_NAMEINDEX = T.SGRP_NIDX AND
                                                        G.FROMYEAR = SGRP_FY AND
                                                        FSGROUP_ACTIVE(G.SGROUP_ID)) THEN
    SELECT 2; -- такие группы уже созданы
  ELSE
    -- регистрируем группы
    INSERT INTO decanet.sgroup(SGROUP_ID, DIVISION_ID, SGROUP_NAMEINDEX, SGROUP_FROMYEAR)
      SELECT DISTINCT NULL, DIV_ID, T.SGRP_NIDX, SGRP_FY, TRUE FROM decanet.ttZACHABIT T;

    ALTER TABLE decanet.ttZACHABIT ADD COLUMN SGROUP_ID INT,
                                   ADD COLUMN STUDENT_ID INT;
    -- проставляем SGROUP_ID
    UPDATE decanet.ttZACHABIT T JOIN decanet.sgroup G ON G.DIVISION_ID = DIV_ID AND
                                                         G.SGROUP_NAMEINDEX = T.SGRP_NIDX AND
                                                         G.FROMYEAR = SGRP_FY AND
                                                         FSGROUP_ACTIVE(G.SGROUP_ID)
      SET T.SGROUP_ID = G.SGROUP_ID;

    -- регистрируем студентов
    INSERT INTO decanet.student(STUDENT_ID, SGROUP_ID, EDUFORM_ID, STUDENT_PERSNO, STUDENT_BUCHNO,
                                STUDENT_ZACHNO, STUDENT_STRAHNO, STUDENT_FNAME, STUDENT_MNAME,
                                STUDENT_LNAME)
      SELECT NULL, T.SGROUP_ID, T.EFORM, T.PERS_NO, T.BUCH_NO, T.ZACH_NO, T.STRAH_NO,
                   T.FNAME, T.MNAME, T.LNAME,
        FROM decanet.ttZACHABIT T;

    -- проставляем STUDENT_ID
    UPDATE decanet.ttZACHABIT T JOIN decanet.student S ON T.SGROUP_ID = S.SGROUP_ID AND
                                                          T.PERSNO = S.STUDENT_PERSNO
      SET T.STUDENT_ID = S.STUDENT_ID;

    -- определем параметры приказа о зачислении
    SET DT_ID = (SELECT DOCTYPE_ID FROM decanet.doctype WHERE DOCTYPE_ABBR = 'ЗАЧИСЛ');

    SELECT S.SCHOOL_ABBR, F.FACULTET_ABBR, D.DIVISION_ABBR INTO SA, FA, DA
      FROM decanet.division D JOIN decanet.facultet F USING (FACULTET_ID) JOIN
           decanet.school S USING (SCHOOL_ID)
      WHERE D.DIVISION_ID = DIV_ID;

    SET DDESC = CONCAT(SA, ' Факультет:', FA, ' Отделение:', DA, ' Год:', CAST(SGRP_FY AS CHAR));
    -- регистрируем приказ о зачислении
    INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, DOCUMENT_TEMPFLAG, DOCUMENT_NO,
                                 DOCUMENT_OUTDATE, DOCUMENT_INDATE, DOCUMENT_NAME, DOCUMENT_DESC)
      SELECT NULL, DT_ID, DTEMP, P_NO, P_DT, IF(DTEMP, NULL, P_DT), 'Зачисление на первый курс', DDESC;

    SET DOC_ID = LAST_INSERT_ID();
    -- связываем приказ со студентами
    INSERT INTO decanet.studdoc(STUDDOC_ID, STUDENT_ID, DOCUMENT_ID)
      SELECT T.STUDENT_ID, DOC_ID FROM decanet.ttZACHABIT T;

    SET SS_ID = (SELECT STUDSTATUS_ID FROM decanet.studstatus WHERE STUDSTATUS_NAME = 'Зачисление на первый курс');

    -- регистрируем контингентный статус
    INSERT INTO decanet.contingent(CONTINGENT_ID, STUDENT_ID, STUDSTATUS_ID,
                                   STUDSTATUS_VALUE, DOCUMENT_ID)
      SELECT NULL, T.STUDENT_ID, SS_ID, 1, DOC_ID FROM decanet.ttZACHABIT T;

    SELECT 1; -- нормальное завершение

  END IF;
END$$
*/

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ XII. СВОДКА ПО СЕССИИ
-- ---------------------------------------------------------------------------------------------------

-- decanet.result.RESULT_ABBR сделать CHAR(1) !!!

/*
  Использование:
    1. decanet.SAI_MP_LST - получаем пункты основной программы
       для колонок сводки
    2. decanet.SAI_STUD_LST - студенты для строк сводки
    3. ПО КАЖДОМУ STUDENT_ID вызываем decanet.SAI_RES_LST.
*/


-- итоги по группе
-- допускается SFASE = NULL
DROP PROCEDURE IF EXISTS decanet.SAI_SGRP_LST $$
CREATE PROCEDURE decanet.SAI_SGRP_LST(IN SGRP_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT G.SGROUP_ID,
         CAST(AVG(T.RESULT_INT) AS DECIMAL(2,1)) AS AVGBALL,
         COUNT(IF(T.RESULT_PASSFLAG, 1, NULL)) AS COUNTPOS,
         COUNT(IF(NOT T.RESULT_PASSFLAG OR RESULT_ID IS NULL, 1, NULL)) AS COUNTNEG,
         COUNT(IF(T.RESULT_ID IN (1,2), 1, NULL)) AS COUNT45,
         COUNT(IF(T.RESULT_ID = 1, 1, NULL)) AS COUNT5,
         COUNT(IF(T.RESULT_ID = 2, 1, NULL)) AS COUNT4,
         COUNT(IF(T.RESULT_ID = 3, 1, NULL)) AS COUNT3,
         COUNT(IF(T.RESULT_ID = 4, 1, NULL)) AS COUNT2,
         COUNT(IF(T.RESULT_ID = 5, 1, NULL)) AS COUNTZ,
         COUNT(IF(T.RESULT_ID = 6, 1, NULL)) AS COUNTNZ,
         COUNT(IF(T.RESULT_ID IS NULL, 1, NULL)) AS COUNTNULL
    FROM decanet.sgroup G LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl P USING (CONTROL_ID) LEFT JOIN
         decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.result T USING (RESULT_ID)

    WHERE G.SGROUP_ID = SGRP_ID AND
          E.SEMESTR = SEM AND
          IF(SPHASE IS NULL, TRUE, P.SESSPHASE_ID = SPHASE) AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                  FROM decanet.progdoc P1 LEFT JOIN
                                       decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                       decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                  WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                        A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
           T.RESULT_ID IS NULL)
    GROUP BY G.SGROUP_ID;
    -- ORDER BY M.CONTROL_ID DESC, U.MPROGSUBJ_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SAI_SGRP_LST TO A,D,Z,S,V $$



-- полный список подпунктов по осн. программе CNT
-- допускается SFASE = NULL
DROP PROCEDURE IF EXISTS decanet.SAI_MP_CNT $$
CREATE PROCEDURE decanet.SAI_MP_CNT(IN SGRP_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(U.MPROGSUBJ_ID) AS CNT
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl P USING (CONTROL_ID)
    WHERE G.SGROUP_ID = SGRP_ID AND
          E.SEMESTR = SEM AND
          IF(SPHASE IS NULL, TRUE, P.SESSPHASE_ID = SPHASE);
END$$
GRANT EXECUTE ON PROCEDURE decanet.SAI_MP_CNT TO A,D,Z,S,V $$

-- полный список подпунктов по осн. программе  LST
-- допускается SFASE = NULL
DROP PROCEDURE IF EXISTS decanet.SAI_MP_LST $$
CREATE PROCEDURE decanet.SAI_MP_LST(IN SGRP_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT U.MPROGSUBJ_ID, J.SUBJ_ABBR, C.CONTROL_ABBR,
         CAST(AVG(T.RESULT_INT) AS DECIMAL(2,1)) AS AVGBALL,
         COUNT(IF(T.RESULT_PASSFLAG, 1, NULL)) AS COUNTPOS,
         COUNT(IF(NOT T.RESULT_PASSFLAG OR RESULT_ID IS NULL, 1, NULL)) AS COUNTNEG,
         COUNT(IF(T.RESULT_ID IN (1,2), 1, NULL)) AS COUNT45,
         COUNT(IF(T.RESULT_ID = 1, 1, NULL)) AS COUNT5,
         COUNT(IF(T.RESULT_ID = 2, 1, NULL)) AS COUNT4,
         COUNT(IF(T.RESULT_ID = 3, 1, NULL)) AS COUNT3,
         COUNT(IF(T.RESULT_ID = 4, 1, NULL)) AS COUNT2,
         COUNT(IF(T.RESULT_ID = 5, 1, NULL)) AS COUNTZ,
         COUNT(IF(T.RESULT_ID = 6, 1, NULL)) AS COUNTNZ,
         COUNT(IF(T.RESULT_ID IS NULL, 1, NULL)) AS COUNTNULL
    FROM decanet.sgroup G LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl P USING (CONTROL_ID) LEFT JOIN
         decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.result T USING (RESULT_ID)

    WHERE G.SGROUP_ID = SGRP_ID AND
          E.SEMESTR = SEM AND
          IF(SPHASE IS NULL, TRUE, P.SESSPHASE_ID = SPHASE) AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                  FROM decanet.progdoc P1 LEFT JOIN
                                       decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                       decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                  WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                        A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
           T.RESULT_ID IS NULL)
    GROUP BY U.MPROGSUBJ_ID
    ORDER BY M.CONTROL_ID, U.MPROGSUBJ_ID;
    -- ORDER BY M.CONTROL_ID DESC, U.MPROGSUBJ_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SAI_MP_LST TO A,D,Z,S,V $$

-- список активных студентов группы для сводки по сессии CNT
DROP PROCEDURE IF EXISTS decanet.SAI_STUD_CNT $$
CREATE PROCEDURE decanet.SAI_STUD_CNT(IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(SG.STUDENT_ID) AS CNT
    FROM decanet.studsgrp SG
    WHERE SG.SGROUP_ID = SGRP_ID AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID);
END $$
GRANT EXECUTE ON PROCEDURE decanet.SAI_STUD_CNT TO A,D,Z,S,V $$

/*
-- список активных студентов группы для сводки по сессии LST
DROP PROCEDURE IF EXISTS decanet.SAI_STUD_LST $$
CREATE PROCEDURE decanet.SAI_STUD_LST(IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SG.STUDSGRP_ID, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME, S.STUDENT_ZACHNO,
         SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUP_AUTONAME
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.student S USING (STUDENT_ID)
    WHERE SG.SGROUP_ID = SGRP_ID AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID)
  ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
*/

-- список активных студентов группы для сводки по сессии LST
-- со средним баллом и фэйл-флагом
DROP PROCEDURE IF EXISTS decanet.SAI_STUD_LST $$
CREATE PROCEDURE decanet.SAI_STUD_LST(IN SGRP_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT SG.STUDSGRP_ID, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME, S.STUDENT_ZACHNO,
         SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUP_AUTONAME,
         COUNT(IF((T.RESULT_ID IS NULL AND PP.PERSPROG_ID IS NOT NULL) OR NOT T.RESULT_PASSFLAG, 1, NULL)) AS FAILFLAG,
         CAST(AVG(T.RESULT_INT) AS DECIMAL(2,1)) AS AVGBALL
    FROM decanet.sgroup G LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl P USING (CONTROL_ID) LEFT JOIN
         decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.result T USING (RESULT_ID)
    WHERE G.SGROUP_ID = SGRP_ID AND
          E.SEMESTR = SEM AND
          IF(SPHASE IS NULL, TRUE, P.SESSPHASE_ID = SPHASE) AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                  FROM decanet.progdoc P1 LEFT JOIN
                                       decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                       decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                  WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                        A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
           T.RESULT_ID IS NULL)
    GROUP BY SG.STUDSGRP_ID
    ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SAI_STUD_LST TO A,D,Z,S,V $$

-- список оценок студента по предварительно полученному перечню пунктов осн. программы
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.SAI_RES_LST $$
CREATE PROCEDURE decanet.SAI_RES_LST(IN SSG_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  SELECT U.MPROGSUBJ_ID, IF(P.PERSPROG_ID IS NULL, 'X', IFNULL(T.RESULT_ABBR, '.')) AS RESULT_ABBR
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING(SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.phasectrl F USING (CONTROL_ID) LEFT JOIN
         decanet.persprog P ON P.STUDSGRP_ID = SG.STUDSGRP_ID AND
                               P.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.result T USING (RESULT_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          E.SEMESTR = SEM AND
          IF(SPHASE IS NULL, TRUE, F.SESSPHASE_ID = SPHASE) AND
         (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                 FROM decanet.progdoc P1 LEFT JOIN
                                      decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                      decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                 WHERE P1.PERSPROG_ID = P.PERSPROG_ID AND
                                       A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
          T.RESULT_ID IS NULL)
    ORDER BY M.CONTROL_ID, U.MPROGSUBJ_ID;
    -- ORDER BY M.CONTROL_ID DESC, U.MPROGSUBJ_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SAI_RES_LST TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ВЫБОРОЧНАЯ СВОДКА ПО СЕССИИ
-- ---------------------------------------------------------------------------------------------------

/*
  Использование:
    1. VSAI_ALLMP_LST - список пунктов программы потока для выбора (MAINPROG_ID)
    2. Отмечаем их чекбоксами и пишем в массив в сессию
    ДАЛЬШЕ В ОДНОМ КОННЕКТЕ:
    3. VSAI_INIT - создать временную таблицу
    4. VSAI_ADD - добавить из массива
    5. VSAI_PHASEADD - добавить фазу при выборе ссылки фазы
    6. VSAI_MP_CNT - кол-во столбцов дисциплин
    7. VSAI_MP_LST - список столбцов дисциплин
    8. VSAI_STUD_LST - студенты для строк сводки - со средними баллами AVGBALL
    9. ПО КАЖДОМУ STUDENT_ID вызываем decanet.VSAI_RES_LST.
    10. VSAI_MPITOG_LST - список ИТОГОВ по столбцам дисциплин
           AVGBALL - Средий балл
           KUSP - Повышенных оценок, %
           CNTNEG - Неаттестованных, чел
           CNT5 - Сдавших на "5", чел
           CNT4 - Сдавших на "4", чел
           CNT3 - Сдавших на "3", чел
           CNT2 - Не сдавших ("2", "-"), чел
    11. VSAI_SGRP_LST - итоги по группе
           AVGBALL - Средий балл
           KUSP - Повышенных оценок, %
           CNT45 -  Сдавших на 4 и 5, чел
           CNTNNEG - Неатестованных, чел
           GUSP - Успеваемость, %
    12. VSAI_DONE - удалить вр. таблицу (И СБРОСИТЬ МАССИВ в PHP)
*/

-- полный список пунктов осн. программы LST
-- если SUBJSEL > 1 то к SUBJ_ABBR добавить многоточие (или пиктограмму ВЫБОР)
DROP PROCEDURE IF EXISTS decanet.VSAI_ALLMP_LST $$
CREATE PROCEDURE decanet.VSAI_ALLMP_LST(IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT M.MAINPROG_ID, J.SUBJ_ABBR, M.CONTROL_ID, C.CONTROL_ABBR, E.SEMESTR,
        (SELECT COUNT(SUBJ_ID) FROM decanet.mprogsubj S WHERE S.MAINPROG_ID = M.MAINPROG_ID) AS SUBJSEL
    FROM decanet.sgroup G LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID)
    WHERE G.SGROUP_ID = SGRP_ID AND
          M.MAINPROG_ID IS NOT NULL
    GROUP BY M.MAINPROG_ID
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR;
END$$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_ALLMP_LST TO A,D,Z,S,V $$


DROP PROCEDURE IF EXISTS decanet.VSAI_INIT $$
CREATE PROCEDURE decanet.VSAI_INIT()
COMMENT 'ADZSV'
BEGIN
  DROP TEMPORARY TABLE IF EXISTS decanet.sysVSAI;
  CREATE TEMPORARY TABLE decanet.sysVSAI
    (MAINPROG_ID INT NOT NULL,
     PRIMARY KEY (MAINPROG_ID));
  SELECT CONNECTION_ID() AS CONN_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_INIT TO A,D,Z,S,V $$

DROP PROCEDURE IF EXISTS decanet.VSAI_DONE $$
CREATE PROCEDURE decanet.VSAI_DONE()
COMMENT 'ADZSV'
BEGIN
  DROP TEMPORARY TABLE IF EXISTS decanet.sysVSAI;
  SELECT 1 AS RES;
END $$


DROP PROCEDURE IF EXISTS decanet.VSAI_ADD $$
CREATE PROCEDURE decanet.VSAI_ADD(IN CONN_ID INT, IN MP_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    REPLACE INTO decanet.sysVSAI(MAINPROG_ID)
      VALUES (MP_ID);
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_ADD TO A,D,Z,S,V $$

-- добавить фазу по семестру (SPHASE может быть NULL)
DROP PROCEDURE IF EXISTS decanet.VSAI_PHASEADD $$
CREATE PROCEDURE decanet.VSAI_PHASEADD(IN CONN_ID INT, IN SGRP_ID INT, IN SEM INT, IN SPHASE INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    REPLACE INTO decanet.sysVSAI(MAINPROG_ID)
      SELECT M.MAINPROG_ID
        FROM decanet.sgroup G LEFT JOIN
             decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
             decanet.stream R USING (STREAM_ID) LEFT JOIN
             decanet.dsession E USING (STREAM_ID) LEFT JOIN
             decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
             decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
             decanet.subj J USING (SUBJ_ID) LEFT JOIN
             decanet.control C USING (CONTROL_ID) LEFT JOIN
             decanet.phasectrl P USING (CONTROL_ID)
        WHERE G.SGROUP_ID = SGRP_ID AND
              E.SEMESTR = SEM AND
              IF(SPHASE IS NULL, TRUE, P.SESSPHASE_ID = SPHASE);
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_PHASEADD TO A,D,Z,S,V $$


-- итоги по группе
--           AVGBALL - Средий балл
--           KUSP - Кач. успеваемость, %
--           CNT45 -  Сдавших на 4 и 5, чел
--           CNTNNEG - Неатестованных, чел
--           GUSP - Общ. успеваемость, %

DROP PROCEDURE IF EXISTS decanet.VSAI_SGRP_LST $$
CREATE PROCEDURE decanet.VSAI_SGRP_LST(IN CONN_ID INT, IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN

  DECLARE AVGBALL, KUSP DECIMAL(4,1);
  DECLARE SG_ID, CNTPOS, SUM45, SUMNEG, CNTALL INT;

  IF CONN_ID = CONNECTION_ID() THEN

    SELECT X.SGROUP_ID,
           AVG(X.AVGBALL),
           SUM(X.FLAG45),
           SUM(X.FLAG45) / COUNT(X.STUDSGRP_ID) * 100,
           COUNT(X.STUDSGRP_ID)
      INTO SG_ID, AVGBALL, SUM45, KUSP, CNTPOS
      FROM (SELECT SG.SGROUP_ID, SG.STUDSGRP_ID,
                   CAST(AVG(T.RESULT_INT) AS DECIMAL(4,1)) AS AVGBALL,
                   COUNT(IF(T.RESULT_ID = 3, 1, NULL)) = 0 AS FLAG45
              FROM decanet.studsgrp SG LEFT JOIN
                   decanet.student S USING (STUDENT_ID) LEFT JOIN
                   decanet.sysVSAI V ON TRUE LEFT JOIN
                   decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
                   decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                          PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
                   decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                   decanet.document D USING (DOCUMENT_ID) LEFT JOIN
                   decanet.result T USING (RESULT_ID)
              WHERE SG.SGROUP_ID = SGRP_ID AND
                    FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
                    (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                            FROM decanet.progdoc P1 LEFT JOIN
                                                 decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                                 decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                            WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                                  A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
                     T.RESULT_ID IS NULL)
            GROUP BY SG.STUDSGRP_ID HAVING COUNT(IF((T.RESULT_ID IS NULL AND PP.PERSPROG_ID IS NOT NULL) OR NOT T.RESULT_PASSFLAG, 1, NULL)) = 0) X
      GROUP BY X.SGROUP_ID;


    SELECT X.SGROUP_ID,
           SUM(X.FLAGNEG),
           COUNT(X.STUDSGRP_ID)
      INTO SG_ID, SUMNEG, CNTALL
      FROM (SELECT SG.SGROUP_ID, SG.STUDSGRP_ID,
                   COUNT(IF((T.RESULT_ID IS NULL AND PP.PERSPROG_ID IS NOT NULL) OR NOT T.RESULT_PASSFLAG, 1, NULL)) > 0  AS FLAGNEG
              FROM decanet.studsgrp SG LEFT JOIN
                   decanet.student S USING (STUDENT_ID) LEFT JOIN
                   decanet.sysVSAI V ON TRUE LEFT JOIN
                   decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
                   decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                          PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
                   decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                   decanet.document D USING (DOCUMENT_ID) LEFT JOIN
                   decanet.result T USING (RESULT_ID)
              WHERE SG.SGROUP_ID = SGRP_ID AND
                    FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
                    (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                            FROM decanet.progdoc P1 LEFT JOIN
                                                 decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                                 decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                            WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                                  A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
                     T.RESULT_ID IS NULL)
            GROUP BY SG.STUDSGRP_ID) X
      GROUP BY X.SGROUP_ID;

    SELECT SGRP_ID, AVGBALL, KUSP, SUM45, SUMNEG, CAST(CNTPOS / CNTALL * 100 AS DECIMAL(4,1)) AS GUSP;

  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_SGRP_LST TO A,D,Z,S,V $$


-- список активных студентов группы для сводки по сессии LST
-- со средним баллом и фэйл-флагом
DROP PROCEDURE IF EXISTS decanet.VSAI_STUD_LST $$
CREATE PROCEDURE decanet.VSAI_STUD_LST(IN CONN_ID INT, IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    SELECT SG.STUDSGRP_ID, S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME, S.STUDENT_ZACHNO,
           SGROUPAUTONAME(SG.SGROUP_ID) AS SGROUP_AUTONAME,
           COUNT(IF((T.RESULT_ID IS NULL AND PP.PERSPROG_ID IS NOT NULL) OR NOT T.RESULT_PASSFLAG, 1, NULL)) AS FAILFLAG,
           CAST(AVG(T.RESULT_INT) AS DECIMAL(4,1)) AS AVGBALL
      FROM decanet.studsgrp SG LEFT JOIN
           decanet.student S USING (STUDENT_ID) LEFT JOIN
           decanet.sysVSAI V ON TRUE LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                  PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
           decanet.acad A USING (PERSPROG_ID) LEFT JOIN
           decanet.document D USING (DOCUMENT_ID) LEFT JOIN
           decanet.result T USING (RESULT_ID)
      WHERE SG.SGROUP_ID = SGRP_ID AND
            FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
            (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                    FROM decanet.progdoc P1 LEFT JOIN
                                         decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                         decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                    WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                          A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
             T.RESULT_ID IS NULL)
      GROUP BY SG.STUDSGRP_ID
      ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_STUD_LST TO A,D,Z,S,V $$


-- список оценок студента по предварительно полученному перечню пунктов осн. программы
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.VSAI_RES_LST $$
CREATE PROCEDURE decanet.VSAI_RES_LST(IN CONN_ID INT, IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    SELECT U.MPROGSUBJ_ID, IF(P.PERSPROG_ID IS NULL, 'X', IFNULL(T.RESULT_ABBR, '.')) AS RESULT_ABBR
      FROM decanet.sysVSAI V LEFT JOIN
           decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.subj J USING (SUBJ_ID) LEFT JOIN
           decanet.persprog P ON P.STUDSGRP_ID = SSG_ID AND
                                 P.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
           decanet.acad A USING (PERSPROG_ID) LEFT JOIN
           decanet.document D USING (DOCUMENT_ID) LEFT JOIN
           decanet.result T USING (RESULT_ID)
      WHERE (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                    FROM decanet.progdoc P1 LEFT JOIN
                                         decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                         decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                    WHERE P1.PERSPROG_ID = P.PERSPROG_ID AND
                                          A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
             T.RESULT_ID IS NULL)
      ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_RES_LST TO A,D,Z,S,V $$

-- кол-во подпунктов осн. программы для шапки таблицы CNT
DROP PROCEDURE IF EXISTS decanet.VSAI_MP_CNT $$
CREATE PROCEDURE decanet.VSAI_MP_CNT(IN CONN_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    SELECT COUNT(U.MPROGSUBJ_ID) AS CNT
      FROM decanet.sysVSAI V LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID);
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_MP_CNT TO A,D,Z,S,V $$


-- список подпунктов осн. программы для шапки таблицы LST
DROP PROCEDURE IF EXISTS decanet.VSAI_MP_LST $$
CREATE PROCEDURE decanet.VSAI_MP_LST(IN CONN_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN

    SELECT M.MAINPROG_ID, U.MPROGSUBJ_ID, J.SUBJ_ABBR, C.CONTROL_ABBR, E.SEMESTR
      FROM decanet.sysVSAI V LEFT JOIN
           decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
           decanet.dsession E USING (DSESSION_ID) LEFT JOIN
           decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
           decanet.subj J USING (SUBJ_ID) LEFT JOIN
           decanet.control C USING (CONTROL_ID)
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR;

  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_MP_LST TO A,D,Z,S,V $$

-- список ИТОГОВ по ПОДПУНКТАМ осн. программы ИТОГОВ таблицы LST
DROP PROCEDURE IF EXISTS decanet.VSAI_MPITOG_LST $$
CREATE PROCEDURE decanet.VSAI_MPITOG_LST(IN CONN_ID INT, IN SGRP_ID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN

--           AVGBALL - Средий балл
--           KUSP - Повышенных оценок, %
--           CNTNEG - Неаттестованных, чел
--           CNT5 - Сдавших на "5", чел
--           CNT4 - Сдавших на "4", чел
--           CNT3 - Сдавших на "3", чел
--           CNT2 - Не сдавших ("2", "-"), чел

  SELECT U.MPROGSUBJ_ID, -- J.SUBJ_ABBR, C.CONTROL_ABBR, E.SEMESTR,
         CAST(AVG(T.RESULT_INT) AS DECIMAL(4,1)) AS AVGBALL,
         CAST(COUNT(IF(T.RESULT_ID IN (1, 2), 1, NULL)) / COUNT(PP.PERSPROG_ID) * 100 AS DECIMAL(4,1)) AS KUSP,
         COUNT(IF(NOT T.RESULT_PASSFLAG OR RESULT_ID IS NULL, 1, NULL)) AS CNTNEG,
         COUNT(IF(T.RESULT_ID = 1, 1, NULL)) AS CNT5,
         COUNT(IF(T.RESULT_ID = 2, 1, NULL)) AS CNT4,
         COUNT(IF(T.RESULT_ID = 3, 1, NULL)) AS CNT3,
         COUNT(IF(T.RESULT_ID = 4 OR T.RESULT_ID = 6, 1, NULL)) AS CNT2
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sysVSAI V ON TRUE LEFT JOIN
         decanet.mainprog M USING (MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.mprogsubj U USING (MAINPROG_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.persprog PP ON PP.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                PP.MPROGSUBJ_ID = U.MPROGSUBJ_ID LEFT JOIN
         decanet.acad A USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.result T USING (RESULT_ID)
    WHERE SG.SGROUP_ID = SGRP_ID AND
          FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
          (D.DOCUMENT_INDATE = (SELECT MAX(D1.DOCUMENT_INDATE)
                                  FROM decanet.progdoc P1 LEFT JOIN
                                       decanet.document D1 USING (DOCUMENT_ID) LEFT JOIN
                                       decanet.acad A1 USING(PERSPROG_ID, DOCUMENT_ID)
                                  WHERE P1.PERSPROG_ID = PP.PERSPROG_ID AND
                                        A1.RESULT_ID IS NOT NULL) OR -- последняя оценка
           T.RESULT_ID IS NULL)
    GROUP BY U.MPROGSUBJ_ID
    ORDER BY E.SEMESTR, M.CONTROL_ID, J.SUBJ_ABBR;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.VSAI_MPITOG_LST TO A,D,Z,S,V $$


/*
CALL decanet.VSAI_MP_LST(173,84);
CALL decanet.VSAI_STUD_LST(173,84);
CALL decanet.VSAI_RES_LST(173,2171);
CALL decanet.VSAI_RES_LST(173,2172);
CALL decanet.VSAI_RES_LST(173,2174);
CALL decanet.VSAI_RES_LST(173,2175);
CALL decanet.VSAI_RES_LST(173,2177);
CALL decanet.VSAI_RES_LST(173,2303);
CALL decanet.VSAI_RES_LST(173,2178);
CALL decanet.VSAI_RES_LST(173,2179);
CALL decanet.VSAI_RES_LST(173,2180);
CALL decanet.VSAI_RES_LST(173,2181);
CALL decanet.VSAI_RES_LST(173,2182);
CALL decanet.VSAI_RES_LST(173,2183);
CALL decanet.VSAI_RES_LST(173,2184);
CALL decanet.VSAI_RES_LST(173,2205);
CALL decanet.VSAI_RES_LST(173,2187);
CALL decanet.VSAI_RES_LST(173,2188);
CALL decanet.VSAI_RES_LST(173,2189);
CALL decanet.VSAI_RES_LST(173,2190);
CALL decanet.VSAI_RES_LST(173,2191);
CALL decanet.VSAI_RES_LST(173,2192);
CALL decanet.VSAI_RES_LST(173,2296);
CALL decanet.VSAI_RES_LST(173,2193);
CALL decanet.VSAI_RES_LST(173,2215);
CALL decanet.VSAI_RES_LST(173,2194);
CALL decanet.VSAI_RES_LST(173,2195);
CALL decanet.VSAI_RES_LST(173,2196);
*/

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . СТИПЕНДИЯ НА ГРУППУ
-- ---------------------------------------------------------------------------------------------------

-- протокол заседания стипендиальной комиссии

-- таблица списка учитываемых фаз сессии
DROP PROCEDURE IF EXISTS decanet.SFLST_INIT $$
CREATE PROCEDURE decanet.SFLST_INIT()
COMMENT 'ADZSV'
BEGIN
  DROP TEMPORARY TABLE IF EXISTS decanet.tt_SFLST;
  CREATE TEMPORARY TABLE decanet.tt_SFLST
    (SESSPHASE_ID INT NOT NULL,
     PRIMARY KEY (SESSPHASE_ID));

  SELECT CONNECTION_ID() AS CONN_ID;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SFLST_INIT TO A,D,Z,S,V $$

-- заполнение списка учитываемых фаз сессии
DROP PROCEDURE IF EXISTS decanet.SFLST_ADD $$
CREATE PROCEDURE decanet.SFLST_ADD(IN CONN_ID INT, IN SFID INT)
COMMENT 'ADZSV'
BEGIN
  IF CONN_ID = CONNECTION_ID() THEN
    REPLACE INTO decanet.tt_SFLST(SESSPHASE_ID)
      VALUES (SFID);
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END$$
GRANT EXECUTE ON PROCEDURE decanet.SFLST_ADD TO A,D,Z,S,V $$


DROP PROCEDURE IF EXISTS decanet.STIPPROT_LST $$
CREATE PROCEDURE decanet.STIPPROT_LST(IN CONN_ID INT, IN SGRP_ID INT, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE DIV_ID INT;

  IF CONN_ID = CONNECTION_ID() THEN

    SELECT DIVISION_ID
      INTO DIV_ID
      FROM decanet.sgroup G LEFT JOIN
           decanet.stream R USING (STREAM_ID)
      WHERE G.SGROUP_ID = SGRP_ID;

    -- справочник результатов с НЕ СДАНО
    DROP TEMPORARY TABLE IF EXISTS decanet.ttresult;
    CREATE TEMPORARY TABLE decanet.ttresult AS
      SELECT RESULT_ID, RESULT_INT, RESULT_ABBR, RESULT_NAME, RESULT_PASSFLAG
        FROM decanet.result
        WHERE RESULT_ID < 7
      UNION
      SELECT 1000, NULL, 'Не сдано', 'Не сдано', 0;

    -- кол-ва по студентам и имеющимся результатам
    DROP TEMPORARY TABLE IF EXISTS decanet.ttstiprescnt;
    CREATE TEMPORARY TABLE decanet.ttstiprescnt AS
      SELECT SG.STUDSGRP_ID, T.RESULT_ID, T.RESULT_ABBR, COUNT(*) AS RCNT
        FROM decanet.studsgrp SG LEFT JOIN
             decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
             decanet.stream R USING (STREAM_ID) LEFT JOIN
             decanet.dsession E USING (STREAM_ID) LEFT JOIN
             decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
             decanet.control C USING (CONTROL_ID) LEFT JOIN
             decanet.phasectrl PC USING (CONTROL_ID) LEFT JOIN
             decanet.tt_SFLST SF USING (SESSPHASE_ID) LEFT JOIN
             decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID) LEFT JOIN
             decanet.acad A USING (PERSPROG_ID) LEFT JOIN
             decanet.document D USING (DOCUMENT_ID) LEFT JOIN
             decanet.result T USING (RESULT_ID)
        WHERE -- C.CONTROL_ID NOT IN (6, 8) AND -- НЕ УЧИТЫВАЕМ УЧЕБНЫЕ ПРАКТИКИ (v.009)
              SF.SESSPHASE_ID IS NOT NULL AND   -- список учитываемых фаз (v.014)
              NOT M.MAINPROG_HIDFLAG AND        -- исключая "скрытые"
              SG.SGROUP_ID = SGRP_ID AND
              E.SEMESTR = SEM AND
              FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AND
             (A.ACAD_ID IS NULL OR
               D.DOCUMENT_INDATE = (SELECT MAX(U.DOCUMENT_INDATE)
                                      FROM decanet.acad C LEFT JOIN
                                           decanet.document U USING (DOCUMENT_ID)
                                      WHERE C.PERSPROG_ID = P.PERSPROG_ID))
        GROUP BY SG.STUDSGRP_ID, T.RESULT_ID;

    -- НЕ СДАНО
    UPDATE decanet.ttstiprescnt
      SET RESULT_ID = 1000
      WHERE RESULT_ID IS NULL;

    -- кол-ва по студентам и всем допустимым результатам
    DROP TEMPORARY TABLE IF EXISTS decanet.ttstipallrescnt;
    CREATE TEMPORARY TABLE decanet.ttstipallrescnt AS
      SELECT X.STUDSGRP_ID, X.STUDENT_ID, X.RESULT_PASSFLAG, X.RESULT_ID, X.RESULT_INT, X.RESULT_ABBR, T.RCNT
        FROM (SELECT DISTINCT SG.STUDSGRP_ID, SG.STUDENT_ID, S.RESULT_ID, S.RESULT_INT, S.RESULT_ABBR, S.RESULT_PASSFLAG
                FROM decanet.studsgrp SG JOIN
                     decanet.ttresult S
                WHERE SG.SGROUP_ID = SGRP_ID AND
                      FSTUDENT_ACTIVE(SG.STUDSGRP_ID)) X LEFT JOIN
             decanet.ttstiprescnt T USING (STUDSGRP_ID, RESULT_ID);

    -- средние баллы по студентам
    DROP TEMPORARY TABLE IF EXISTS decanet.ttavgball;
    CREATE TEMPORARY TABLE decanet.ttavgball AS
      SELECT STUDSGRP_ID, STUDENT_ID, CAST(SUM(RESULT_INT * RCNT)/ SUM(RCNT) AS DECIMAL(2,1)) AS AVGBALL
        FROM decanet.ttstipallrescnt T
        WHERE RESULT_INT IS NOT NULL
        GROUP BY STUDENT_ID;

    -- удаляем средние баллы студентов, имеющих долги и отрицательные оценки
    DELETE FROM decanet.ttavgball
      WHERE STUDENT_ID IN (SELECT DISTINCT STUDENT_ID
                             FROM decanet.ttstipallrescnt
                             WHERE NOT RESULT_PASSFLAG AND
                                   RCNT > 0);

    -- имеющие долги и 3
    DROP TEMPORARY TABLE IF EXISTS decanet.ttstipcat;
    CREATE TEMPORARY TABLE decanet.ttstipcat AS
      SELECT DISTINCT STUDSGRP_ID, STUDENT_ID, 1 AS CATNO,
                      CAST('Студенты не назначенные на стипендию' AS CHAR(100)) AS CATNAME,
                      CAST('Отказать' AS CHAR(50)) AS DECIGION
        FROM decanet.ttstipallrescnt T
        WHERE RESULT_ID IN (3,4,6,1000) AND
              RCNT > 0;

    DELETE decanet.ttstipallrescnt
      FROM decanet.ttstipcat LEFT JOIN
           decanet.ttstipallrescnt USING (STUDENT_ID);

    -- форма обучения вне бюджет и пр. без стипендии
    DROP TEMPORARY TABLE IF EXISTS decanet.ttstustipcat;
    CREATE TEMPORARY TABLE decanet.ttstustipcat AS
      SELECT * FROM decanet.ttstipcat;

    TRUNCATE decanet.ttstipcat;
    INSERT INTO decanet.ttstipcat
      SELECT DISTINCT T.STUDSGRP_ID, T.STUDENT_ID, 2 AS CATNO,
                     'Форма обучения - контракт' AS CATNAME,
                     'Не назнач.' AS DECIGION
        FROM decanet.ttstipallrescnt T LEFT JOIN
             decanet.studsgrp S USING (STUDSGRP_ID) LEFT JOIN
             decanet.eduform E USING (EDUFORM_ID)
        WHERE NOT EDUFORM_STIP;

    DELETE decanet.ttstipallrescnt
      FROM decanet.ttstipcat LEFT JOIN
           decanet.ttstipallrescnt USING (STUDENT_ID);

    INSERT INTO decanet.ttstudstipcat
      SELECT * FROM decanet.ttstipcat;

    TRUNCATE decanet.ttstipcat;
    INSERT INTO decanet.ttstipcat
      SELECT DISTINCT STUDSGRP_ID, STUDENT_ID, 3 AS CATNO,
                      'Сдавшие на "Хорошо" и "Отлично"' AS CATNAME,
                      'Назначить' AS DECIGION
        FROM decanet.ttstipallrescnt T
        WHERE RESULT_ID = 2 AND
              RCNT > 0;

    DELETE decanet.ttstipallrescnt
      FROM decanet.ttstipcat LEFT JOIN
           decanet.ttstipallrescnt USING (STUDENT_ID);

    INSERT INTO decanet.ttstudstipcat
      SELECT * FROM decanet.ttstipcat;

    TRUNCATE decanet.ttstipcat;
    INSERT INTO decanet.ttstipcat
      SELECT DISTINCT STUDSGRP_ID, STUDENT_ID, 4 AS CATNO,
                      'Сдавшие на "Отлично"' AS CATNAME,
                      'Назначить' AS DECIGION
        FROM decanet.ttstipallrescnt T
        WHERE RESULT_ID = 1 AND
              RCNT > 0;

    INSERT INTO decanet.ttstudstipcat
      SELECT * FROM decanet.ttstipcat;

    SELECT T.CATNAME, IF(E.EDUFORM_ID = 4, E.EDUFORM_NAME, NULL) AS EDUFORM_NAME,
           T.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_PERSNO, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
           IF(G.SBOSS_ID = T.STUDENT_ID, 'Староста', NULL) AS SGBOSS,
           A.AVGBALL, T.DECIGION
      FROM decanet.ttstudstipcat T LEFT JOIN
           decanet.ttavgball A USING (STUDSGRP_ID) LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
           decanet.student S ON S.STUDENT_ID = SG.STUDENT_ID LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID)
      ORDER BY T.CATNO, 2, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;

  ELSE
    SELECT 0 AS RES;
  END IF;

END $$
GRANT EXECUTE ON PROCEDURE decanet.STIPPROT_LST TO A,D,Z,S,V $$

-- детализация по протоколу начисления стипендии
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STIPPROT_ITM $$
CREATE PROCEDURE decanet.STIPPROT_ITM(IN CONN_ID INT, IN SSG_ID INT, IN SEM INT)
COMMENT 'ADZSV'
BEGIN

  IF CONN_ID = CONNECTION_ID() THEN

    -- справочник результатов с НЕ СДАНО
    DROP TEMPORARY TABLE IF EXISTS decanet.ttresult;
    CREATE TEMPORARY TABLE decanet.ttresult AS
      SELECT RESULT_ID, RESULT_INT, RESULT_ABBR, RESULT_NAME, RESULT_PASSFLAG
        FROM decanet.result
        WHERE RESULT_ID < 7
      UNION
      SELECT 1000, NULL, 'Не сдано', 'Не сдано', 0;

    -- имеющиеся результаты студента
    DROP TEMPORARY TABLE IF EXISTS decanet.ttstiprescnt;
    CREATE TEMPORARY TABLE decanet.ttstiprescnt AS
      SELECT SG.STUDENT_ID, T.RESULT_ID, T.RESULT_ABBR, COUNT(*) AS RCNT
        FROM decanet.studsgrp SG LEFT JOIN
             decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
             decanet.stream R USING (STREAM_ID) LEFT JOIN
             decanet.dsession E USING (STREAM_ID) LEFT JOIN
             decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
             decanet.control C USING (CONTROL_ID) LEFT JOIN
             decanet.phasectrl PC USING (CONTROL_ID) LEFT JOIN
             decanet.tt_SFLST SF USING (SESSPHASE_ID) LEFT JOIN
             decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID) LEFT JOIN
             decanet.acad A USING (PERSPROG_ID) LEFT JOIN
             decanet.document D USING (DOCUMENT_ID) LEFT JOIN
             decanet.result T USING (RESULT_ID)
        WHERE -- C.CONTROL_ID NOT IN (6, 8) AND -- НЕ УЧИТЫВАЕМ УЧЕБНЫЕ ПРАКТИКИ (v.009)
              SF.SESSPHASE_ID IS NOT NULL AND   -- список учитываемых фаз (v.014)
              NOT M.MAINPROG_HIDFLAG AND        -- исключая "скрытые"
              SG.STUDSGRP_ID = SSG_ID AND
              E.SEMESTR = SEM AND
             (A.ACAD_ID IS NULL OR
               D.DOCUMENT_INDATE = (SELECT MAX(U.DOCUMENT_INDATE)
                                      FROM decanet.acad C LEFT JOIN
                                           decanet.document U USING (DOCUMENT_ID)
                                      WHERE C.PERSPROG_ID = P.PERSPROG_ID AND
                                            NOT U.DOCUMENT_TEMPFLAG))
        GROUP BY T.RESULT_ID;


    -- НЕ СДАНО
    UPDATE decanet.ttstiprescnt
      SET RESULT_ID = 1000
      WHERE RESULT_ID IS NULL;

    -- кол-ва студента по всем допустимым результатам
    SELECT X.SSG_ID AS STUDSGRP_ID, X.RESULT_ABBR, T.RCNT
      FROM (SELECT DISTINCT SSG_ID, S.RESULT_ID, S.RESULT_INT, S.RESULT_ABBR, S.RESULT_PASSFLAG
              FROM decanet.ttresult S) X LEFT JOIN
           decanet.ttstiprescnt T USING (RESULT_ID)
      ORDER BY X.RESULT_PASSFLAG, X.RESULT_ID DESC;

  ELSE
    SELECT 0 AS RES;
  END IF;

END $$
GRANT EXECUTE ON PROCEDURE decanet.STIPPROT_ITM TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ИТОГИ СЕССИИ
-- ---------------------------------------------------------------------------------------------------

-- только экзамены! (v.0.017)
DROP PROCEDURE IF EXISTS decanet.REP_SESSITOG $$
CREATE PROCEDURE decanet.REP_SESSITOG(IN FID INT,    -- факультет
                                      IN UYEAR YEAR, -- уч.год (2007/2008 => 2007)
                                      IN HYEAR BOOL) -- 0-лето 1-зима
COMMENT 'ADZSV'
BEGIN

  -- отбор сессий и студентов обязанных сдавать
  DROP TEMPORARY TABLE IF EXISTS decanet.ttsslist;
  CREATE TEMPORARY TABLE decanet.ttsslist AS
    SELECT D.DIVISION_ID, R.STREAM_ID, G.SGROUP_ID, E.DSESSION_ID, E.DSESSION_ENDDATE, SG.STUDSGRP_ID, SG.EDUFORM_ID, P.PROLONG_TODATE
      FROM decanet.division D LEFT JOIN
           decanet.stream R USING (DIVISION_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.dsession E USING (STREAM_ID) LEFT JOIN
           decanet.prolong P USING (DSESSION_ID, STUDSGRP_ID)
      WHERE D.FACULTET_ID = FID AND
            R.STREAM_FROMYEAR <= UYEAR AND
            R.STREAM_FROMYEAR + FLOOR(R.STREAM_SEMCOUNT / 2 + 0.5 ) > UYEAR AND
            E.SEMESTR MOD 2 = HYEAR AND
            R.STREAM_FROMYEAR + ((E.SEMESTR + (E.SEMESTR MOD 2)) DIV 2) = UYEAR AND
            FDSTUD_ACTIVE(SG.STUDSGRP_ID, E.DSESSION_ENDDATE) AND
            IF(PROLONG_TODATE IS NULL, true, IF(E.DSESSION_ENDDATE IS NULL, true, PROLONG_TODATE <= E.DSESSION_ENDDATE));

  CREATE INDEX IDX_ttSSLIST ON decanet.ttsslist(DSESSION_ID, STUDSGRP_ID);

  -- справочник результатов с НЕ СДАНО
  DROP TEMPORARY TABLE IF EXISTS decanet.ttresult;
  CREATE TEMPORARY TABLE decanet.ttresult AS
    SELECT RESULT_ID, RESULT_INT, RESULT_ABBR, RESULT_NAME, RESULT_PASSFLAG
      FROM decanet.result
      WHERE RESULT_ID < 5
    UNION
    SELECT 1000, NULL, 'Не сдано', 'Не сдано', 0;

  CREATE INDEX IDX_ttRESULT ON decanet.ttresult(RESULT_ID);


  -- базовый набор студент-результат
  DROP TEMPORARY TABLE IF EXISTS decanet.ttSTUDRESBASE;
  CREATE TEMPORARY TABLE decanet.ttSTUDRESBASE AS
    SELECT TS.STUDSGRP_ID, TR.RESULT_ID
      FROM decanet.ttsslist TS JOIN
           decanet.ttresult TR;

  CREATE INDEX IDX_ttSTUDRESBASE ON decanet.ttSTUDRESBASE(STUDSGRP_ID, RESULT_ID);

  -- имеющиеся результаты студентов
  -- только экзамены
  DROP TEMPORARY TABLE IF EXISTS decanet.ttSTUDRES;
  CREATE TEMPORARY TABLE decanet.ttSTUDRES AS
    SELECT P.PERSPROG_ID, D.DOCUMENT_INDATE, A.RESULT_ID
      FROM decanet.ttsslist TS LEFT JOIN
           decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
           decanet.phasectrl C USING (CONTROL_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID) LEFT JOIN
           decanet.acad A USING (PERSPROG_ID) LEFT JOIN
           decanet.document D USING (DOCUMENT_ID)
      WHERE C.SESSPHASE_ID = 3 AND
            D.DOCUMENT_INDATE = (SELECT MAX(U.DOCUMENT_INDATE)
                                   FROM decanet.acad C LEFT JOIN
                                        decanet.document U USING (DOCUMENT_ID)
                                   WHERE C.PERSPROG_ID = P.PERSPROG_ID AND
                                         IF(TS.DSESSION_ENDDATE IS NULL, true, U.DOCUMENT_INDATE <= TS.DSESSION_ENDDATE) AND -- отсечка по сроку сессии
                                         NOT U.DOCUMENT_TEMPFLAG);

  CREATE INDEX IDX_ttSTUDRES ON decanet.ttSTUDRES(PERSPROG_ID);

  -- все результаты студентов (+ НЕ СДАНО)
  -- только экзамены
  DROP TEMPORARY TABLE IF EXISTS decanet.ttstudallres;
  CREATE TEMPORARY TABLE decanet.ttstudallres AS
    SELECT TS.STUDSGRP_ID, P.PERSPROG_ID, TR.DOCUMENT_INDATE, TR.RESULT_ID
      FROM decanet.ttsslist TS LEFT JOIN
           decanet.mainprog M USING (DSESSION_ID) LEFT JOIN
           decanet.phasectrl C USING (CONTROL_ID) LEFT JOIN
           decanet.persprog P USING (MAINPROG_ID, STUDSGRP_ID) LEFT JOIN
           decanet.ttSTUDRES TR USING (PERSPROG_ID)
     WHERE C.SESSPHASE_ID = 3;

  CREATE INDEX IDX_ttSTUDALLRES ON decanet.ttstudallres(STUDSGRP_ID, RESULT_ID);

  -- НЕ СДАНО
  UPDATE decanet.ttstudallres
    SET RESULT_ID = 1000
    WHERE RESULT_ID IS NULL;

  -- кол-ва по студентам и результатам
  DROP TEMPORARY TABLE IF EXISTS decanet.ttstudrescnt;
  CREATE TEMPORARY TABLE decanet.ttstudrescnt AS
    SELECT B.STUDSGRP_ID, B.RESULT_ID, T.RESULT_INT, T.RESULT_PASSFLAG, T.RESULT_ABBR, COUNT(SR.RESULT_ID) AS RCNT
      FROM decanet.ttSTUDRESBASE B LEFT JOIN
           decanet.ttstudallres SR USING (STUDSGRP_ID, RESULT_ID) LEFT JOIN
           decanet.ttresult T USING (RESULT_ID)
      GROUP BY B.STUDSGRP_ID, B.RESULT_ID;

  -- итоги по группам
  DROP TEMPORARY TABLE IF EXISTS decanet.ttsgrpdata;
  CREATE TEMPORARY TABLE decanet.ttsgrpdata(
    SGROUP_ID INT NOT NULL,
    RESN INT,
    CRESN INT,
    RES2 INT,
    CRES2 INT,
    RES3 INT,
    CRES3 INT,
    RES4 INT,
    CRES4 INT,
    RES5 INT,
    CRES5 INT);

  INSERT INTO decanet.ttsgrpdata(SGROUP_ID)
    SELECT DISTINCT SGROUP_ID
      FROM decanet.ttsslist TS;

  -- имеющие долги
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatlist;
  CREATE TEMPORARY TABLE decanet.ttcatlist AS
    SELECT DISTINCT STUDSGRP_ID
      FROM decanet.ttstudrescnt
      WHERE RESULT_ID IN (6, 1000) AND
            RCNT > 0;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatitog;
  CREATE TEMPORARY TABLE decanet.ttcatitog AS
    SELECT SG.SGROUP_ID, COUNT(DISTINCT T.STUDSGRP_ID) AS SCNT,
                         COUNT(DISTINCT IF (EDUFORM_ID = 4, T.STUDSGRP_ID, null)) AS CCNT
      FROM decanet.ttstudrescnt T LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      WHERE RESULT_ID IN (6, 1000) AND
            RCNT > 0
      GROUP BY SG.SGROUP_ID;

  UPDATE decanet.ttsgrpdata D LEFT JOIN
         decanet.ttcatitog I USING (SGROUP_ID)
    SET D.RESN = IFNULL(I.SCNT, 0),
        D.CRESN = IFNULL(I.CCNT, 0);

  DELETE decanet.ttstudrescnt
    FROM decanet.ttcatlist LEFT JOIN
         decanet.ttstudrescnt USING (STUDSGRP_ID);

  -- имеющие неуды
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatlist;
  CREATE TEMPORARY TABLE decanet.ttcatlist AS
    SELECT DISTINCT STUDSGRP_ID
      FROM decanet.ttstudrescnt
      WHERE RESULT_ID = 4 AND
            RCNT > 0;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatitog;
  CREATE TEMPORARY TABLE decanet.ttcatitog AS
    SELECT SG.SGROUP_ID, COUNT(DISTINCT T.STUDSGRP_ID) AS SCNT,
                         COUNT(DISTINCT IF (EDUFORM_ID = 4, T.STUDSGRP_ID, null)) AS CCNT
      FROM decanet.ttstudrescnt T LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      WHERE RESULT_ID = 4
            AND RCNT > 0
      GROUP BY SG.SGROUP_ID;

  UPDATE decanet.ttsgrpdata D LEFT JOIN
         decanet.ttcatitog I USING (SGROUP_ID)
    SET D.RES2 = IFNULL(I.SCNT, 0),
        D.CRES2 = IFNULL(I.CCNT, 0);

  DELETE decanet.ttstudrescnt
    FROM decanet.ttcatlist LEFT JOIN
         decanet.ttstudrescnt USING (STUDSGRP_ID);

  -- имеющие уды
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatlist;
  CREATE TEMPORARY TABLE decanet.ttcatlist AS
    SELECT DISTINCT STUDSGRP_ID
      FROM decanet.ttstudrescnt
      WHERE RESULT_ID = 3 AND
            RCNT > 0;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatitog;
  CREATE TEMPORARY TABLE decanet.ttcatitog AS
    SELECT SG.SGROUP_ID, COUNT(DISTINCT T.STUDSGRP_ID) AS SCNT,
                         COUNT(DISTINCT IF (EDUFORM_ID = 4, T.STUDSGRP_ID, null)) AS CCNT
      FROM decanet.ttstudrescnt T LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      WHERE RESULT_ID = 3
            AND RCNT > 0
      GROUP BY SG.SGROUP_ID;

  UPDATE decanet.ttsgrpdata D LEFT JOIN
         decanet.ttcatitog I USING (SGROUP_ID)
    SET D.RES3 = IFNULL(I.SCNT, 0),
        D.CRES3 = IFNULL(I.CCNT, 0);

  DELETE decanet.ttstudrescnt
    FROM decanet.ttcatlist LEFT JOIN
         decanet.ttstudrescnt USING (STUDSGRP_ID);

  -- имеющие xop
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatlist;
  CREATE TEMPORARY TABLE decanet.ttcatlist AS
    SELECT DISTINCT STUDSGRP_ID
      FROM decanet.ttstudrescnt
      WHERE RESULT_ID = 2 AND
            RCNT > 0;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatitog;
  CREATE TEMPORARY TABLE decanet.ttcatitog AS
    SELECT SG.SGROUP_ID, COUNT(DISTINCT T.STUDSGRP_ID) AS SCNT,
                         COUNT(DISTINCT IF (EDUFORM_ID = 4, T.STUDSGRP_ID, null)) AS CCNT
      FROM decanet.ttstudrescnt T LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      WHERE RESULT_ID = 2
            AND RCNT > 0
      GROUP BY SG.SGROUP_ID;

  UPDATE decanet.ttsgrpdata D LEFT JOIN
         decanet.ttcatitog I USING (SGROUP_ID)
    SET D.RES4 = IFNULL(I.SCNT, 0),
        D.CRES4 = IFNULL(I.CCNT, 0);

  DELETE decanet.ttstudrescnt
    FROM decanet.ttcatlist LEFT JOIN
         decanet.ttstudrescnt USING (STUDSGRP_ID);

  -- сдавшие на отл
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatlist;
  CREATE TEMPORARY TABLE decanet.ttcatlist AS
    SELECT DISTINCT STUDSGRP_ID
      FROM decanet.ttstudrescnt
      WHERE RESULT_ID = 1 AND
            RCNT > 0;

  DROP TEMPORARY TABLE IF EXISTS decanet.ttcatitog;
  CREATE TEMPORARY TABLE decanet.ttcatitog AS
    SELECT SG.SGROUP_ID, COUNT(DISTINCT T.STUDSGRP_ID) AS SCNT,
                         COUNT(DISTINCT IF (EDUFORM_ID = 4, T.STUDSGRP_ID, null)) AS CCNT
      FROM decanet.ttstudrescnt T LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID)
      WHERE RESULT_ID = 1
            AND RCNT > 0
      GROUP BY SG.SGROUP_ID;

  UPDATE decanet.ttsgrpdata D LEFT JOIN
         decanet.ttcatitog I USING (SGROUP_ID)
    SET D.RES5 = IFNULL(I.SCNT, 0),
        D.CRES5 = IFNULL(I.CCNT, 0);

/*
  DELETE decanet.ttstudrescnt
    FROM decanet.ttSITOGCAT LEFT JOIN
         decanet.ttstudrescnt USING (STUDSGRP_ID);
*/

  SELECT TS.DIVISION_ID, D.DIVISION_NAME, TS.SGROUP_ID, SGROUPAUTONAME(SGROUP_ID) AS SGNAME,
         COUNT(TS.STUDSGRP_ID) AS ALLCNT,
         COUNT(IF(TS.EDUFORM_ID = 4, 1, NULL)) AS CONTRCNT,
         GD.RESN, GD.CRESN, GD.RES2, GD.CRES2, GD.RES3, GD.CRES3, GD.RES4, GD.CRES4, GD.RES5, GD.CRES5
    FROM decanet.ttsslist TS LEFT JOIN
         decanet.ttsgrpdata GD USING (SGROUP_ID) LEFT JOIN
         decanet.division D USING (DIVISION_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID)
    GROUP BY TS.DIVISION_ID, TS.SGROUP_ID
    ORDER BY D.DIVISION_NAME, R.STREAM_FROMYEAR DESC, SGROUPAUTONAME(SGROUP_ID);


END$$
GRANT EXECUTE ON PROCEDURE decanet.REP_SESSITOG TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ XIII. ПОИСК СТУДЕНТА ПО ШАБЛОНУ ФАМИЛИИ
-- ---------------------------------------------------------------------------------------------------

-- поиск студента по шаблону фамилии с учетом ограничений прав тек. DUSER-а на объекты CNT
DROP PROCEDURE IF EXISTS decanet.FND_STUDLN_CNT $$
CREATE PROCEDURE decanet.FND_STUDLN_CNT(IN SLNAME VARCHAR(50))
COMMENT 'ADZSV'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

  IF NOT LOCATE('%', SLNAME) THEN
    SET SLNAME = CONCAT(SLNAME, '%');
  END IF;

  SELECT COUNT(SG.STUDENT_ID) AS CNT
    FROM decanet.country C LEFT JOIN
         decanet.region R USING (COUNTRY_ID) LEFT JOIN
         decanet.city Y USING (REGION_ID) LEFT JOIN
         decanet.school H USING (CITY_ID) LEFT JOIN
         decanet.facultet F USING (SCHOOL_ID) LEFT JOIN
         decanet.division D USING (FACULTET_ID) LEFT JOIN
         decanet.stream E USING (DIVISION_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID)
    WHERE IF(CNT_ID IS NULL, TRUE, C.COUNTRY_ID = CNT_ID) AND
          IF(REG_ID IS NULL, TRUE, R.REGION_ID = REG_ID) AND
          IF(CTY_ID IS NULL, TRUE, Y.CITY_ID = CTY_ID) AND
          IF(SCH_ID IS NULL, TRUE, H.SCHOOL_ID = SCH_ID) AND
          IF(FAC_ID IS NULL, TRUE, F.FACULTET_ID = FAC_ID) AND
          IF(DIV_ID IS NULL, TRUE, D.DIVISION_ID = DIV_ID) AND
          IF(SGR_ID IS NULL, TRUE, G.SGROUP_ID = SGR_ID) AND
          IF(STD_ID IS NULL, TRUE, S.STUDENT_ID = STD_ID) AND
          S.STUDENT_LNAME LIKE SLNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_STUDLN_CNT TO A,D,Z,S,V $$

-- поиск студента по шаблону фамилии с учетом ограничений прав тек. DUSER-а на объекты LIST
DROP PROCEDURE IF EXISTS decanet.FND_STUDLN_LST $$
CREATE PROCEDURE decanet.FND_STUDLN_LST(IN SLNAME VARCHAR(50))
COMMENT 'ADZSV'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

  IF NOT LOCATE('%', SLNAME) THEN
    SET SLNAME = CONCAT(SLNAME, '%');
  END IF;

  SELECT C.COUNTRY_ID, C.COUNTRY_ABBR,
         R.REGION_ID, R.REGION_NAME,
         Y.CITY_ID, Y.CITY_NAME,
         H.SCHOOL_ID, H.SCHOOL_ABBR,
         F.FACULTET_ID, F.FACULTET_ABBR,
         D.DIVISION_ID, D.DIVISION_ABBR,
         G.SGROUP_ID, SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(T.STREAM_FROMYEAR, T.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SG.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
    FROM decanet.country C LEFT JOIN
         decanet.region R USING (COUNTRY_ID) LEFT JOIN
         decanet.city Y USING (REGION_ID) LEFT JOIN
         decanet.school H USING (CITY_ID) LEFT JOIN
         decanet.facultet F USING (SCHOOL_ID) LEFT JOIN
         decanet.division D USING (FACULTET_ID) LEFT JOIN
         decanet.stream T USING (DIVISION_ID) LEFT JOIN
         decanet.sgroup G USING (STREAM_ID) LEFT JOIN
         decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID)
    WHERE IF(CNT_ID IS NULL, TRUE, C.COUNTRY_ID = CNT_ID) AND
          IF(REG_ID IS NULL, TRUE, R.REGION_ID = REG_ID) AND
          IF(CTY_ID IS NULL, TRUE, Y.CITY_ID = CTY_ID) AND
          IF(SCH_ID IS NULL, TRUE, H.SCHOOL_ID = SCH_ID) AND
          IF(FAC_ID IS NULL, TRUE, F.FACULTET_ID = FAC_ID) AND
          IF(DIV_ID IS NULL, TRUE, D.DIVISION_ID = DIV_ID) AND
          IF(SGR_ID IS NULL, TRUE, G.SGROUP_ID = SGR_ID) AND
          IF(STD_ID IS NULL, TRUE, S.STUDENT_ID = STD_ID) AND
          S.STUDENT_LNAME LIKE SLNAME
    ORDER BY S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
             C.COUNTRY_ABBR, R.REGION_NAME, Y.CITY_NAME,
             H.SCHOOL_ABBR, F.FACULTET_ABBR, D.DIVISION_ABBR, G.SGROUP_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_STUDLN_LST TO A,D,Z,S,V $$

-- поиск студента по осн. параметрам с учетом ограничений прав тек. DUSER-а на объекты LIST
DROP PROCEDURE IF EXISTS decanet.FND_STUD_LST $$
CREATE PROCEDURE decanet.FND_STUD_LST( IN AFAC_ID INT,        -- факультет (выбор из списка)
                                       IN ADIV_ID INT,        -- отделение (выбор из списка)
                                       IN SFY YEAR,           -- год поступления
                                       IN SGR_AN VARCHAR(25), -- наименование группы
                                       IN NUM VARCHAR(25),     -- перс.номер или номер зачетки
                                       IN SFNAME VARCHAR(50), -- имя
                                       IN SMNAME VARCHAR(50), -- отчество
                                       IN SLNAME VARCHAR(50), -- фамилия
                                       IN STAT BOOL)          -- флаг-активность
COMMENT 'ADZSV'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

  -- переопределение по правам
  IF FAC_ID IS NOT NULL THEN
    SET AFAC_ID = FAC_ID;
  END IF;

  IF DIV_ID IS NOT NULL THEN
    SET ADIV_ID = DIV_ID;
  END IF;

  -- маски
  IF NOT LOCATE('%', SFNAME) THEN
    SET SFNAME = CONCAT(SFNAME, '%');
  END IF;

  IF NOT LOCATE('%', SMNAME) THEN
    SET SMNAME = CONCAT(SMNAME, '%');
  END IF;

  IF NOT LOCATE('%', SLNAME) THEN
    SET SLNAME = CONCAT(SLNAME, '%');
  END IF;

  IF NOT LOCATE('%', SGR_AN) THEN
    SET SGR_AN = CONCAT('%', SGR_AN, '%');
  END IF;

  IF NOT LOCATE('%', NUM) THEN
    SET NUM = CONCAT('%', NUM, '%');
  END IF;

  SELECT C.COUNTRY_ID, C.COUNTRY_ABBR,
         R.REGION_ID, R.REGION_NAME,
         Y.CITY_ID, Y.CITY_NAME,
         H.SCHOOL_ID, H.SCHOOL_ABBR,
         F.FACULTET_ID, F.FACULTET_ABBR,
         D.DIVISION_ID, D.DIVISION_ABBR,
         G.SGROUP_ID,
         SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(T.STREAM_FROMYEAR, T.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SG.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
    FROM decanet.student S LEFT JOIN
         decanet.studsgrp SG USING (STUDENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream T USING (STREAM_ID) LEFT JOIN
         decanet.division D ON D.DIVISION_ID = T.DIVISION_ID LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school H USING (SCHOOL_ID) LEFT JOIN
         decanet.city Y USING (CITY_ID) LEFT JOIN
         decanet.region R USING (REGION_ID) LEFT JOIN
         decanet.country C USING (COUNTRY_ID)
    WHERE IF(CNT_ID IS NULL, TRUE, C.COUNTRY_ID = CNT_ID) AND
          IF(REG_ID IS NULL, TRUE, R.REGION_ID = REG_ID) AND
          IF(CTY_ID IS NULL, TRUE, Y.CITY_ID = CTY_ID) AND
          IF(SCH_ID IS NULL, TRUE, H.SCHOOL_ID = SCH_ID) AND
          IF(AFAC_ID IS NULL, TRUE, F.FACULTET_ID = AFAC_ID) AND
          IF(ADIV_ID IS NULL, TRUE, D.DIVISION_ID = ADIV_ID) AND
          IF(SGR_ID IS NULL, TRUE, G.SGROUP_ID = SGR_ID) AND
          IF(STD_ID IS NULL, TRUE, S.STUDENT_ID = STD_ID) AND
          IF(SFY IS NULL, TRUE, T.STREAM_FROMYEAR = SFY) AND
          IF(SGR_AN IS NULL, TRUE, SGROUPAUTONAME(G.SGROUP_ID) LIKE SGR_AN) AND
          IF(NUM IS NULL, TRUE, (S.STUDENT_PERSNO LIKE NUM) OR
                                  (S.STUDENT_ZACHNO LIKE NUM)) AND
          IF(SFNAME IS NULL, TRUE, S.STUDENT_FNAME LIKE SFNAME) AND
          IF(SMNAME IS NULL, TRUE, S.STUDENT_MNAME LIKE SMNAME) AND
          IF(SLNAME IS NULL, TRUE, S.STUDENT_LNAME LIKE SLNAME) AND
          IF(STAT IS NULL, TRUE, FSTUDENT_ACTIVE(SG.STUDSGRP_ID) = STAT)
    ORDER BY C.COUNTRY_ABBR, R.REGION_NAME, Y.CITY_NAME,
             H.SCHOOL_ABBR, F.FACULTET_ABBR, D.DIVISION_ABBR,
             T.STREAM_FROMYEAR, G.SGROUP_NAMEINDEX,
             S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_STUD_LST TO A,D,Z,S,V $$

-- поиск студента по конт. операциям за период
-- с учетом ограничений прав тек. DUSER-а на объекты LIST
DROP PROCEDURE IF EXISTS decanet.FND_STUDCONT_LST $$
CREATE PROCEDURE decanet.FND_STUDCONT_LST( IN AFAC_ID INT,        -- факультет (выбор из списка)
                                           IN ADIV_ID INT,        -- отделение (выбор из списка)
                                           IN SS_ID INT,          -- STUDSTATUS_ID
                                           IN FD DATE,             -- from date
                                           IN TD DATE)             -- to date
COMMENT 'ADZSV'
BEGIN
  DECLARE CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID INT;
  DECLARE BN VARCHAR(255);

  SET BN = HEX(ENCODE(SUBSTRING_INDEX(USER(),'@',1), 'GoNdUrAs'));

  SELECT COUNTRY_ID, REGION_ID, CITY_ID, SCHOOL_ID, FACULTET_ID, DIVISION_ID, SGROUP_ID, STUDENT_ID
    INTO CNT_ID, REG_ID, CTY_ID, SCH_ID, FAC_ID, DIV_ID, SGR_ID, STD_ID
    FROM decanet.duser
    WHERE BUNAME = BN LIMIT 1;

  -- переопределение по правам
  IF FAC_ID IS NOT NULL THEN
    SET AFAC_ID = FAC_ID;
  END IF;

  IF DIV_ID IS NOT NULL THEN
    SET ADIV_ID = DIV_ID;
  END IF;

  SELECT C.COUNTRY_ID, C.COUNTRY_ABBR,
         R.REGION_ID, R.REGION_NAME,
         Y.CITY_ID, Y.CITY_NAME,
         H.SCHOOL_ID, H.SCHOOL_ABBR,
         F.FACULTET_ID, F.FACULTET_ABBR,
         V.DIVISION_ID, V.DIVISION_ABBR,
         G.SGROUP_ID,
         SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(T.STREAM_FROMYEAR, T.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SG.STUDSGRP_ID, S.STUDENT_ID, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE,
         SS.STUDSTATUS_ID, SS.STUDSTATUS_ACTIVE, SS.STUDSTATUS_NAME,
         D.DOCUMENT_NO, D.DOCUMENT_INDATE, DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS
    FROM decanet.contingent CN LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID)LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.studstatus SS USING (STUDSTATUS_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream T USING (STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = T.DIVISION_ID LEFT JOIN
         decanet.facultet F ON F.FACULTET_ID = V.FACULTET_ID LEFT JOIN
         decanet.school H USING (SCHOOL_ID) LEFT JOIN
         decanet.city Y USING (CITY_ID) LEFT JOIN
         decanet.region R USING (REGION_ID) LEFT JOIN
         decanet.country C USING (COUNTRY_ID)
    WHERE IF(CNT_ID IS NULL, TRUE, C.COUNTRY_ID = CNT_ID) AND
          IF(REG_ID IS NULL, TRUE, R.REGION_ID = REG_ID) AND
          IF(CTY_ID IS NULL, TRUE, Y.CITY_ID = CTY_ID) AND
          IF(SCH_ID IS NULL, TRUE, H.SCHOOL_ID = SCH_ID) AND
          IF(AFAC_ID IS NULL, TRUE, F.FACULTET_ID = AFAC_ID) AND
          IF(ADIV_ID IS NULL, TRUE, V.DIVISION_ID = ADIV_ID) AND
          IF(SS_ID IS NULL, TRUE, CN.STUDSTATUS_ID = SS_ID) AND
          IF(FD IS NULL, TRUE, CN.CONTINGENT_DATE >= FD) AND
          IF(TD IS NULL, TRUE, CN.CONTINGENT_DATE <= FD)
    ORDER BY C.COUNTRY_ABBR, R.REGION_NAME, Y.CITY_NAME,
             H.SCHOOL_ABBR, F.FACULTET_ABBR, V.DIVISION_ABBR,
             T.STREAM_FROMYEAR, G.SGROUP_NAMEINDEX,
             S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_STUDCONT_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- СВОДКА ДВИЖЕНИЯ КОНТИНГЕНТА
-- ---------------------------------------------------------------------------------------------------

-- собственно сводка
-- !!! ИСПРАВИТЬ - НЕ УЧТЕНА ЗАВЕРШЕННОСТЬ ДОКУМЕНТОВ !
DROP PROCEDURE IF EXISTS decanet.REP_CONTINGENT $$
CREATE PROCEDURE decanet.REP_CONTINGENT(IN PERIOD DATE, IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN

  DECLARE NPERIOD DATE;

  SET PERIOD = CAST((CONCAT(YEAR(PERIOD), '-', MONTH(PERIOD), '-01')) AS DATE);
  SET NPERIOD = PERIOD + INTERVAL 1 MONTH;

  -- статус студентов на начало периода
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontstart;
  CREATE TEMPORARY TABLE decanet.ttcontstart AS
    SELECT D.DIVISION_ID, SGROUP_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS, SG.STUDSGRP_ID, SG.EDUFORM_ID,
           IFNULL(A.STUDENT_SEX, 'М') AS STUDENT_SEX, U.STUDSTATUS_ACTIVE
      FROM decanet.division D LEFT JOIN
           decanet.stream R USING (DIVISION_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.studadd A ON A.STUDENT_ID = SG.STUDENT_ID LEFT JOIN
           decanet.contingent C USING (STUDSGRP_ID) LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID)
      WHERE D.FACULTET_ID = FAC_ID AND
            FSGROUP_ACTIVE(G.SGROUP_ID) AND
            C.CONTINGENT_DATE < PERIOD AND
            C.CONTINGENT_DATE = (SELECT MAX(T.CONTINGENT_DATE)
                                   FROM decanet.contingent T LEFT JOIN
                                        decanet.document M USING (DOCUMENT_ID)
                                   WHERE T.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                         NOT M.DOCUMENT_TEMPFLAG AND
                                         T.CONTINGENT_DATE < PERIOD) AND
            NOT DT.DOCUMENT_TEMPFLAG;

  -- общее кол-во на начало
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontstartmain;
  CREATE TEMPORARY TABLE decanet.ttcontstartmain AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS STARTMAINCNT
      FROM decanet.ttcontstart
      WHERE STUDSTATUS_ACTIVE
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. мужчин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontstartmans;
  CREATE TEMPORARY TABLE decanet.ttcontstartmans AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS STARTMANCNT
      FROM decanet.ttcontstart
      WHERE STUDSTATUS_ACTIVE AND
            STUDENT_SEX = 'М'
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. женщин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontstartwomans;
  CREATE TEMPORARY TABLE decanet.ttcontstartwomans AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS STARTWOMANCNT
      FROM decanet.ttcontstart
      WHERE STUDSTATUS_ACTIVE AND
            STUDENT_SEX = 'Ж'
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. контракт
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontstartkontr;
  CREATE TEMPORARY TABLE decanet.ttcontstartkontr AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS STARTKONTRCNT
      FROM decanet.ttcontstart
      WHERE STUDSTATUS_ACTIVE AND
            EDUFORM_ID = 4
      GROUP BY DIVISION_ID, KURS;

  -- статус студентов на конец периода
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontfin;
  CREATE TEMPORARY TABLE decanet.ttcontfin AS
    SELECT D.DIVISION_ID, SGROUP_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS, SG.STUDSGRP_ID, SG.EDUFORM_ID,
           IFNULL(A.STUDENT_SEX, 'М') AS STUDENT_SEX, U.STUDSTATUS_ACTIVE
      FROM decanet.division D LEFT JOIN
           decanet.stream R USING (DIVISION_ID) LEFT JOIN
           decanet.sgroup G USING (STREAM_ID) LEFT JOIN
           decanet.studsgrp SG USING (SGROUP_ID) LEFT JOIN
           decanet.studadd A ON A.STUDENT_ID = SG.STUDENT_ID LEFT JOIN
           decanet.contingent C USING (STUDSGRP_ID) LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID)
      WHERE D.FACULTET_ID = FAC_ID AND
            FSGROUP_ACTIVE(G.SGROUP_ID) AND
            -- U.STUDSTATUS_ACTIVE AND
            C.CONTINGENT_DATE < NPERIOD AND
            C.CONTINGENT_DATE = (SELECT MAX(T.CONTINGENT_DATE)
                                   FROM decanet.contingent T LEFT JOIN
                                        decanet.document M USING (DOCUMENT_ID)
                                   WHERE T.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                         NOT M.DOCUMENT_TEMPFLAG AND
                                         T.CONTINGENT_DATE < NPERIOD) AND
            NOT DT.DOCUMENT_TEMPFLAG;

  -- общее кол-во на конец
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontfinmain;
  CREATE TEMPORARY TABLE decanet.ttcontfinmain AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS FINMAINCNT
      FROM decanet.ttcontfin
      WHERE STUDSTATUS_ACTIVE
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. мужчин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontfinmans;
  CREATE TEMPORARY TABLE decanet.ttcontfinmans AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS FINMANCNT
      FROM decanet.ttcontfin
      WHERE STUDSTATUS_ACTIVE AND
            STUDENT_SEX = 'М'
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. женщин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontfinwomans;
  CREATE TEMPORARY TABLE decanet.ttcontfinwomans AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS FINWOMANCNT
      FROM decanet.ttcontfin
      WHERE STUDSTATUS_ACTIVE AND
            STUDENT_SEX = 'Ж'
      GROUP BY DIVISION_ID, KURS;

  -- общее кол-во в.т.ч. контракт
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontfinkontr;
  CREATE TEMPORARY TABLE decanet.ttcontfinkontr AS
    SELECT DIVISION_ID, KURS, COUNT(STUDSGRP_ID) AS FINKONTRCNT
      FROM decanet.ttcontfin
      WHERE STUDSTATUS_ACTIVE AND
            EDUFORM_ID = 4
      GROUP BY DIVISION_ID, KURS;

  -- общее категорированное кол-во
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontmain;
  CREATE TEMPORARY TABLE decanet.ttcontmain AS
    SELECT D.DIVISION_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS,
           T.STATUSTYPE_ID, COUNT(SG.STUDENT_ID) AS MAINCNT
      FROM decanet.contingent C LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID) LEFT JOIN
           decanet.statustype T USING (STATUSTYPE_ID) LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE C.CONTINGENT_DATE >= PERIOD AND
            C.CONTINGENT_DATE < NPERIOD AND
            D.FACULTET_ID = FAC_ID AND
            NOT DT.DOCUMENT_TEMPFLAG
      GROUP BY D.DIVISION_ID, R.STREAM_FROMYEAR, T.STATUSTYPE_ID;

  -- в т.ч. мужчин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontmans;
  CREATE TEMPORARY TABLE decanet.ttcontmans AS
    SELECT D.DIVISION_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS,
           T.STATUSTYPE_ID, COUNT(SG.STUDENT_ID) AS MANCNT
      FROM decanet.contingent C LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID) LEFT JOIN
           decanet.statustype T USING (STATUSTYPE_ID) LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.studadd A USING (STUDENT_ID) LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE IF(A.STUDENT_SEX IS NULL, TRUE, A.STUDENT_SEX = 'М') AND
            C.CONTINGENT_DATE >= PERIOD AND
            C.CONTINGENT_DATE < DATE_ADD(PERIOD, INTERVAL 1 MONTH) AND
            D.FACULTET_ID = FAC_ID AND
            NOT DT.DOCUMENT_TEMPFLAG
      GROUP BY D.DIVISION_ID, R.STREAM_FROMYEAR, T.STATUSTYPE_ID;

  -- в т.ч. женщин
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontwomans;
  CREATE TEMPORARY TABLE decanet.ttcontwomans AS
    SELECT D.DIVISION_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS,
           T.STATUSTYPE_ID, COUNT(SG.STUDENT_ID) AS WOMANCNT
      FROM decanet.contingent C LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID) LEFT JOIN
           decanet.statustype T USING (STATUSTYPE_ID) LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.studadd A USING (STUDENT_ID) LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE IF(A.STUDENT_SEX IS NULL, FALSE, A.STUDENT_SEX = 'Ж') AND
            C.CONTINGENT_DATE >= PERIOD AND
            C.CONTINGENT_DATE < DATE_ADD(PERIOD, INTERVAL 1 MONTH) AND
            D.FACULTET_ID = FAC_ID AND
            NOT DT.DOCUMENT_TEMPFLAG
      GROUP BY D.DIVISION_ID, R.STREAM_FROMYEAR, T.STATUSTYPE_ID;

  -- в т.ч. контракт
  DROP TEMPORARY TABLE IF EXISTS decanet.ttcontkontr;
  CREATE TEMPORARY TABLE decanet.ttcontkontr AS
    SELECT D.DIVISION_ID, SGROUPKURS(G.SGROUP_ID, PERIOD) AS KURS,
           T.STATUSTYPE_ID, COUNT(SG.STUDENT_ID) AS KONTRCNT
      FROM decanet.contingent C LEFT JOIN
           decanet.document DT USING (DOCUMENT_ID) LEFT JOIN
           decanet.studstatus U USING (STUDSTATUS_ID) LEFT JOIN
           decanet.statustype T USING (STATUSTYPE_ID) LEFT JOIN
           decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
           decanet.student S USING (STUDENT_ID) LEFT JOIN
           decanet.studadd A USING (STUDENT_ID) LEFT JOIN
           decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
           decanet.stream R USING (STREAM_ID) LEFT JOIN
           decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
      WHERE SG.EDUFORM_ID = 4 AND
            C.CONTINGENT_DATE >= PERIOD AND
            C.CONTINGENT_DATE < DATE_ADD(PERIOD, INTERVAL 1 MONTH) AND
            D.FACULTET_ID = FAC_ID AND
            NOT DT.DOCUMENT_TEMPFLAG
      GROUP BY D.DIVISION_ID, R.STREAM_FROMYEAR, T.STATUSTYPE_ID;

  -- СВОДКА
  SELECT V.DIVISION_ID, V.DIVISION_NAME, A.KURS,
         -1 AS STATUSTYPE_ID,
         CAST(CONCAT('Cостояло на ', DATE_FORMAT(PERIOD, '%d.%m.%Y')) AS CHAR(255)) AS STATUSTYPE_NAME,
         IFNULL(A.STARTMAINCNT, 0) AS MAINCNT,
         IFNULL(B.STARTMANCNT, 0) AS MANCNT,
         IFNULL(C.STARTWOMANCNT, 0) AS WOMANCNT,
         IFNULL(D.STARTKONTRCNT, 0) AS KONTRCNT
    FROM decanet.ttcontstartmain A LEFT JOIN
         decanet.ttcontstartmans B USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.ttcontstartwomans C USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.ttcontstartkontr D USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.division V USING (DIVISION_ID) UNION
  SELECT V.DIVISION_ID, V.DIVISION_NAME, A.KURS,
         10000 AS STATUSTYPE_ID,
         CAST(CONCAT('Cостоит на ', DATE_FORMAT(DATE_ADD(PERIOD, INTERVAL 1 MONTH), '%d.%m.%Y')) AS CHAR(255)) AS STATUSTYPE_NAME,
         IFNULL(A.FINMAINCNT, 0) AS MAINCNT,
         IFNULL(B.FINMANCNT, 0) AS MANCNT,
         IFNULL(C.FINWOMANCNT, 0) AS WOMANCNT,
         IFNULL(D.FINKONTRCNT, 0) AS KONTRCNT
    FROM decanet.ttcontfinmain A LEFT JOIN
         decanet.ttcontfinmans B USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.ttcontfinwomans C USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.ttcontfinkontr D USING (DIVISION_ID, KURS) LEFT JOIN
         decanet.division V USING (DIVISION_ID) UNION
  SELECT V.DIVISION_ID, V.DIVISION_NAME, A.KURS,
         T.STATUSTYPE_ID,
         T.STATUSTYPE_NAME,
         IFNULL(A.MAINCNT, 0) AS MAINCNT,
         IFNULL(B.MANCNT, 0) AS MANCNT,
         IFNULL(C.WOMANCNT, 0) AS WOMANCNT,
         IFNULL(D.KONTRCNT, 0) AS KONTRCNT
    FROM decanet.ttcontmain A LEFT JOIN
         ttcontmans B USING (DIVISION_ID, KURS, STATUSTYPE_ID) LEFT JOIN
         ttcontwomans C USING (DIVISION_ID, KURS, STATUSTYPE_ID) LEFT JOIN
         ttcontkontr D USING (DIVISION_ID, KURS, STATUSTYPE_ID) LEFT JOIN
         decanet.statustype T USING (STATUSTYPE_ID) LEFT JOIN
         decanet.division V USING (DIVISION_ID)
  ORDER BY DIVISION_ID, KURS, STATUSTYPE_ID;

END $$
GRANT EXECUTE ON PROCEDURE decanet.REP_CONTINGENT TO A,D,Z,S,V $$

-- список документов Приказов по л/с, обеспечивших движение контингента
DROP PROCEDURE IF EXISTS decanet.REP_CONTDOC_LST $$
CREATE PROCEDURE decanet.REP_CONTDOC_LST (IN PERIOD DATE, IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DISTINCT D.DOCUMENT_ID,
         D.DOCUMENT_NO,
         CAST(D.DOCUMENT_INDATE AS DATE) AS DOCUMENT_INDATE
    FROM decanet.contingent C LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE D.FACULTET_ID = FAC_ID AND
          NOT D.DOCUMENT_TEMPFLAG AND
          C.CONTINGENT_DATE >= PERIOD AND
          C.CONTINGENT_DATE < DATE_ADD(PERIOD, INTERVAL 1 MONTH)
    ORDER BY D.DOCUMENT_INDATE;
END $$
GRANT EXECUTE ON PROCEDURE decanet.REP_CONTDOC_LST TO A,D,Z,S,V $$

-- ---------------------------------------------------------------------------------------------------
-- УЧЕБНЫЕ СПРАВКИ (ПО МЕСТУ ТРЕБОВАНИЯ и  В ПФР)
-- ---------------------------------------------------------------------------------------------------

-- выдача учебной справки
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.USPR_ADD $$
CREATE PROCEDURE decanet.USPR_ADD(IN SSG_ID INT, IN DT_ID INT) -- DT_ID = 9 - по месту треб, 10 - в ПФР
COMMENT 'DZS'
BEGIN
  DECLARE FID, SSA, DOC_ID INT;

  SELECT D.FACULTET_ID, FSTUDENT_ACTIVE(SG.STUDSGRP_ID) INTO FID, SSA
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.division D ON D.DIVISION_ID = R.DIVISION_ID
    WHERE SG.STUDSGRP_ID = SSG_ID;

  IF (NOT DT_ID IN (9, 10)) OR (NOT SSA) THEN
    SELECT NULL AS DOCUMENT_ID;
  ELSE
    INSERT INTO decanet.document(DOCUMENT_ID, DOCTYPE_ID, FACULTET_ID, DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_INDATE)
      SELECT NULL, DT_ID, FID, FALSE, NOW(), NOW();

    SET DOC_ID = LAST_INSERT_ID();

    INSERT INTO decanet.studdoc(STUDDOC_ID, STUDSGRP_ID, DOCUMENT_ID)
      VALUES(NULL, SSG_ID, DOC_ID);

    UPDATE decanet.document D
      SET D.DOCUMENT_BARNO = CONCAT(FID, DOC_ID),
          D.DOCUMENT_NO = CONCAT(FID, DOC_ID)
      WHERE D.DOCUMENT_ID = DOC_ID;

    SELECT DOC_ID AS RES;

  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.USPR_ADD TO D,Z,S $$

-- тело учебной справки
DROP PROCEDURE IF EXISTS decanet.USPR_ITM $$
CREATE PROCEDURE decanet.USPR_ITM(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT U.DOCUMENT_ID, U.DOCUMENT_NO,
         DATE_FORMAT(U.DOCUMENT_OUTDATE, '%d.%m.%Y') AS DOCUMENT_INDATE,
         H.SCHOOL_DEPT, H.SCHOOL_ABBR, H.SCHOOL_NAME, C.CITY_NAME, H.SCHOOL_STREET, H.SCHOOL_BLDNO,
         F.FACULTET_ABBR, F.FACULTET_NAME, D.DIVISION_NAME,
         I.GOSDIR_CODE, I.GOSDIR_NAME,
         T.GOSTITLE_CODE, T.GOSTITLE_NAME,
         B.SUBSPEC_CODE, B.SUBSPEC_NAME,
         SGROUPKURS(G.SGROUP_ID, NOW()) AS KURS,
         S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         DATE_FORMAT(A.STUDENT_BIRTHDAY, '%d.%m.%Y') AS STUDENT_BIRTHDAY,
         FET.EDUTYPE_NAME AS FED_NAME, DET.EDUTYPE_NAME AS DET_NAME, E.EDUFORM_NAME,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS UPERIOD,
         X.DOCUMENT_NO AS PRIK_NO,
         DATE_FORMAT(X.DOCUMENT_INDATE, '%d.%m.%Y') AS PRIK_DATE
    FROM (SELECT D.DOCUMENT_NO, D.DOCUMENT_INDATE
            FROM decanet.studdoc O LEFT JOIN
                 decanet.contingent C USING (STUDSGRP_ID) LEFT JOIN
                 decanet.studstatus S USING (STUDSTATUS_ID) LEFT JOIN
                 decanet.document D ON D.DOCUMENT_ID = C.DOCUMENT_ID
            WHERE O.DOCUMENT_ID = DOC_ID AND
                  NOT D.DOCUMENT_TEMPFLAG AND
                  S.STATUSTYPE_ID IN (1,2,3,4,5)
            ORDER BY DOCUMENT_INDATE DESC
            LIMIT 1) X LEFT JOIN
         decanet.document U ON TRUE LEFT JOIN
         decanet.studdoc USING (DOCUMENT_ID) LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.studadd A USING (STUDENT_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID, DIVISION_ID) LEFT JOIN
         decanet.division D ON D.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.gosTITLE T USING (GOSTITLE_ID) LEFT JOIN
         decanet.gosDIR I USING (GOSDIR_ID) LEFT JOIN
         decanet.subspec B USING (SUBSPEC_ID) LEFT JOIN
         decanet.edutype DET ON D.EDUTYPE_ID = DET.EDUTYPE_ID LEFT JOIN
         decanet.facultet F ON D.FACULTET_ID = F.FACULTET_ID LEFT JOIN
         decanet.edutype FET ON F.EDUTYPE_ID = FET.EDUTYPE_ID LEFT JOIN
         decanet.school H USING (SCHOOL_ID) LEFT JOIN
         decanet.city C ON C.CITY_ID = H.CITY_ID
    WHERE U.DOCUMENT_ID = DOC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.USPR_ITM TO A,D,Z,S,V $$


-- ---------------------------------------------------------------------------------------------------
-- ДОКУМЕНТЫ
-- ---------------------------------------------------------------------------------------------------
-- список судентов привязанных к НЕакадемическому документу
-- документы студента LST
DROP PROCEDURE IF EXISTS decanet.STUDDOC_LST $$
CREATE PROCEDURE decanet.STUDDOC_LST (IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN

  SELECT H.SCHOOL_ID, H.SCHOOL_NAME,
         F.FACULTET_ID, F.FACULTET_NAME,
         V.DIVISION_ID, V.DIVISION_NAME,
         G.SGROUP_ID, SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SG.STUDSGRP_ID, S.STUDENT_ID,
         E.EDUFORM_ABBR, S.STUDENT_PERSNO, S.STUDENT_ZACHNO, S.STUDENT_STRAHNO,
         S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE
    FROM decanet.studdoc O LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (DIVISION_ID, STREAM_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school H USING (SCHOOL_ID)
    WHERE O.DOCUMENT_ID = DOC_ID;

END$$
GRANT EXECUTE ON PROCEDURE decanet.STUDDOC_LST TO A,D,Z,S,V $$


-- список студентов документа по л/с для формы приказа по л/с
-- ЭТО вместо DOCUMENT_BODY в форме приказа по л/с
-- для окраски берем STUDSTATUS_ACTIVE
-- как третий параметр STUDDOCCONT_DEL берем STUDSTATUS_ID
-- CONCAT(T.STUDSTATUS_NAME,  ' (', T.STUDSTATUS_VALUE, ')') - в заголовок
DROP PROCEDURE IF EXISTS decanet.STUDDOCCONT_LST $$
CREATE PROCEDURE decanet.STUDDOCCONT_LST (IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN

  SELECT H.SCHOOL_ID, H.SCHOOL_NAME,
         F.FACULTET_ID, F.FACULTET_NAME,
         V.DIVISION_ID, V.DIVISION_NAME,
         G.SGROUP_ID, SGROUPAUTONAME(G.SGROUP_ID) AS SGROUP_AUTONAME,
         FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS SGROUP_PERIOD,
         SG.STUDSGRP_ID, S.STUDENT_ID,
         E.EDUFORM_ABBR, S.STUDENT_PERSNO, S.STUDENT_ZACHNO, S.STUDENT_STRAHNO,
         S.STUDENT_FNAME, S.STUDENT_MNAME, S.STUDENT_LNAME,
         FSTUDENT_ACTIVE(SG.STUDSGRP_ID) AS STUDENT_ACTIVE,
         DATE_FORMAT(C.CONTINGENT_DATE, '%d.%m.%Y') AS CONTINGENT_DATE,
         T.STUDSTATUS_ID, T.STUDSTATUS_NAME, T.STUDSTATUS_ACTIVE, C.STUDSTATUS_VALUE,
         CONCAT(T.STUDSTATUS_NAME,  IFNULL(CONCAT(' (', C.STUDSTATUS_VALUE, ')'), '')) AS SUBTITLE, -- в заголовок
         T.STUDSTATUS_ACTIVE
    FROM decanet.studdoc O LEFT JOIN
         decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
         decanet.contingent C USING (STUDSGRP_ID, DOCUMENT_ID) LEFT JOIN
         decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
         decanet.student S USING (STUDENT_ID) LEFT JOIN
         decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         -- decanet.stream R USING (DIVISION_ID, STREAM_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         -- decanet.division V USING (DIVISION_ID) LEFT JOIN
         decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school H USING (SCHOOL_ID)
    WHERE O.DOCUMENT_ID = DOC_ID
    ORDER BY T.STUDSTATUS_ACTIVE DESC, T.STUDSTATUS_ID, C.STUDSTATUS_VALUE, V.DIVISION_ID,
             R.STREAM_FROMYEAR DESC, G.SGROUP_NAMEINDEX, S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;

END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDDOCCONT_LST TO A,D,Z,S,V $$


-- неакадемические документы студента LST
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.DOCSTUD_LST $$
CREATE PROCEDURE decanet.DOCSTUD_LST (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT S.DOCUMENT_ID, T.DOCTYPE_ABBR, T.DOCTYPE_NAME, D.DOCUMENT_NO,
         DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS,
         CAST(D.DOCUMENT_INDATE AS DATE) AS DOCUMENT_INDATE,
         DOCUMENT_DESC
    FROM decanet.studdoc S LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID)
    WHERE S.STUDSGRP_ID = SSG_ID
    ORDER BY D.DOCUMENT_INDATE DESC, D.DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCSTUD_LST TO A,D,Z,S,V $$

-- незавершенные экз. листы / протоколы ГЭК студента LST
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.ADOCSTUD_LST $$
CREATE PROCEDURE decanet.ADOCSTUD_LST (IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT D.DOCUMENT_ID, D.DOCTYPE_ID, T.DOCTYPE_ABBR, D.DOCUMENT_NO,
         DATE_FORMAT(D.DOCUMENT_OUTDATE, '%d.%m.%Y') AS DOCUMENT_OUTDATE,
         E.SEMESTR, P.VOLUME, J.SUBJ_NAME,
         C.CONTROL_ID, C.CONTROL_NAME
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.persprog P USING (STUDSGRP_ID) LEFT JOIN
         decanet.mainprog M USING(MAINPROG_ID) LEFT JOIN
         decanet.dsession E USING (DSESSION_ID) LEFT JOIN
         decanet.control C USING (CONTROL_ID) LEFT JOIN
         decanet.progdoc R USING (PERSPROG_ID) LEFT JOIN
         decanet.document D USING (DOCUMENT_ID) LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID) LEFT JOIN
         decanet.mprogsubj U USING (MPROGSUBJ_ID) LEFT JOIN
         decanet.subj J USING (SUBJ_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          D.DOCTYPE_ID IN (2, 6) AND
          D.DOCUMENT_TEMPFLAG
    ORDER BY D.DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.ADOCSTUD_LST TO A,D,Z,S,V $$


-- список типов документов CNT
DROP PROCEDURE IF EXISTS decanet.DOCTYPE_CNT $$
CREATE PROCEDURE decanet.DOCTYPE_CNT()
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DOCTYPE_ID) AS CNT
    FROM decanet.document;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCTYPE_CNT TO A,D,Z,S,V $$

-- список типов документов LST
DROP PROCEDURE IF EXISTS decanet.DOCTYPE_LST $$
CREATE PROCEDURE decanet.DOCTYPE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT DOCTYPE_ID, DOCTYPE_ABBR, DOCTYPE_NAME, DOCTYPE_DESC
    FROM decanet.doctype
    ORDER BY DOCTYPE_NAME;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCTYPE_LST TO A,D,Z,S,V $$


-- определение типа документа по номеру
DROP PROCEDURE IF EXISTS decanet.GETDOCTYPE $$
CREATE PROCEDURE decanet.GETDOCTYPE (IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN

/*
  1, 'Экзаменационная ведомость', 'Вед'
  2, 'Экзаменационный лист', 'Лист'
  3, 'Приказ по личному составу', 'Приказ по л/с'
  4, 'Приказ о назначении стипендии', 'Стипенд'
  5, 'Приказ на тему выпускной работы', 'Тема'
  6, 'Протокол ГЭК', 'ГЭК'
  7, 'Выпускная работа', 'Диплом'
  8, 'Ведомость должников', 'ДолгВед',
  9, 'Учебная справка по месту требования', 'УчСправ'
  10, 'Учебная справка в ПФ', 'УчСправПФ'
  11, 'Академическая справка', 'АкадСправ'
  12, 'Ведомость тем', 'ТемаВед'
*/

  SELECT DOCTYPE_ID
    FROM decanet.document
    WHERE DOCUMENT_ID = DOC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.GETDOCTYPE TO A,D,Z,S,V $$

-- название статуса DOCUMENT_TEMPFLAG в зависимости от типа док-та
DROP FUNCTION IF EXISTS decanet.DOCSTATE $$
CREATE FUNCTION decanet.DOCSTATE (DOC_ID INT) RETURNS VARCHAR(25)
BEGIN
  DECLARE DTYPE INT;
  DECLARE DTF BOOL;

  SELECT DOCTYPE_ID, DOCUMENT_TEMPFLAG INTO DTYPE, DTF
    FROM decanet.document
    WHERE DOCUMENT_ID = DOC_ID;

  RETURN (SELECT CASE WHEN DTYPE IN (1,2,6,8,12) THEN
                        IF(DTF, 'Не введен', 'Введен')
                      WHEN DTYPE IN (3,4,5) THEN
                       IF(DTF, 'Проект', 'Завершён')
                      ELSE
                       IF(DTF, 'Ошибка', 'Выдан') -- документы рождаются завершёнными
                 END);
END$$


-- список ОТКРЫТЫХ документов
DROP PROCEDURE IF EXISTS decanet.TEMPDOC_LST $$
CREATE PROCEDURE decanet.TEMPDOC_LST(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DOCUMENT_ID, DOCTYPE_NAME, DOCUMENT_NO,
         DOCSTATE(DOCUMENT_ID) AS DOCUMENT_STATUS,
         DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_INDATE,
         DOCUMENT_NAME, DOCUMENT_DESC
    FROM decanet.document LEFT JOIN
         decanet.doctype USING (DOCTYPE_ID)
    WHERE FACULTET_ID = FAC_ID AND
          DOCUMENT_TEMPFLAG
    ORDER BY DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.TEMPDOC_LST TO A,D,Z,S,V $$


-- список свежих ОТКРЫТЫХ приказов по л/составу CNT
DROP PROCEDURE IF EXISTS decanet.LSDOC_CNT $$
CREATE PROCEDURE decanet.LSDOC_CNT(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DOCUMENT_ID) AS CNT
    FROM decanet.document
    WHERE DOCTYPE_ID = 3 AND
          FACULTET_ID = FAC_ID AND
          DOCUMENT_TEMPFLAG AND
          DOCUMENT_OUTDATE > CURDATE() - INTERVAL 1 MONTH;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOC_CNT TO A,D,Z,S,V $$

-- список свежих ОТКРЫТЫХ приказов по л/составу LIST
DROP PROCEDURE IF EXISTS decanet.LSDOC_LST $$
CREATE PROCEDURE decanet.LSDOC_LST(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DOCUMENT_ID, DOCUMENT_NO,
         DOCSTATE(DOCUMENT_ID) AS DOCUMENT_STATUS,
         DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_INDATE, DOCUMENT_NAME
    FROM decanet.document
    WHERE DOCTYPE_ID = 3 AND
          FACULTET_ID = FAC_ID AND
          DOCUMENT_TEMPFLAG AND
          DOCUMENT_OUTDATE > CURDATE() - INTERVAL 1 MONTH
    ORDER BY DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOC_LST TO A,D,Z,S,V $$

-- список всех ОТКРЫТЫХ приказов по л/составу CNT
DROP PROCEDURE IF EXISTS decanet.LSDOCALL_CNT $$
CREATE PROCEDURE decanet.LSDOCALL_CNT(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT COUNT(DOCUMENT_ID) AS CNT
    FROM decanet.document
    WHERE FACULTET_ID = FAC_ID AND
          DOCTYPE_ID = 3 AND
          DOCUMENT_TEMPFLAG;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOCALL_CNT TO A,D,Z,S,V $$

-- список всех ОТКРЫТЫХ приказов по л/составу LIST
DROP PROCEDURE IF EXISTS decanet.LSDOCALL_LST $$
CREATE PROCEDURE decanet.LSDOCALL_LST(IN FAC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT DOCUMENT_ID, DOCUMENT_NO,
         DOCSTATE(DOCUMENT_ID) AS DOCUMENT_STATUS,
         DOCUMENT_TEMPFLAG, DOCUMENT_OUTDATE, DOCUMENT_INDATE, DOCUMENT_NAME
    FROM decanet.document
    WHERE FACULTET_ID = FAC_ID AND
          DOCTYPE_ID = 3 AND
          DOCUMENT_TEMPFLAG
    ORDER BY DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.LSDOCALL_LST TO A,D,Z,S,V $$

-- данные документа ITEM
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_ITM $$
CREATE PROCEDURE decanet.DOCUMENT_ITM(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
    SELECT C.CITY_NAME, S.SCHOOL_DEPT, S.SCHOOL_NAME, S.SCHOOL_ABBR, F.FACULTET_NAME,
           DOCUMENT_ID, D.DOCTYPE_ID, DOCTYPE_NAME, DOCUMENT_NO,
           DOCUMENT_TEMPFLAG,
           DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS,
           DOCUMENT_OUTDATE, DOCUMENT_INDATE,
           DOCUMENT_NAME, DOCUMENT_DESC
    FROM decanet.document D LEFT JOIN
         decanet.doctype T USING (DOCTYPE_ID) LEFT JOIN
         decanet.facultet F USING (FACULTET_ID) LEFT JOIN
         decanet.school S USING (SCHOOL_ID) LEFT JOIN
         decanet.city C USING (CITY_ID)
    WHERE DOCUMENT_ID = DOC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_ITM TO A,D,Z,S,V $$

-- удаление студента из ОТКРЫТОГО документа
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDDOCCONT_DEL $$
CREATE PROCEDURE decanet.STUDDOCCONT_DEL (IN SSG_ID INT, IN DOC_ID INT, IN STAT_ID INT)
COMMENT 'DZ'
BEGIN
  DELETE decanet.contingent
    FROM decanet.contingent LEFT JOIN
         decanet.document USING (DOCUMENT_ID)
     WHERE STUDSGRP_ID = SSG_ID AND
           DOCUMENT_ID = DOC_ID AND
           STUDSTATUS_ID = STAT_ID AND
           DOCUMENT_TEMPFLAG;

    DELETE decanet.studdoc
      FROM decanet.studdoc LEFT JOIN
           decanet.contingent USING (STUDSGRP_ID, DOCUMENT_ID)
      WHERE STUDSGRP_ID = SSG_ID AND
            DOCUMENT_ID = DOC_ID AND
            CONTINGENT_ID IS NULL;

    SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDDOCCONT_DEL TO D,Z $$

-- смена причины и даты с..  у студента из ОТКРЫТОГО документа
-- причину перемещения берем из STUDSTATUS_LST(NULL)
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.STUDDOCCONT_CNG $$
CREATE PROCEDURE decanet.STUDDOCCONT_CNG (IN SSG_ID INT, IN DOC_ID INT, IN NEWSTAT_ID INT, IN NEWCONTDATE DATE)
COMMENT 'DZ'
BEGIN
  UPDATE decanet.contingent C
    SET STUDSTATUS_ID = NEWSTAT_ID,
        CONTINGENT_DATE = NEWCONTDATE
    WHERE C.DOCUMENT_ID = DOC_ID AND
          C.STUDSGRP_ID = SSG_ID;

    SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.STUDDOCCONT_CNG TO D,Z $$


-- закрытие ОТКРЫТОГО документа CNG
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_CLOSE $$
CREATE PROCEDURE decanet.DOCUMENT_CLOSE (IN DOC_ID INT, IN DOCNO VARCHAR(25), IN INDT DATE)
COMMENT 'DZ'
BEGIN
  DECLARE TEMPDOC BOOL;

  SET TEMPDOC = (SELECT DOCUMENT_TEMPFLAG
                  FROM decanet.document
                  WHERE DOCUMENT_ID = DOC_ID);

  IF TEMPDOC THEN
    UPDATE decanet.document
      SET DOCUMENT_NO = DOCNO,
          DOCUMENT_INDATE = INDT,
          DOCUMENT_TEMPFLAG = FALSE
      WHERE DOCUMENT_ID = DOC_ID;

    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;

END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_CLOSE TO D,Z $$

-- правка данных документа CNG
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_CNG $$
CREATE PROCEDURE decanet.DOCUMENT_CNG(IN DOC_ID INT, IN DNAME VARCHAR(255), IN DDESC VARCHAR(255))
COMMENT 'DZ'
BEGIN
  UPDATE decanet.document
    SET DOCUMENT_NAME = DNAME,
        DOCUMENT_DESC = DDESC
    WHERE DOCUMENT_ID = DOC_ID;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_CNG TO D,Z $$

-- поиск документов CNT
DROP PROCEDURE IF EXISTS decanet.FND_DOCUMENT_CNT $$
CREATE PROCEDURE decanet.FND_DOCUMENT_CNT(IN FID INT,
                                      IN DTYPE INT,
                                      IN DNO VARCHAR (25),
                                      IN DTFLAG BOOL,
                                      IN DDATE DATE,
                                      IN DNAME VARCHAR (255),
                                      IN DDESC VARCHAR (255))
COMMENT 'ADZSV'
BEGIN
  IF NOT LOCATE('%', DNO) THEN
    SET DNO = CONCAT('%', DNO, '%');
  END IF;
  IF NOT LOCATE('%', DNAME) THEN
    SET DNAME = CONCAT('%', DNAME, '%');
  END IF;
  IF NOT LOCATE('%', DDESC) THEN
    SET DDESC = CONCAT('%', DDESC, '%');
  END IF;

  SELECT COUNT(DOCUMENT_ID) AS CNT
  FROM decanet.document D
  WHERE D.FACULTET_ID = FID AND
        IF(DTYPE IS NULL, TRUE, D.DOCTYPE_ID = DTYPE) AND
        IF(DNO IS NULL, TRUE, D.DOCUMENT_NO LIKE DNO) AND
        IF(DTFLAG IS NULL, TRUE, D.DOCUMENT_TEMPFLAG = DTFLAG) AND
        IF(DDATE IS NULL, TRUE, (D.DOCUMENT_INDATE >= DDATE OR D.DOCUMENT_OUTDATE >= DDATE)) AND
        IF(DNAME IS NULL, TRUE, D.DOCUMENT_NAME LIKE DNAME) AND
        IF(DDESC IS NULL, TRUE, D.DOCUMENT_DESC LIKE DDESC);
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_DOCUMENT_CNT TO A,D,Z,S,V $$

-- поиск документов LST
DROP PROCEDURE IF EXISTS decanet.FND_DOCUMENT_LST $$
CREATE PROCEDURE decanet.FND_DOCUMENT_LST(IN FID INT,             -- факультет (пока NOT NULL)
                                          IN DTYPE INT,           -- тип док-та по списку
                                          IN DNO VARCHAR (25),    -- номер док-та
                                          IN DTFLAG BOOL,         -- временный = 1; утвержденный = 0
                                          IN DDATE DATE,          -- дата формирования или утверждения
                                          IN DNAME VARCHAR (255), -- наименоваие
                                          IN DDESC VARCHAR (255)) -- примечание
COMMENT 'ADZSV'
BEGIN
  IF NOT LOCATE('%', DNO) THEN
    SET DNO = CONCAT('%', DNO, '%');
  END IF;
  IF NOT LOCATE('%', DNAME) THEN
    SET DNAME = CONCAT('%', DNAME, '%');
  END IF;
  IF NOT LOCATE('%', DDESC) THEN
    SET DDESC = CONCAT('%', DDESC, '%');
  END IF;

  SELECT DOCUMENT_ID, DOCTYPE_NAME, DOCUMENT_NO,
         DOCUMENT_TEMPFLAG,
         DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS,
         DOCUMENT_OUTDATE, DOCUMENT_INDATE,
         DOCUMENT_NAME, DOCUMENT_DESC
  FROM decanet.document D LEFT JOIN
       decanet.doctype T USING (DOCTYPE_ID)
  WHERE IF(FID IS NULL, TRUE, D.FACULTET_ID = FID) AND
        IF(DTYPE IS NULL, TRUE, D.DOCTYPE_ID = DTYPE) AND
        IF(DNO IS NULL, TRUE, D.DOCUMENT_NO LIKE DNO) AND
        IF(DTFLAG IS NULL, TRUE, D.DOCUMENT_TEMPFLAG = DTFLAG) AND
        IF(DDATE IS NULL, TRUE, (D.DOCUMENT_INDATE >= DDATE OR D.DOCUMENT_OUTDATE >= DDATE)) AND
        IF(DNAME IS NULL, TRUE, D.DOCUMENT_NAME LIKE DNAME) AND
        IF(DDESC IS NULL, TRUE, D.DOCUMENT_DESC LIKE DDESC)
  ORDER BY DOCUMENT_INDATE DESC, DOCUMENT_OUTDATE DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.FND_DOCUMENT_LST TO A,D,Z,S,V $$

-- данные для заголовка документа
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_TITLE $$
CREATE PROCEDURE decanet.DOCUMENT_TITLE(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT C.CITY_NAME, S.SCHOOL_DEPT, S.SCHOOL_NAME, S.SCHOOL_ABBR, F.FACULTET_NAME,
         DOCUMENT_ID, D.DOCTYPE_ID, DOCTYPE_NAME, DOCUMENT_NO,
         DOCUMENT_TEMPFLAG,
         DOCSTATE(D.DOCUMENT_ID) AS DOCUMENT_STATUS,
         DOCUMENT_OUTDATE, DOCUMENT_INDATE,
         DOCUMENT_NAME, DOCUMENT_DESC
  FROM decanet.document D LEFT JOIN
       decanet.doctype T USING (DOCTYPE_ID) LEFT JOIN
       decanet.facultet F USING (FACULTET_ID) LEFT JOIN
       decanet.school S USING (SCHOOL_ID) LEFT JOIN
       decanet.city C USING (CITY_ID)
  WHERE DOCUMENT_ID = DOC_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_TITLE TO A,D,Z,S,V $$

-- компилляция тела документа по л/с
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_BODY $$
CREATE PROCEDURE decanet.DOCUMENT_BODY(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE SSTID, SSTVAL INT;
  DECLARE SSTNAME VARCHAR(255);
  DECLARE done INT DEFAULT 0;
  DECLARE cRE CURSOR FOR SELECT DISTINCT C.STUDSTATUS_ID, T.STUDSTATUS_NAME, C.STUDSTATUS_VALUE
                           FROM decanet.document D LEFT JOIN
                                decanet.studdoc SD USING (DOCUMENT_ID) LEFT JOIN
                                decanet.contingent C USING (STUDSGRP_ID, DOCUMENT_ID) LEFT JOIN
                                decanet.studstatus T USING (STUDSTATUS_ID)
                           WHERE D.DOCUMENT_ID = DOC_ID
                           ORDER BY T.STUDSTATUS_NAME, C.STUDSTATUS_VALUE;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

  OPEN cRE;
  REPEAT
    FETCH cRE INTO SSTID, SSTNAME, SSTVAL;
    IF NOT done THEN
      SELECT CONCAT(SSTNAME, IFNULL(CONCAT(' (', SSTVAL, ')'), '')) AS _TITLE_;
      IF SSTID = 27 THEN
        SELECT CONCAT(S.STUDENT_LNAME, ' ', S.STUDENT_FNAME, ' ', S.STUDENT_MNAME, ' (', S.STUDENT_PERSNO, ', ', S.STUDENT_ZACHNO, ')') AS 'Фамилия Имя Отчество (Бух. №, № зач.)',
               CONCAT(V.DIVISION_NAME, ' ',
                      SGROUPAUTONAME(G.SGROUP_ID),
                      CONCAT(' (', FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT), ')')) AS 'Отделение Поток Группа',
               CONCAT(Y.CONTROL_NAME, ': "', Y.PERSNAME_NAME, '" с оценкой: ', Y.RESULT_NAME, ' (',
                      Y.DOCTYPE_NAME, ': ', Y.DOCUMENT_NO, ' от ',
                      DATE_FORMAT(Y.DOCUMENT_INDATE, '%d.%m.%Y)')) AS 'Результат',
               DATE_FORMAT(C.CONTINGENT_DATE, 'c %d.%m.%Y') AS 'Дата',
               S.STUDENT_ID, T.STUDSTATUS_ACTIVE -- эти два убрать
          FROM decanet.document D LEFT JOIN
               decanet.studdoc SD USING (DOCUMENT_ID) LEFT JOIN
               decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
               decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
               decanet.student S USING (STUDENT_ID) LEFT JOIN
               decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
               decanet.stream R USING (STREAM_ID) LEFT JOIN
               decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
               decanet.contingent C ON C.STUDSGRP_ID = SG.STUDSGRP_ID AND
                                       C.DOCUMENT_ID = D.DOCUMENT_ID LEFT JOIN
               decanet.studstatus T USING (STUDSTATUS_ID) LEFT JOIN
              (SELECT U.DIVISION_ID, P.STUDSGRP_ID, C.CONTROL_NAME, N.PERSNAME_NAME, R.RESULT_NAME, T.DOCTYPE_NAME, D.DOCUMENT_NO, D.DOCUMENT_INDATE
                 FROM decanet.mainprog M LEFT JOIN
                      decanet.dsession E USING (DSESSION_ID) LEFT JOIN
                      decanet.stream U USING (STREAM_ID) LEFT JOIN
                      decanet.control C USING (CONTROL_ID) LEFT JOIN
                      decanet.persprog P USING (MAINPROG_ID) LEFT JOIN
                      decanet.persname N USING (PERSPROG_ID) LEFT JOIN
                      decanet.acad A USING (PERSPROG_ID) LEFT JOIN
                      decanet.result R USING (RESULT_ID) LEFT JOIN
                      decanet.document D ON D.DOCUMENT_ID = A.DOCUMENT_ID LEFT JOIN
                      decanet.doctype T USING (DOCTYPE_ID)
                 WHERE C.CONTROL_ENDFLAG AND
                       A.RESULT_ID IS NOT NULL
                 GROUP BY STUDSGRP_ID HAVING D.DOCUMENT_INDATE = MAX(D.DOCUMENT_INDATE)) Y ON Y.DIVISION_ID = R.DIVISION_ID AND
                                                                                              Y.STUDSGRP_ID = SG.STUDSGRP_ID
          WHERE D.DOCUMENT_ID = DOC_ID AND
                C.STUDSTATUS_ID = SSTID
          ORDER BY V.DIVISION_ID, R.STREAM_FROMYEAR DESC, G.SGROUP_NAMEINDEX,
                   S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
      ELSE
        SELECT V.DIVISION_NAME AS 'Отделение',
               FSTREAMPERIOD(R.STREAM_FROMYEAR, R.STREAM_SEMCOUNT) AS 'Поток',
               SGROUPAUTONAME(G.SGROUP_ID) AS 'Группа',
               S.STUDENT_LNAME AS 'Фамилия',
               S.STUDENT_FNAME AS 'Имя',
               S.STUDENT_MNAME AS 'Отчество',
               S.STUDENT_PERSNO AS 'Бух. номер',
               S.STUDENT_ZACHNO AS 'Номер зач.',
               E.EDUFORM_ABBR AS 'Форма обучения',
               DATE_FORMAT(C.CONTINGENT_DATE, 'c %d.%m.%Y') AS 'Дата',
               S.STUDENT_ID, T.STUDSTATUS_ACTIVE
          FROM decanet.document D LEFT JOIN
               decanet.studdoc SD USING (DOCUMENT_ID) LEFT JOIN
               decanet.studsgrp SG USING (STUDSGRP_ID) LEFT JOIN
               decanet.eduform E USING (EDUFORM_ID) LEFT JOIN
               decanet.student S USING (STUDENT_ID) LEFT JOIN
               decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
               decanet.stream R USING (DIVISION_ID, STREAM_ID) LEFT JOIN
               decanet.division V ON V.DIVISION_ID = R.DIVISION_ID LEFT JOIN
               decanet.contingent C USING (STUDSGRP_ID, DOCUMENT_ID) LEFT JOIN
               decanet.studstatus T USING (STUDSTATUS_ID)
          WHERE D.DOCUMENT_ID = DOC_ID AND
                C.STUDSTATUS_ID = SSTID AND
                IF(SSTVAL IS NULL, TRUE, C.STUDSTATUS_VALUE = SSTVAL)
          ORDER BY V.DIVISION_ID, R.STREAM_FROMYEAR DESC, G.SGROUP_NAMEINDEX,
                   S.STUDENT_LNAME, S.STUDENT_FNAME, S.STUDENT_MNAME;
      END IF;
    END IF;
  UNTIL done END REPEAT;
  CLOSE cRE;

END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_BODY TO A,D,Z,S,V $$


-- данные для подписи документа
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_FOOTER $$
CREATE PROCEDURE decanet.DOCUMENT_FOOTER(IN DOC_ID INT)
COMMENT 'ADZSV'
BEGIN
  DECLARE DTID INT;
  DECLARE FID INT;

  SELECT DOCTYPE_ID, FACULTET_ID
    INTO DTID, FID
    FROM decanet.document
    WHERE DOCUMENT_ID = DOC_ID;


  SELECT CASE WHEN DTID IN (1, 2, 5, 6, 7, 8, 9, 11, 12) THEN
                 CONCAT(FPS.PERSTATUS_NAME, ' ', F.FACULTET_ABBR)
              WHEN DTID IN (3, 4, 10) THEN
                CONCAT(SPS.PERSTATUS_NAME, ' ', S.SCHOOL_ABBR)
         END AS BOSSTITUL,
         CASE WHEN DTID IN (1, 2, 5, 6, 7, 8, 9, 11, 12) THEN
                CONCAT(MID(FP.PERSON_FNAME, 1, 1), '.', MID(FP.PERSON_MNAME, 1, 1), '.', FP.PERSON_LNAME)
              WHEN DTID IN (3, 4, 10) THEN
                CONCAT(MID(SP.PERSON_FNAME, 1, 1), '.', MID(SP.PERSON_MNAME, 1, 1), '.', SP.PERSON_LNAME)
         END AS BOSSFIO
    FROM decanet.facultet F LEFT JOIN
         decanet.school S USING (SCHOOL_ID) LEFT JOIN
         PERSON SP ON SP.PERSON_ID = S.PERSON_ID LEFT JOIN
         PERSON FP ON FP.PERSON_ID = F.PERSON_ID LEFT JOIN
         PERSTATUS SPS ON SPS.PERSTATUS_ID = SP.PERSTATUS_ID LEFT JOIN
         PERSTATUS FPS ON FPS.PERSTATUS_ID = FP.PERSTATUS_ID
    WHERE F.FACULTET_ID = FID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_FOOTER TO A,D,Z,S,V $$

-- открытие РАНЕЕ ЗАКРЫТОГО док-та
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_OPEN $$
CREATE PROCEDURE decanet.DOCUMENT_OPEN(IN DOC_ID INT)
COMMENT 'DZ'
BEGIN
  UPDATE decanet.document
    SET DOCUMENT_TEMPFLAG = TRUE
    WHERE DOCUMENT_ID = DOC_ID;

  SELECT 1 AS RES;
END$$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_OPEN TO D,Z $$

-- удаление ОТКРЫТОГО документа
DROP PROCEDURE IF EXISTS decanet.DOCUMENT_DEL $$
CREATE PROCEDURE decanet.DOCUMENT_DEL(IN DOC_ID INT)
COMMENT 'DZ'
BEGIN
  IF (SELECT DOCUMENT_TEMPFLAG
        FROM decanet.document
        WHERE DOCUMENT_ID = DOC_ID) THEN
    SET FOREIGN_KEY_CHECKS = 0;
    -- multidelete syntax
    DELETE decanet.acad, decanet.progdoc, decanet.studdoc, decanet.contingent, decanet.document
      FROM decanet.document LEFT JOIN
           decanet.acad USING (DOCUMENT_ID) LEFT JOIN
           decanet.progdoc USING (DOCUMENT_ID) LEFT JOIN
           decanet.studdoc USING (DOCUMENT_ID) LEFT JOIN
           decanet.contingent USING (DOCUMENT_ID)
      WHERE DOCUMENT_ID = DOC_ID;
    SET FOREIGN_KEY_CHECKS = 1;
    SELECT 1 AS RES;
  ELSE
    SELECT 0 AS RES;
  END IF;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DOCUMENT_DEL TO D,Z $$

-- удаление просроченных НЕ ВВЕДЕННЫХ квитков и ведомостей
-- спросить дату выдачи документа c которой и ранее которой документы подлежат удалению
-- но все равно не позднее месяца
DROP PROCEDURE IF EXISTS decanet.ACADOC_DEL $$
CREATE PROCEDURE decanet.ACADOC_DEL(IN FAC_ID INT, IN OLDDATE DATE)
COMMENT 'DZ'
BEGIN
    -- multidelete syntax
    SET FOREIGN_KEY_CHECKS = 0;
    DELETE decanet.acad, decanet.progdoc, decanet.document
      FROM decanet.document LEFT JOIN
           decanet.acad USING (DOCUMENT_ID) LEFT JOIN
           decanet.progdoc USING (DOCUMENT_ID)
      WHERE DOCUMENT_TEMPFLAG AND
            DOCUMENT_OUTDATE <= OLDDATE AND
            DOCUMENT_OUTDATE < CurDate() - INTERVAL 2 MONTH AND  -- защита
            -- DOCTYPE_ID = 2; -- только квитки  IN (1,2); -- ведомость и квиток
            DOCTYPE_ID IN (1,2,8,12);
    SET FOREIGN_KEY_CHECKS = 1;

    SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.ACADOC_DEL TO D,Z $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ПРОДЛЕНИЯ СЕССИИ
-- ---------------------------------------------------------------------------------------------------

-- определение сессии
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.DSESS_ITM $$
CREATE PROCEDURE decanet.DSESS_ITM (IN SSG_ID INT, IN SEM INT)
COMMENT 'ADZSV'
BEGIN
  SELECT E.DSESSION_ID
    FROM decanet.studsgrp SG LEFT JOIN
         decanet.sgroup G USING (SGROUP_ID) LEFT JOIN
         decanet.stream R USING (STREAM_ID) LEFT JOIN
         decanet.dsession E USING (STREAM_ID) LEFT JOIN
         decanet.prolong P USING (DSESSION_ID) LEFT JOIN
         decanet.proltype T USING (PROLTYPE_ID)
    WHERE SG.STUDSGRP_ID = SSG_ID AND
          E.SEMESTR = SEM;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DSESS_ITM TO A,D,Z,S,V $$

-- список типов продлений
DROP PROCEDURE IF EXISTS decanet.PROLTYPE_LST $$
CREATE PROCEDURE decanet.PROLTYPE_LST()
COMMENT 'ADZSV'
BEGIN
  SELECT T.PROLTYPE_ID, T.PROLTYPE_ABBR, T.PROLTYPE_NAME
    FROM decanet.proltype T;
END $$
GRANT EXECUTE ON PROCEDURE decanet.PROLTYPE_LST TO A,D,Z,S,V $$

-- строка продления
-- ##SSG
DROP PROCEDURE IF EXISTS decanet.PROLONG_ITM $$
CREATE PROCEDURE decanet.PROLONG_ITM(IN DSESS_ID INT, IN SSG_ID INT)
COMMENT 'ADZSV'
BEGIN
  SELECT P.DSESSION_ID, P.STUDSGRP_ID,
         T.PROLTYPE_ID, T.PROLTYPE_ABBR, T.PROLTYPE_NAME,
         P.PROLONG_TODATE
    FROM decanet.prolong P LEFT JOIN
         decanet.proltype T USING (PROLTYPE_ID)
    WHERE P.DSESSION_ID = DSESS_ID AND
          P.STUDSGRP_ID = SSG_ID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.PROLONG_ITM TO A,D,Z,S,V $$

-- правка продления
-- #SSG
DROP PROCEDURE IF EXISTS decanet.PROLONG_CNG $$
CREATE PROCEDURE decanet.PROLONG_CNG(IN DSESS_ID INT, IN SSG_ID INT, IN PTYPE INT, IN TDT DATE)
COMMENT 'DZS'
BEGIN
  IF TDT IS NULL THEN
    DELETE FROM decanet.prolong
      WHERE DSESSION_ID = DSESS_ID AND
            STUDSGRP_ID = SSG_ID;
  ELSE
    REPLACE INTO decanet.prolong (PROLONG_ID, DSESSION_ID, STUDSGRP_ID, PROLTYPE_ID, PROLONG_TODATE)
      VALUES (NULL, DSESS_ID, SSG_ID, PTYPE, TDT);
  END IF;
  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.PROLONG_CNG TO D,Z,S $$


-- НСД
-- системная - синхронизирует юзеров из БД с юзерами сервера
DROP PROCEDURE IF EXISTS decanet.NSD_SYNC $$
CREATE PROCEDURE decanet.NSD_SYNC()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE UID, MTID INT;
  DECLARE DN, DP, BN, BP VARCHAR(255);
  DECLARE MTROLE VARCHAR(25);
  DECLARE cRE CURSOR FOR
    SELECT U.DUSER_ID, U.MANAGERTYPE_ID, MT.MANAGERTYPE_ABBR, U.DUNAME, U.DUPASS, U.BUNAME, U.BUPASS
      FROM decanet.duser U LEFT JOIN
           decanet.managertype MT USING (MANAGERTYPE_ID);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION SELECT 0 AS RES;

  OPEN cRE;
  REPEAT
    FETCH cRE INTO UID, MTID, MTROLE, DN, DP, BN, BP;
    IF NOT done THEN
      SET BN = DECODE(UNHEX(BN), 'GoNdUrAs');
      SET BP = DECODE(UNHEX(BP), 'PaRaGuWaY');

      -- CREATE OR REPLACE user
      SET @dcsql = CONCAT('CREATE OR REPLACE USER ', '\'', BN, '\'@\'localhost\'', ' IDENTIFIED BY ', '\'', BP, '\'');
      -- SELECT @dcsql;
      PREPARE dcstmt FROM @dcsql;
      EXECUTE dcstmt;

      -- REVOKE ALL PRIVILEGES, GRANT OPTION FROM user
      -- SET @dcsql = CONCAT('REVOKE ALL PRIVILEGES, GRANT OPTION FROM ', '\'', BN, '\'@\'localhost\'');
      -- PREPARE dcstmt FROM @dcsql;
      -- EXECUTE dcstmt;

      -- obsolete
      -- CALL decanet.SETDUSERACCESS(UID, MTID);

      CALL NSD_SET_DUSER_ROLE(BN, MTROLE);

    END IF;
  UNTIL done END REPEAT;
  CLOSE cRE;
  DEALLOCATE PREPARE dcstmt;
  SELECT 1 AS RES;
END $$

-- ---------------------------------------------------------------------------------------------------
-- РАЗДЕЛ . ЛОГ.
-- ---------------------------------------------------------------------------------------------------

-- глоб-список лога
DROP PROCEDURE IF EXISTS decanet.DCLOG_LST $$
CREATE PROCEDURE decanet.DCLOG_LST(IN DBUS VARCHAR(50),  -- mysql user name
                                   IN DUSR VARCHAR(50),  -- duser name
                                   IN DLNM VARCHAR(50),  -- фамилия
                                   IN EXPR VARCHAR(100), -- строка вызова
                                   IN SRES VARCHAR(50),  -- строка результата
                                   IN IRET INT,          -- возврат СП
                                   IN MNTP INT,          -- тип пользователя (MANTYPE_LST)
                                   IN FD DATETIME,       -- дата-время от
                                   IN TD DATETIME)       -- дата-время до
COMMENT 'A'
BEGIN

  IF NOT LOCATE('%', DBUS) AND DBUS IS NOT NULL THEN
    SET DBUS = CONCAT('%', DBUS, '%');
  END IF;
  IF NOT LOCATE('%', DUSR) AND DUSR IS NOT NULL THEN
    SET DUSR = CONCAT('%', DUSR, '%');
  END IF;
  IF NOT LOCATE('%', DLNM) AND DLNM IS NOT NULL THEN
    SET DLNM = CONCAT('%', DLNM, '%');
  END IF;
  IF NOT LOCATE('%', EXPR) AND EXPR IS NOT NULL THEN
    SET EXPR = CONCAT('%', EXPR, '%');
  END IF;
  IF NOT LOCATE('%', SRES) AND SRES IS NOT NULL THEN
    SET SRES = CONCAT('%', SRES, '%');
  END IF;


  SELECT L.DCLOG_ID,
         L.DBUSER, L.DUSER_ID, U.DUNAME, U.DUSER_FNAME, U.DUSER_MNAME, U.DUSER_LNAME,
         U.MANAGERTYPE_ID, T.MANAGERTYPE_NAME,
         L.DCLOG_DT, L.DCLOG_EXPRESSION, L.DCLOG_IRESULT, L.DCLOG_SRESULT, L.DCLOG_IRET
    FROM sitlog.dclog L LEFT JOIN
         decanet.duser U USING (DUSER_ID) LEFT JOIN
         decanet.managertype T USING (MANAGERTYPE_ID)
    WHERE IF(DBUS IS NOT NULL, L.DBUSER LIKE DBUS, TRUE) AND
          IF(DUSR IS NOT NULL, U.DUNAME LIKE DUSR, TRUE) AND
          IF(DLNM IS NOT NULL, U.DUSER_LNAME LIKE DLNM, TRUE) AND
          IF(EXPR IS NOT NULL, L.DCLOG_EXPRESSION LIKE EXPR, TRUE) AND
          IF(SRES IS NOT NULL, L.DCLOG_SRESULT LIKE SRES, TRUE) AND
          IF(IRET IS NOT NULL, L.DCLOG_IRET = IRET, TRUE) AND
          IF(MNTP IS NOT NULL, U.MANAGERTYPE_ID = MNTP, TRUE) AND
          IF(FD IS NOT NULL, L.DCLOG_DT >= FD, TRUE) AND
          IF(TD IS NOT NULL, L.DCLOG_DT <= TD, TRUE)
    ORDER BY L.DCLOG_DT DESC;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DCLOG_LST TO A $$

DROP PROCEDURE IF EXISTS DCLOG_ITM $$
CREATE PROCEDURE DCLOG_ITM(IN DCLID INT)
COMMENT 'A'
BEGIN
  SELECT L.DCLOG_ID,
         L.DUSER_ID, U.DUNAME, U.DUSER_FNAME, U.DUSER_MNAME, U.DUSER_LNAME,
         U.MANAGERTYPE_ID, T.MANAGERTYPE_NAME,
         L.DCLOG_DT, L.DCLOG_EXPRESSION, L.DCLOG_IRESULT, L.DCLOG_SRESULT, L.DCLOG_IRET
    FROM sitlog.dclog L LEFT JOIN
         decanet.duser U USING (DUSER_ID) LEFT JOIN
         decanet.managertype T USING (MANAGERTYPE_ID)
    WHERE L.DCLOG_ID = DCLID;
END $$
GRANT EXECUTE ON PROCEDURE decanet.DCLOG_ITM TO A $$

DROP PROCEDURE IF EXISTS decanet.SYSLOG_ADD $$
CREATE PROCEDURE decanet.SYSLOG_ADD(IN DUID INT,
                                    IN EXPR TEXT,
                                    IN IRES INT,
                                    IN SRES TINYTEXT,
                                    IN IRET INT)
COMMENT 'ADZSV'
BEGIN
  IF NOT ((EXPR LIKE '%_CNT(%') OR
          (EXPR LIKE '%_ITM(%') OR
          (EXPR LIKE '%_LST(%')  OR
          (EXPR LIKE '%_INIT(%') OR
          (EXPR LIKE '%_DONE(%') OR
          (EXPR LIKE '%_TITLE(%') OR
          (EXPR LIKE '%_BODY(%') OR
          (EXPR LIKE '%_FOOTER(%') OR
          (EXPR LIKE '%LOGINEXISTS(%') OR
          (EXPR LIKE '%BASKET_ADD(%') OR
          (EXPR LIKE '%VSAI_ADD(%') OR
          (EXPR LIKE '%SFLST_ADD(%')) THEN

    INSERT INTO sitlog.dclog(DCLOG_ID, DBUSER, DUSER_ID, DCLOG_DT, DCLOG_EXPRESSION, DCLOG_IRESULT, DCLOG_SRESULT, DCLOG_IRET)
      VALUES (NULL, SUBSTRING_INDEX(USER(),'@',1), DUID, Now(), EXPR, IRES, SRES, IRET);
  END IF;

  SELECT 1 AS RES;
END $$
GRANT EXECUTE ON PROCEDURE decanet.SYSLOG_ADD TO A,D,Z,S,V $$

DELIMITER ;

-- ---------------------------------------------------------------------------------------------------
-- ОБНОВЛЕНИЯ ПРАВ ПОЛЬЗОВАТЕЛЕЙ
-- ---------------------------------------------------------------------------------------------------
-- DELETE FROM MYSQL.DB WHERE USER = 'guest';
-- DELETE FROM MYSQL.USER WHERE USER = 'guest';
-- FLUSH PRIVILEGES;

-- создаем пользователя guest
/*
INSERT INTO MYSQL.USER
  VALUES('localhost', 'guest', PASSWORD('guest'),
           'N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N','N',
           'N','N','N','N','N','N','N','N', '', '', '', '', 0, 0, 0, 0);
*/

CREATE OR REPLACE USER 'guest'@'localhost' IDENTIFIED BY 'guest';

-- FLUSH PRIVILEGES;

GRANT EXECUTE ON PROCEDURE decanet.GETRUINFO TO 'guest'@'localhost';

-- FLUSH PRIVILEGES;

-- TRUNCATE decanet.duser;
-- CALL decanet.CREATEUSER(1,'demo','demo','demo_db','demo_pass','', '','Anonimous', 1, 7, 59, 18, 1, NULL, NULL, NULL, NULL);
--  CALL decanet.CREATEUSER(1,'sax','111222','salnikov','pass','Александр', 'Алксандрович','Сальников', 1, 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

CALL decanet.NSD_SYNC();

-- FLUSH PRIVILEGES;

/*
TRUNCATE decanet.duser;

CALL decanet.CREATEUSER(1,'supervisor','extrapass','supervisor_db','extrapass_db','', '','Supervisor', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- demo
CALL decanet.CREATEUSER(1,'demo','demo','demo_db','demo_pass','', '','Anonimous', 1, 7, 59, 18, 1, NULL, NULL, NULL, NULL);

-- SIT
CALL decanet.CREATEUSER(1,'kiv','111','mezon','test','Иван', 'Владимирович','Космынин', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(1,'sax','111222','salnikov','pass','Александр', 'Алксандрович','Сальников', 1, 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
CALL decanet.CREATEUSER(5,'wad','333','wad_db','wad_pass','Вадим', 'Васильевич','Секереш', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(1,'wwr','444','wwr_db','wwr_pass','Владимир', 'Владиславович','Рябков', 1, 7, 59, 18, 1, NULL, NULL, NULL, NULL);
-- ЛХФ
CALL decanet.CREATEUSER(4,'admin','!@#qweasd','admin_db','!@#qweasd','Администратор', 'Администраторович','Администраторов', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(4,'frol','55frol','frol_db','frol_pass','Татьяна', 'Ивановна','Фролова', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(5,'shom','719767','shom_db','shom_pass','Елена', 'Валерьевна','Шомина', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(1,'anna','3347085','anna_db','anna_pass','Анна', 'Владимировна','Лантинова', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(5,'nata','010186','nata_db','nata_pass','Наталья', 'Сергеевна','Хромцова', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(4,'zotus','1905','zotus_db','zotus_pass','Елена', 'Анатольевна','Зотеева', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
CALL decanet.CREATEUSER(6,'view','view','view_db','view_pass','', '','Только просмотр ЛХФ', 1, 7, 59, 18, 1, 1, NULL, NULL, NULL);
-- ГФ
CALL decanet.CREATEUSER(4,'anosovatg','123654','anosovatg_db','123654_pass','Татьяна', 'Геннадьевна', 'Аносова', 1, 7, 59, 18, 1, NULL, NULL, NULL, NULL);


FLUSH PRIVILEGES;
*/

/*
-- дубли дат правленных оценок
SELECT Y.PERSPROG_ID, Y.DOCUMENT_INDATE, S.STUDENT_PERSNO
  FROM (SELECT A.PERSPROG_ID, D.DOCUMENT_INDATE
          FROM (SELECT A1.PERSPROG_ID, COUNT(A1.ACAD_ID) AS CNT, SUM(D1.DOCUMENT_INDATE) AS SUMD
                  FROM ACAD A1 LEFT JOIN
                       DOCUMENT D1 USING (DOCUMENT_ID)
                  GROUP BY A1.PERSPROG_ID HAVING COUNT(ACAD_ID) > 1) X LEFT JOIN
               ACAD A USING (PERSPROG_ID) LEFT JOIN
              DOCUMENT D USING (DOCUMENT_ID)) Y LEFT JOIN
       PERSPROG P USING (PERSPROG_ID) LEFT JOIN
       STUDENT S USING (STUDENT_ID)
  GROUP BY Y.PERSPROG_ID, Y.DOCUMENT_INDATE HAVING COUNT(Y.DOCUMENT_INDATE) > 1;
*/