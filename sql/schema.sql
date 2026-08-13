-- MariaDB dump 10.19  Distrib 10.5.22-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: decanet
-- ------------------------------------------------------
-- Server version	10.5.22-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


CREATE DATABASE `decanet` /*!40100 DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_uca1400_ai_ci */;

--
-- Table structure for table `abit`
--

DROP TABLE IF EXISTS `abit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `abit` (
  `ABIT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ABIT_ABBR` varchar(30) NOT NULL,
  `ABIT_NAME` varchar(255) DEFAULT NULL,
  `ABIT_RATE` int(11) NOT NULL,
  PRIMARY KEY (`ABIT_ID`),
  UNIQUE KEY `UIDX_ABIT` (`ABIT_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `abit`
--


--
-- Table structure for table `acad`
--

DROP TABLE IF EXISTS `acad`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acad` (
  `ACAD_ID` int(11) NOT NULL AUTO_INCREMENT,
  `PERSPROG_ID` int(11) NOT NULL,
  `RESULT_ID` int(11) NOT NULL,
  `DOCUMENT_ID` int(11) NOT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`ACAD_ID`),
  UNIQUE KEY `UIDX_ACAD` (`PERSPROG_ID`,`RESULT_ID`,`DOCUMENT_ID`),
  KEY `FK_ACAD_RESULT` (`RESULT_ID`),
  KEY `FK_ACAD_DOCUMENT` (`DOCUMENT_ID`),
  CONSTRAINT `FK_ACAD_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_ACAD_PERSPROG` FOREIGN KEY (`PERSPROG_ID`) REFERENCES `persprog` (`PERSPROG_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_ACAD_RESULT` FOREIGN KEY (`RESULT_ID`) REFERENCES `result` (`RESULT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=636546 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `acad`
--


--
-- Table structure for table `city`
--

DROP TABLE IF EXISTS `city`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `city` (
  `CITY_ID` int(11) NOT NULL AUTO_INCREMENT,
  `REGION_ID` int(11) NOT NULL,
  `CITY_NAME` varchar(100) NOT NULL,
  PRIMARY KEY (`CITY_ID`),
  UNIQUE KEY `UIDX_CITY` (`REGION_ID`,`CITY_NAME`),
  CONSTRAINT `FK_CITY_REGION` FOREIGN KEY (`REGION_ID`) REFERENCES `region` (`REGION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `city`
--


--
-- Table structure for table `contingent`
--

DROP TABLE IF EXISTS `contingent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contingent` (
  `CONTINGENT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STUDSGRP_ID` int(11) NOT NULL,
  `STUDSTATUS_ID` int(11) NOT NULL,
  `STUDSTATUS_VALUE` int(11) DEFAULT NULL,
  `CONTINGENT_DATE` date NOT NULL,
  `CONTINGENT_TODATE` date DEFAULT NULL,
  `DOCUMENT_ID` int(11) DEFAULT NULL,
  `CONTINGENT_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`CONTINGENT_ID`),
  UNIQUE KEY `UIDX_CONTINGENT` (`STUDSGRP_ID`,`STUDSTATUS_ID`,`DOCUMENT_ID`),
  KEY `FK_CONTINGENT_NEWSTUDSTATUS` (`STUDSTATUS_ID`),
  KEY `FK_CONTINGENT_DOCUMENT` (`DOCUMENT_ID`),
  KEY `IDX_CONTINGENT_D` (`DOCUMENT_ID`),
  CONSTRAINT `FK_CONTINGENT_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_CONTINGENT_NEWSTUDSTATUS` FOREIGN KEY (`STUDSTATUS_ID`) REFERENCES `studstatus` (`STUDSTATUS_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_CONTINGENT_STUDSGRP` FOREIGN KEY (`STUDSGRP_ID`) REFERENCES `studsgrp` (`STUDSGRP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=17416 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contingent`
--


--
-- Table structure for table `control`
--

DROP TABLE IF EXISTS `control`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `control` (
  `CONTROL_ID` int(11) NOT NULL AUTO_INCREMENT,
  `CTRLGRP_ID` int(11) NOT NULL,
  `CONTROL_ENDFLAG` tinyint(1) DEFAULT NULL,
  `CONTROL_ABBR` varchar(25) NOT NULL,
  `CONTROL_NAME` varchar(255) DEFAULT NULL,
  `CONTROL_NAMED` tinyint(1) NOT NULL DEFAULT 0,
  `CONTROL_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`CONTROL_ID`),
  UNIQUE KEY `UIDX_CONTROL` (`CONTROL_ABBR`),
  KEY `FK_CONTROL_CTRLGRP` (`CTRLGRP_ID`),
  CONSTRAINT `FK_CONTROL_CTRLGRP` FOREIGN KEY (`CTRLGRP_ID`) REFERENCES `ctrlgrp` (`CTRLGRP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `control`
--


--
-- Table structure for table `country`
--

DROP TABLE IF EXISTS `country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `country` (
  `COUNTRY_ID` int(11) NOT NULL AUTO_INCREMENT,
  `COUNTRY_ABBR` varchar(3) NOT NULL,
  `COUNTRY_SNAME` varchar(50) NOT NULL,
  `COUNTRY_BNAME` varchar(100) NOT NULL,
  PRIMARY KEY (`COUNTRY_ID`),
  UNIQUE KEY `UIDX_COUNTRY` (`COUNTRY_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `country`
--


--
-- Table structure for table `ctrlgrp`
--

DROP TABLE IF EXISTS `ctrlgrp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ctrlgrp` (
  `CTRLGRP_ID` int(11) NOT NULL AUTO_INCREMENT,
  `CTRLGRP_ABBR` varchar(25) NOT NULL,
  `CTRLGRP_NAME` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`CTRLGRP_ID`),
  UNIQUE KEY `UIDX_CTRLGRP` (`CTRLGRP_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ctrlgrp`
--


--
-- Table structure for table `design`
--

DROP TABLE IF EXISTS `design`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `design` (
  `DESIGN_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DESIGN_NAME` varchar(100) NOT NULL,
  `DESIGN_PATH` varchar(255) NOT NULL,
  `DESIGN_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`DESIGN_ID`),
  UNIQUE KEY `UIDX_DESIGN` (`DESIGN_NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `design`
--


--
-- Table structure for table `division`
--

DROP TABLE IF EXISTS `division`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `division` (
  `DIVISION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FACULTET_ID` int(11) NOT NULL,
  `GOSTITLE_ID` int(11) NOT NULL,
  `EDUTYPE_ID` int(11) NOT NULL,
  `SUBSPEC_ID` int(11) DEFAULT NULL,
  `DIVISION_ABBR` varchar(25) NOT NULL,
  `DIVISION_NAME` varchar(255) DEFAULT NULL,
  `DIVISION_UYEAR` int(11) NOT NULL,
  `DIVISION_HALFUYEAR` int(11) NOT NULL,
  `DIVISION_NPREFIX` varchar(25) DEFAULT NULL,
  `DIVISION_ALGNO` int(11) NOT NULL DEFAULT 0,
  `DIVISION_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`DIVISION_ID`),
  UNIQUE KEY `UIDX_DIVISION` (`FACULTET_ID`,`DIVISION_ABBR`),
  KEY `FK_DIVISION_EDUTYPE` (`EDUTYPE_ID`),
  KEY `FK_DIVISION_SUBSPEC` (`SUBSPEC_ID`),
  KEY `FK_DIVISION_GOSTITLE` (`GOSTITLE_ID`),
  CONSTRAINT `FK_DIVISION_EDUTYPE` FOREIGN KEY (`EDUTYPE_ID`) REFERENCES `edutype` (`EDUTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DIVISION_FACULTET` FOREIGN KEY (`FACULTET_ID`) REFERENCES `facultet` (`FACULTET_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DIVISION_GOSTITLE` FOREIGN KEY (`GOSTITLE_ID`) REFERENCES `gostitle` (`GOSTITLE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DIVISION_SUBSPEC` FOREIGN KEY (`SUBSPEC_ID`) REFERENCES `subspec` (`SUBSPEC_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `division`
--


--
-- Table structure for table `doctype`
--

DROP TABLE IF EXISTS `doctype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `doctype` (
  `DOCTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DOCTYPE_ABBR` varchar(25) NOT NULL,
  `DOCTYPE_NAME` varchar(255) DEFAULT NULL,
  `DOCTYPE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`DOCTYPE_ID`),
  UNIQUE KEY `UIDX_DOCTYPE` (`DOCTYPE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `doctype`
--


--
-- Table structure for table `document`
--

DROP TABLE IF EXISTS `document`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `document` (
  `DOCUMENT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DOCTYPE_ID` int(11) NOT NULL,
  `FACULTET_ID` int(11) NOT NULL,
  `DOCUMENT_BARNO` bigint(20) DEFAULT NULL,
  `DOCUMENT_NO` varchar(25) DEFAULT NULL,
  `DOCUMENT_TEMPFLAG` tinyint(1) DEFAULT 1,
  `DOCUMENT_OUTDATE` datetime NOT NULL,
  `DOCUMENT_INDATE` datetime DEFAULT NULL,
  `DOCUMENT_EXPIRE` date DEFAULT NULL,
  `DOCUMENT_PERIOD` int(11) NOT NULL DEFAULT 0,
  `DOCUMENT_NAME` varchar(255) DEFAULT NULL,
  `DOCUMENT_PATH` varchar(255) DEFAULT NULL,
  `DOCUMENT_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`DOCUMENT_ID`),
  UNIQUE KEY `UIDX_DOCUMENT` (`DOCTYPE_ID`,`FACULTET_ID`,`DOCUMENT_NO`,`DOCUMENT_PERIOD`),
  KEY `FK_DOCUMENT_DOCTYPE` (`DOCTYPE_ID`),
  KEY `FK_DOCUMENT_FACULTET` (`FACULTET_ID`),
  CONSTRAINT `FK_DOCUMENT_DOCTYPE` FOREIGN KEY (`DOCTYPE_ID`) REFERENCES `doctype` (`DOCTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DOCUMENT_FACULTET` FOREIGN KEY (`FACULTET_ID`) REFERENCES `facultet` (`FACULTET_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=141950 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document`
--

/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`greenworks`@`%`*/ /*!50003 TRIGGER `ins_document` BEFORE INSERT ON `document` FOR EACH ROW SET NEW.DOCUMENT_PERIOD := CAST(YEAR(NOW()) AS SIGNED) */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dsession`
--

DROP TABLE IF EXISTS `dsession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dsession` (
  `DSESSION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STREAM_ID` int(11) NOT NULL,
  `SEMESTR` int(11) NOT NULL,
  `DSESSION_BEGDATE` date DEFAULT NULL,
  `DSESSION_ENDDATE` date DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`DSESSION_ID`),
  UNIQUE KEY `UIDX_DSESSION` (`STREAM_ID`,`SEMESTR`),
  CONSTRAINT `FK_DSESSION_STREAM` FOREIGN KEY (`STREAM_ID`) REFERENCES `stream` (`STREAM_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=1612 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dsession`
--


--
-- Table structure for table `duser`
--

DROP TABLE IF EXISTS `duser`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `duser` (
  `DUSER_ID` int(11) NOT NULL AUTO_INCREMENT,
  `MANAGERTYPE_ID` int(11) NOT NULL,
  `DUSER_FNAME` varchar(50) DEFAULT NULL,
  `DUSER_MNAME` varchar(50) DEFAULT NULL,
  `DUSER_LNAME` varchar(50) NOT NULL,
  `DUSER_PHONE1` varchar(15) DEFAULT NULL,
  `DUSER_PHONE2` varchar(15) DEFAULT NULL,
  `DUSER_EMAIL` varchar(100) DEFAULT NULL,
  `DUSER_ICQ` varchar(15) DEFAULT NULL,
  `DUNAME` varchar(255) NOT NULL,
  `DUPASS` varchar(255) NOT NULL,
  `BUNAME` varchar(255) NOT NULL,
  `BUPASS` varchar(255) NOT NULL,
  `DUSER_2FA` varchar(255) DEFAULT NULL,
  `DESIGN_ID` int(11) DEFAULT NULL,
  `COUNTRY_ID` int(11) DEFAULT NULL,
  `REGION_ID` int(11) DEFAULT NULL,
  `CITY_ID` int(11) DEFAULT NULL,
  `SCHOOL_ID` int(11) DEFAULT NULL,
  `FACULTET_ID` int(11) DEFAULT NULL,
  `DIVISION_ID` int(11) DEFAULT NULL,
  `SGROUP_ID` int(11) DEFAULT NULL,
  `STUDENT_ID` int(11) DEFAULT NULL,
  `DUSER_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`DUSER_ID`),
  UNIQUE KEY `UIDX_DUSER` (`DUNAME`),
  KEY `FK_DUSER_MANAGERTYPE` (`MANAGERTYPE_ID`),
  KEY `FK_DUSER_DESIGN` (`DESIGN_ID`),
  KEY `FK_DUSER_COUNTRY` (`COUNTRY_ID`),
  KEY `FK_DUSER_REGION` (`REGION_ID`),
  KEY `FK_DUSER_CITY` (`CITY_ID`),
  KEY `FK_DUSER_SCHOOL` (`SCHOOL_ID`),
  KEY `FK_DUSER_FACULTET` (`FACULTET_ID`),
  KEY `FK_DUSER_DIVISION` (`DIVISION_ID`),
  KEY `FK_DUSER_SGROUP` (`SGROUP_ID`),
  KEY `FK_DUSER_STUDENT` (`STUDENT_ID`),
  CONSTRAINT `FK_DUSER_CITY` FOREIGN KEY (`CITY_ID`) REFERENCES `city` (`CITY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_COUNTRY` FOREIGN KEY (`COUNTRY_ID`) REFERENCES `country` (`COUNTRY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_DESIGN` FOREIGN KEY (`DESIGN_ID`) REFERENCES `design` (`DESIGN_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_DIVISION` FOREIGN KEY (`DIVISION_ID`) REFERENCES `division` (`DIVISION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_FACULTET` FOREIGN KEY (`FACULTET_ID`) REFERENCES `facultet` (`FACULTET_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_MANAGERTYPE` FOREIGN KEY (`MANAGERTYPE_ID`) REFERENCES `managertype` (`MANAGERTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_REGION` FOREIGN KEY (`REGION_ID`) REFERENCES `region` (`REGION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_SCHOOL` FOREIGN KEY (`SCHOOL_ID`) REFERENCES `school` (`SCHOOL_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_SGROUP` FOREIGN KEY (`SGROUP_ID`) REFERENCES `sgroup` (`SGROUP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_DUSER_STUDENT` FOREIGN KEY (`STUDENT_ID`) REFERENCES `student` (`STUDENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `duser`
--


--
-- Table structure for table `eduform`
--

DROP TABLE IF EXISTS `eduform`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eduform` (
  `EDUFORM_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EDUFORM_ABBR` varchar(25) NOT NULL,
  `EDUFORM_NAME` varchar(255) NOT NULL,
  `EDUFORM_STIP` tinyint(1) NOT NULL,
  `EDUFORM_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`EDUFORM_ID`),
  UNIQUE KEY `UIDX_EDUFORM` (`EDUFORM_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eduform`
--


--
-- Table structure for table `edutype`
--

DROP TABLE IF EXISTS `edutype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `edutype` (
  `EDUTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EDUTYPE_ABBR` varchar(25) NOT NULL,
  `EDUTYPE_NAME` varchar(255) NOT NULL,
  `EDUTYPE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`EDUTYPE_ID`),
  UNIQUE KEY `UIDX_EDUTYPE` (`EDUTYPE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `edutype`
--


--
-- Table structure for table `facultet`
--

DROP TABLE IF EXISTS `facultet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `facultet` (
  `FACULTET_ID` int(11) NOT NULL AUTO_INCREMENT,
  `SCHOOL_ID` int(11) NOT NULL,
  `EDUTYPE_ID` int(11) NOT NULL,
  `PERSON_ID` int(11) NOT NULL,
  `FACULTET_ABBR` varchar(25) NOT NULL,
  `FACULTET_NAME` varchar(255) DEFAULT NULL,
  `FACULTET_BASESTIP` float DEFAULT NULL,
  `FACULTET_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`FACULTET_ID`),
  UNIQUE KEY `UIDX_FACULTET` (`SCHOOL_ID`,`FACULTET_ABBR`),
  KEY `FK_FACULTET_EDUTYPE` (`EDUTYPE_ID`),
  KEY `FK_FACULTET_PERSON` (`PERSON_ID`),
  CONSTRAINT `FK_FACULTET_EDUTYPE` FOREIGN KEY (`EDUTYPE_ID`) REFERENCES `edutype` (`EDUTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_FACULTET_PERSON` FOREIGN KEY (`PERSON_ID`) REFERENCES `person` (`PERSON_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_FACULTET_SCHOOL` FOREIGN KEY (`SCHOOL_ID`) REFERENCES `school` (`SCHOOL_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `facultet`
--


--
-- Table structure for table `foreignlan`
--

DROP TABLE IF EXISTS `foreignlan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `foreignlan` (
  `FOREIGNLAN_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FOREIGNLAN_NAME` varchar(30) NOT NULL,
  PRIMARY KEY (`FOREIGNLAN_ID`),
  UNIQUE KEY `UIDX_FOREIGNLAN` (`FOREIGNLAN_NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `foreignlan`
--


--
-- Table structure for table `gos`
--

DROP TABLE IF EXISTS `gos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gos` (
  `GOS_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSTITLE_ID` int(11) NOT NULL,
  `GOSCOMP_ID` int(11) NOT NULL,
  `GOSCYCLE_ID` int(11) NOT NULL,
  `GOS_CODE` varchar(25) NOT NULL,
  `GOS_NAME` varchar(255) NOT NULL,
  `GOS_VOL` int(11) NOT NULL,
  PRIMARY KEY (`GOS_ID`),
  UNIQUE KEY `UIDX_GOS` (`GOSTITLE_ID`,`GOS_CODE`),
  KEY `FK_GOS_GOSCOMP` (`GOSCOMP_ID`),
  KEY `FK_GOS_GOSCYCLE` (`GOSCYCLE_ID`),
  CONSTRAINT `FK_GOS_GOSCOMP` FOREIGN KEY (`GOSCOMP_ID`) REFERENCES `goscomp` (`GOSCOMP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_GOS_GOSCYCLE` FOREIGN KEY (`GOSCYCLE_ID`) REFERENCES `goscycle` (`GOSCYCLE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_GOS_GOSTITLE` FOREIGN KEY (`GOSTITLE_ID`) REFERENCES `gostitle` (`GOSTITLE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=601 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gos`
--


--
-- Table structure for table `goscomp`
--

DROP TABLE IF EXISTS `goscomp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `goscomp` (
  `GOSCOMP_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSCOMP_CODE` varchar(25) DEFAULT NULL,
  `GOSCOMP_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`GOSCOMP_ID`),
  UNIQUE KEY `UIDX_GOSCOMP` (`GOSCOMP_CODE`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goscomp`
--


--
-- Table structure for table `goscycle`
--

DROP TABLE IF EXISTS `goscycle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `goscycle` (
  `GOSCYCLE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSCYCLE_CODE` varchar(25) NOT NULL,
  `GOSCYCLE_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`GOSCYCLE_ID`),
  UNIQUE KEY `UIDX_GOSCYCLE` (`GOSCYCLE_CODE`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goscycle`
--


--
-- Table structure for table `gosdir`
--

DROP TABLE IF EXISTS `gosdir`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gosdir` (
  `GOSDIR_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSGROUP_ID` int(11) NOT NULL,
  `GOSDIR_CODE` varchar(25) NOT NULL,
  `GOSDIR_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`GOSDIR_ID`),
  UNIQUE KEY `UIDX_GOSDIR` (`GOSDIR_CODE`),
  KEY `FK_GOSDIR_GOSGROUP` (`GOSGROUP_ID`),
  CONSTRAINT `FK_GOSDIR_GOSGROUP` FOREIGN KEY (`GOSGROUP_ID`) REFERENCES `gosgroup` (`GOSGROUP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gosdir`
--


--
-- Table structure for table `gosgroup`
--

DROP TABLE IF EXISTS `gosgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gosgroup` (
  `GOSGROUP_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSGROUP_CODE` varchar(25) NOT NULL,
  `GOSGROUP_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`GOSGROUP_ID`),
  UNIQUE KEY `UIDX_GOSGROUP` (`GOSGROUP_CODE`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gosgroup`
--


--
-- Table structure for table `gostitle`
--

DROP TABLE IF EXISTS `gostitle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gostitle` (
  `GOSTITLE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSDIR_ID` int(11) NOT NULL,
  `GOSTITLE_CODE` varchar(10) NOT NULL,
  `GOSTITLE_NAME` varchar(255) NOT NULL,
  `GOSTITLE_DOC` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`GOSTITLE_ID`),
  UNIQUE KEY `UIDX_GOSTITLE` (`GOSTITLE_CODE`),
  KEY `FK_GOSTITLE_GOSDIR` (`GOSDIR_ID`),
  CONSTRAINT `FK_GOSTITLE_GOSDIR` FOREIGN KEY (`GOSDIR_ID`) REFERENCES `gosdir` (`GOSDIR_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gostitle`
--


--
-- Table structure for table `gsubj`
--

DROP TABLE IF EXISTS `gsubj`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gsubj` (
  `GSUBJ_ID` int(11) NOT NULL AUTO_INCREMENT,
  `FACULTET_ID` int(11) NOT NULL,
  `GOS_ID` int(11) NOT NULL,
  `SUBJ_ID` int(11) NOT NULL,
  `GSUBJ_CODE` varchar(25) NOT NULL,
  PRIMARY KEY (`GSUBJ_ID`),
  UNIQUE KEY `UIDX_GSUBJ` (`FACULTET_ID`,`GOS_ID`,`SUBJ_ID`),
  KEY `FK_GSUBJ_GOS` (`GOS_ID`),
  KEY `FK_GSUBJ_SUBJ` (`SUBJ_ID`),
  CONSTRAINT `FK_GSUBJ_FACULTET` FOREIGN KEY (`FACULTET_ID`) REFERENCES `facultet` (`FACULTET_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_GSUBJ_GOS` FOREIGN KEY (`GOS_ID`) REFERENCES `gos` (`GOS_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_GSUBJ_SUBJ` FOREIGN KEY (`SUBJ_ID`) REFERENCES `subj` (`SUBJ_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gsubj`
--


--
-- Table structure for table `mainprog`
--

DROP TABLE IF EXISTS `mainprog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mainprog` (
  `MAINPROG_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DSESSION_ID` int(11) NOT NULL,
  `CONTROL_ID` int(11) NOT NULL,
  `VOLUME` int(11) NOT NULL DEFAULT 0,
  `MAINPROG_HIDFLAG` tinyint(1) NOT NULL DEFAULT 0,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`MAINPROG_ID`),
  KEY `FK_MAINPROG_CONTROL` (`CONTROL_ID`),
  KEY `tIDX_MAINPROG` (`DSESSION_ID`,`CUSR_`,`CONTROL_ID`),
  CONSTRAINT `FK_MAINPROG_CONTROL` FOREIGN KEY (`CONTROL_ID`) REFERENCES `control` (`CONTROL_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_MAINPROG_DSESSION` FOREIGN KEY (`DSESSION_ID`) REFERENCES `dsession` (`DSESSION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=26195 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mainprog`
--


--
-- Table structure for table `managertype`
--

DROP TABLE IF EXISTS `managertype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `managertype` (
  `MANAGERTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `MANAGERTYPE_ABBR` varchar(25) NOT NULL,
  `MANAGERTYPE_NAME` varchar(100) DEFAULT NULL,
  `MANAGERTYPE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`MANAGERTYPE_ID`),
  UNIQUE KEY `UIDX_MANAGERTYPE` (`MANAGERTYPE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `managertype`
--


--
-- Table structure for table `mprogsubj`
--

DROP TABLE IF EXISTS `mprogsubj`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mprogsubj` (
  `MPROGSUBJ_ID` int(11) NOT NULL AUTO_INCREMENT,
  `MAINPROG_ID` int(11) NOT NULL,
  `SUBJ_ID` int(11) NOT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`MPROGSUBJ_ID`),
  UNIQUE KEY `UI_MPROGSUBJ` (`MAINPROG_ID`,`SUBJ_ID`),
  UNIQUE KEY `UIDX_MPROGSUBJ` (`MAINPROG_ID`,`SUBJ_ID`),
  KEY `FK_MPROGSUBJ_SUBJ` (`SUBJ_ID`),
  CONSTRAINT `FK_MPROGSUBJ_MAINPROG` FOREIGN KEY (`MAINPROG_ID`) REFERENCES `mainprog` (`MAINPROG_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_MPROGSUBJ_SUBJ` FOREIGN KEY (`SUBJ_ID`) REFERENCES `subj` (`SUBJ_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=28655 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mprogsubj`
--


--
-- Table structure for table `persname`
--

DROP TABLE IF EXISTS `persname`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `persname` (
  `PERSNAME_ID` int(11) NOT NULL AUTO_INCREMENT,
  `PERSPROG_ID` int(11) DEFAULT NULL,
  `PERSNAME_NAME` varchar(255) NOT NULL,
  `DOCUMENT_ID` int(11) DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`PERSNAME_ID`),
  UNIQUE KEY `UIDX_PERSNAME` (`PERSPROG_ID`),
  KEY `FK_PERSNAME_DOCUMENT` (`DOCUMENT_ID`),
  CONSTRAINT `FK_PERSNAME_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PERSNAME_PERSPROG` FOREIGN KEY (`PERSPROG_ID`) REFERENCES `persprog` (`PERSPROG_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4838 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `persname`
--


--
-- Table structure for table `person`
--

DROP TABLE IF EXISTS `person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person` (
  `PERSON_ID` int(11) NOT NULL AUTO_INCREMENT,
  `PERSTATUS_ID` int(11) NOT NULL,
  `PERSON_FNAME` varchar(50) NOT NULL,
  `PERSON_MNAME` varchar(50) NOT NULL,
  `PERSON_LNAME` varchar(50) NOT NULL,
  PRIMARY KEY (`PERSON_ID`),
  UNIQUE KEY `UIDX_PERSON` (`PERSTATUS_ID`,`PERSON_FNAME`,`PERSON_MNAME`,`PERSON_LNAME`),
  CONSTRAINT `FK_PERSON_PERSTATUS` FOREIGN KEY (`PERSTATUS_ID`) REFERENCES `perstatus` (`PERSTATUS_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `person`
--


--
-- Table structure for table `persprog`
--

DROP TABLE IF EXISTS `persprog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `persprog` (
  `PERSPROG_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STUDSGRP_ID` int(11) NOT NULL,
  `MAINPROG_ID` int(11) NOT NULL,
  `MPROGSUBJ_ID` int(11) NOT NULL,
  `VOLUME` int(11) NOT NULL DEFAULT 0,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`PERSPROG_ID`),
  UNIQUE KEY `UIDX_PERSPROG` (`MAINPROG_ID`,`STUDSGRP_ID`),
  KEY `FK_PERSPROG_MPROGSUBJ` (`MPROGSUBJ_ID`),
  KEY `FK_PERSPROG_STUDSGRP` (`STUDSGRP_ID`),
  KEY `IDX_PPKEY` (`MPROGSUBJ_ID`,`STUDSGRP_ID`),
  CONSTRAINT `FK_PERSPROG_MAINPROG` FOREIGN KEY (`MAINPROG_ID`) REFERENCES `mainprog` (`MAINPROG_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PERSPROG_MPROGSUBJ` FOREIGN KEY (`MPROGSUBJ_ID`) REFERENCES `mprogsubj` (`MPROGSUBJ_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PERSPROG_STUDSGRP` FOREIGN KEY (`STUDSGRP_ID`) REFERENCES `studsgrp` (`STUDSGRP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=896920 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `persprog`
--


--
-- Table structure for table `perstatus`
--

DROP TABLE IF EXISTS `perstatus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `perstatus` (
  `PERSTATUS_ID` int(11) NOT NULL AUTO_INCREMENT,
  `PERSTATUS_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`PERSTATUS_ID`),
  UNIQUE KEY `UIDX_PERSTATUS` (`PERSTATUS_NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `perstatus`
--


--
-- Table structure for table `phasectrl`
--

DROP TABLE IF EXISTS `phasectrl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `phasectrl` (
  `PHASECTRL_ID` int(11) NOT NULL AUTO_INCREMENT,
  `SESSPHASE_ID` int(11) NOT NULL,
  `CONTROL_ID` int(11) NOT NULL,
  PRIMARY KEY (`PHASECTRL_ID`),
  UNIQUE KEY `UIDX_PHASECTRL` (`SESSPHASE_ID`,`CONTROL_ID`),
  KEY `FK_PHASECTRL_CONTROL` (`CONTROL_ID`),
  CONSTRAINT `FK_PHASECTRL_CONTROL` FOREIGN KEY (`CONTROL_ID`) REFERENCES `control` (`CONTROL_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PHASECTRL_SESSPHASE` FOREIGN KEY (`SESSPHASE_ID`) REFERENCES `sessphase` (`SESSPHASE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `phasectrl`
--


--
-- Table structure for table `progdoc`
--

DROP TABLE IF EXISTS `progdoc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `progdoc` (
  `PROGDOC_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DOCUMENT_ID` int(11) NOT NULL,
  `PERSPROG_ID` int(11) NOT NULL,
  PRIMARY KEY (`PROGDOC_ID`),
  UNIQUE KEY `UIDX_PROGDOC` (`DOCUMENT_ID`,`PERSPROG_ID`),
  KEY `FK_ADOCPPROG_PERSPROG` (`PERSPROG_ID`),
  CONSTRAINT `FK_ADOCPPROG_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_ADOCPPROG_PERSPROG` FOREIGN KEY (`PERSPROG_ID`) REFERENCES `persprog` (`PERSPROG_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=731588 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `progdoc`
--


--
-- Table structure for table `prolong`
--

DROP TABLE IF EXISTS `prolong`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `prolong` (
  `PROLONG_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DSESSION_ID` int(11) NOT NULL,
  `STUDSGRP_ID` int(11) NOT NULL,
  `PROLTYPE_ID` int(11) NOT NULL,
  `PROLONG_TODATE` date NOT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`PROLONG_ID`),
  UNIQUE KEY `UIDX_PROLONG` (`DSESSION_ID`,`STUDSGRP_ID`),
  KEY `FK_PROLONG_PROLTYPE` (`PROLTYPE_ID`),
  KEY `FK_PROLONG_STUDSGRP` (`STUDSGRP_ID`),
  CONSTRAINT `FK_PROLONG_DSESSION` FOREIGN KEY (`DSESSION_ID`) REFERENCES `dsession` (`DSESSION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PROLONG_PROLTYPE` FOREIGN KEY (`PROLTYPE_ID`) REFERENCES `proltype` (`PROLTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_PROLONG_STUDSGRP` FOREIGN KEY (`STUDSGRP_ID`) REFERENCES `studsgrp` (`STUDSGRP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `prolong`
--


--
-- Table structure for table `proltype`
--

DROP TABLE IF EXISTS `proltype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `proltype` (
  `PROLTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `PROLTYPE_ABBR` varchar(25) NOT NULL,
  `PROLTYPE_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`PROLTYPE_ID`),
  UNIQUE KEY `UIDX_PROLTYPE` (`PROLTYPE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proltype`
--


--
-- Table structure for table `protocol`
--

DROP TABLE IF EXISTS `protocol`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `protocol` (
  `PROTOCOL_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EVENT_TYPE` enum('Успешно','Инфо','Предупреждение','Ошибка','Сбой') DEFAULT NULL,
  `EVENT_DESC` varchar(150) DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`PROTOCOL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `protocol`
--


--
-- Table structure for table `region`
--

DROP TABLE IF EXISTS `region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `region` (
  `REGION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `COUNTRY_ID` int(11) NOT NULL,
  `REGION_NAME` varchar(100) NOT NULL,
  PRIMARY KEY (`REGION_ID`),
  UNIQUE KEY `UIDX_REGION` (`COUNTRY_ID`,`REGION_NAME`),
  CONSTRAINT `FK_REGION_COUNTRY` FOREIGN KEY (`COUNTRY_ID`) REFERENCES `country` (`COUNTRY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `region`
--


--
-- Table structure for table `resset`
--

DROP TABLE IF EXISTS `resset`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resset` (
  `RESSET_ID` int(11) NOT NULL AUTO_INCREMENT,
  `CONTROL_ID` int(11) NOT NULL,
  `RESULT_ID` int(11) NOT NULL,
  PRIMARY KEY (`RESSET_ID`),
  UNIQUE KEY `UIDX_RESSET` (`CONTROL_ID`,`RESULT_ID`),
  KEY `FK_RESSET_RESULT` (`RESULT_ID`),
  CONSTRAINT `FK_RESSET_CONTROL` FOREIGN KEY (`CONTROL_ID`) REFERENCES `control` (`CONTROL_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_RESSET_RESULT` FOREIGN KEY (`RESULT_ID`) REFERENCES `result` (`RESULT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=157 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resset`
--


--
-- Table structure for table `result`
--

DROP TABLE IF EXISTS `result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `result` (
  `RESULT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `RESULT_INT` int(11) DEFAULT NULL,
  `RESULT_ABBR` varchar(10) NOT NULL,
  `RESULT_NAME` varchar(50) NOT NULL,
  `RESULT_PASSFLAG` tinyint(1) NOT NULL,
  `RESULT_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`RESULT_ID`),
  UNIQUE KEY `UIDX_RESULT` (`RESULT_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `result`
--


--
-- Table structure for table `school`
--

DROP TABLE IF EXISTS `school`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `school` (
  `SCHOOL_ID` int(11) NOT NULL AUTO_INCREMENT,
  `CITY_ID` int(11) DEFAULT NULL,
  `PERSON_ID` int(11) NOT NULL,
  `SCHOOL_DEPT` varchar(255) NOT NULL,
  `SCHOOL_ABBR` varchar(25) NOT NULL,
  `SCHOOL_NAME` varchar(255) NOT NULL,
  `SCHOOL_NPUNKT` varchar(100) DEFAULT NULL,
  `SCHOOL_POST` varchar(25) DEFAULT NULL,
  `SCHOOL_STREET` varchar(100) DEFAULT NULL,
  `SCHOOL_BLDNO` varchar(10) DEFAULT NULL,
  `SCHOOL_OFFNO` varchar(10) DEFAULT NULL,
  `SCHOOL_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`SCHOOL_ID`),
  UNIQUE KEY `UIDX_SCHOOL` (`CITY_ID`,`SCHOOL_ABBR`),
  KEY `FK_SCHOOL_PERSON` (`PERSON_ID`),
  CONSTRAINT `FK_SCHOOL_CITY` FOREIGN KEY (`CITY_ID`) REFERENCES `city` (`CITY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_SCHOOL_PERSON` FOREIGN KEY (`PERSON_ID`) REFERENCES `person` (`PERSON_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `school`
--


--
-- Table structure for table `sessphase`
--

DROP TABLE IF EXISTS `sessphase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessphase` (
  `SESSPHASE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `SESSPHASE_ABBR` varchar(25) NOT NULL,
  `SESSPHASE_NAME` varchar(255) DEFAULT NULL,
  `SESSPHASE_HIDFLAG` tinyint(1) NOT NULL DEFAULT 0,
  `SESSPHASE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`SESSPHASE_ID`),
  UNIQUE KEY `UIDX_SESSPHASE` (`SESSPHASE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessphase`
--


--
-- Table structure for table `sgroup`
--

DROP TABLE IF EXISTS `sgroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sgroup` (
  `SGROUP_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STREAM_ID` int(11) NOT NULL,
  `SBOSS_ID` int(11) DEFAULT NULL,
  `SGROUP_NAMEINDEX` varchar(10) NOT NULL,
  `SGROUP_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`SGROUP_ID`),
  UNIQUE KEY `UIDX_SGROUP` (`STREAM_ID`,`SGROUP_NAMEINDEX`),
  KEY `FK_SGROUP_STUDENT` (`SBOSS_ID`),
  CONSTRAINT `FK_SGROUP_STREAM` FOREIGN KEY (`STREAM_ID`) REFERENCES `stream` (`STREAM_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_SGROUP_STUDENT` FOREIGN KEY (`SBOSS_ID`) REFERENCES `student` (`STUDENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=458 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sgroup`
--


--
-- Table structure for table `statustype`
--

DROP TABLE IF EXISTS `statustype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statustype` (
  `STATUSTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STATUSTYPE_ABBR` varchar(25) DEFAULT NULL,
  `STATUSTYPE_NAME` varchar(255) DEFAULT NULL,
  `STATUSTYPE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`STATUSTYPE_ID`),
  UNIQUE KEY `UIDX_STATUSTYPE` (`STATUSTYPE_ABBR`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statustype`
--


--
-- Table structure for table `stipend`
--

DROP TABLE IF EXISTS `stipend`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stipend` (
  `STIPEND_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DOCUMENT_ID` int(11) DEFAULT NULL,
  `STIPTYPE_ID` int(11) DEFAULT NULL,
  `STIPEND_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`STIPEND_ID`),
  KEY `FK_STIPEND_DOCUMENT` (`DOCUMENT_ID`),
  KEY `FK_STIPEND_STIPTYPE` (`STIPTYPE_ID`),
  CONSTRAINT `FK_STIPEND_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STIPEND_STIPTYPE` FOREIGN KEY (`STIPTYPE_ID`) REFERENCES `stiptype` (`STIPTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stipend`
--


--
-- Table structure for table `stiptype`
--

DROP TABLE IF EXISTS `stiptype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stiptype` (
  `STIPTYPE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STIPTYPE_ABBR` varchar(30) NOT NULL,
  `STIPTYPE_NAME` varchar(120) DEFAULT NULL,
  `STIPTYPE_COEFF` double DEFAULT NULL,
  `STIPTYPE_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`STIPTYPE_ID`),
  UNIQUE KEY `UIDX_STIPTYPE` (`STIPTYPE_ABBR`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stiptype`
--


--
-- Table structure for table `stream`
--

DROP TABLE IF EXISTS `stream`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stream` (
  `STREAM_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DIVISION_ID` int(11) NOT NULL,
  `STREAM_FROMYEAR` year(4) NOT NULL,
  `STREAM_SEMCOUNT` int(11) NOT NULL DEFAULT 1,
  `STREAM_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`STREAM_ID`),
  UNIQUE KEY `UIDX_STREAM` (`DIVISION_ID`,`STREAM_FROMYEAR`),
  CONSTRAINT `FK_STREAM_DIVISION` FOREIGN KEY (`DIVISION_ID`) REFERENCES `division` (`DIVISION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=260 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stream`
--


--
-- Table structure for table `studadd`
--

DROP TABLE IF EXISTS `studadd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `studadd` (
  `STUDENT_ID` int(11) NOT NULL DEFAULT 0,
  `STUDENT_SEX` enum('М','Ж') DEFAULT NULL,
  `STUDENT_PASSPNO` varchar(255) DEFAULT NULL,
  `CITY_ID` int(11) DEFAULT NULL,
  `STUDENT_POSTINDEX` varchar(20) DEFAULT NULL,
  `STUDENT_NPUNKT` varchar(100) DEFAULT NULL,
  `STUDENT_STREET` varchar(100) DEFAULT NULL,
  `STUDENT_BLDNO` varchar(10) DEFAULT NULL,
  `STUDENT_FLATNO` varchar(10) DEFAULT NULL,
  `STUDENT_BIRTHDAY` date DEFAULT NULL,
  `COUNTRY_ID` int(11) DEFAULT NULL,
  `STUDENT_FAMSTATE` enum('холост','не замужем','женат','замужем') DEFAULT NULL,
  `STUDENT_FATHER` varchar(100) DEFAULT NULL,
  `STUDENT_FATHERWORK` varchar(100) DEFAULT NULL,
  `STUDENT_MOTHER` varchar(100) DEFAULT NULL,
  `STUDENT_MOTHERWORK` varchar(100) DEFAULT NULL,
  `STUDENT_EMAIL` varchar(100) DEFAULT NULL,
  `STUDENT_PHONE1` varchar(15) DEFAULT NULL,
  `STUDENT_PHONE2` varchar(15) DEFAULT NULL,
  `STUDENT_PHONE3` varchar(15) DEFAULT NULL,
  `STUDENT_OBADDR` varchar(20) DEFAULT NULL,
  `FOREIGNLAN_ID` int(11) DEFAULT NULL,
  `ABIT_ID` int(11) DEFAULT NULL,
  `STUDENT_FIRM` varchar(100) DEFAULT NULL,
  `STUDENT_ADDWORK` varchar(255) DEFAULT NULL,
  `STUDENT_FIRSTWORK` varchar(255) DEFAULT NULL,
  `STUDENT_PHOTOPATH` varchar(255) DEFAULT NULL,
  `STUDENT_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`STUDENT_ID`),
  KEY `FK_STUDADD_CITY` (`CITY_ID`),
  KEY `FK_STUDADD_COUNTRY` (`COUNTRY_ID`),
  KEY `FK_STUDADD_FOREIGNLAN` (`FOREIGNLAN_ID`),
  KEY `FK_STUDADD_ABIT` (`ABIT_ID`),
  CONSTRAINT `FK_STUDADD_ABIT` FOREIGN KEY (`ABIT_ID`) REFERENCES `abit` (`ABIT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDADD_CITY` FOREIGN KEY (`CITY_ID`) REFERENCES `city` (`CITY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDADD_COUNTRY` FOREIGN KEY (`COUNTRY_ID`) REFERENCES `country` (`COUNTRY_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDADD_FOREIGNLAN` FOREIGN KEY (`FOREIGNLAN_ID`) REFERENCES `foreignlan` (`FOREIGNLAN_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDADD_STUDENT` FOREIGN KEY (`STUDENT_ID`) REFERENCES `student` (`STUDENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studadd`
--


--
-- Table structure for table `studdoc`
--

DROP TABLE IF EXISTS `studdoc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `studdoc` (
  `STUDDOC_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STUDSGRP_ID` int(11) NOT NULL,
  `DOCUMENT_ID` int(11) NOT NULL,
  PRIMARY KEY (`STUDDOC_ID`),
  UNIQUE KEY `UIDX_STUDDOC` (`STUDSGRP_ID`,`DOCUMENT_ID`),
  KEY `FK_STUDDOC_DOCUMENT` (`DOCUMENT_ID`),
  CONSTRAINT `FK_STUDDOC_DOCUMENT` FOREIGN KEY (`DOCUMENT_ID`) REFERENCES `document` (`DOCUMENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDDOC_STUDSGRP` FOREIGN KEY (`STUDSGRP_ID`) REFERENCES `studsgrp` (`STUDSGRP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=25159 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studdoc`
--


--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `student` (
  `STUDENT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STUDENT_PERSNO` varchar(25) NOT NULL,
  `STUDENT_PERIOD` int(11) NOT NULL DEFAULT 0,
  `STUDENT_ZACHNO` varchar(25) DEFAULT NULL,
  `STUDENT_STRAHNO` varchar(25) DEFAULT NULL,
  `STUDENT_FNAME` varchar(50) NOT NULL,
  `STUDENT_MNAME` varchar(50) NOT NULL,
  `STUDENT_LNAME` varchar(50) NOT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`STUDENT_ID`),
  UNIQUE KEY `UIDX_STUDENT` (`STUDENT_PERSNO`,`STUDENT_PERIOD`)
) ENGINE=InnoDB AUTO_INCREMENT=7594 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student`
--

/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`greenworks`@`%`*/ /*!50003 TRIGGER `ins_student` BEFORE INSERT ON `student` FOR EACH ROW SET NEW.STUDENT_PERIOD := CAST(YEAR(NOW()) AS SIGNED) */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `studsgrp`
--

DROP TABLE IF EXISTS `studsgrp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `studsgrp` (
  `STUDSGRP_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DIVISION_ID` int(11) NOT NULL,
  `SGROUP_ID` int(11) NOT NULL,
  `STUDENT_ID` int(11) NOT NULL,
  `EDUFORM_ID` int(11) NOT NULL,
  PRIMARY KEY (`STUDSGRP_ID`),
  UNIQUE KEY `UIDX_STUDSGRP` (`DIVISION_ID`,`STUDENT_ID`),
  KEY `FK_STUDSGRP_SGROUP` (`SGROUP_ID`),
  KEY `FK_STUDSGRP_STUDENT` (`STUDENT_ID`),
  KEY `FK_STUDSGRP_EDUFORM` (`EDUFORM_ID`),
  CONSTRAINT `FK_STUDSGRP_DIVISION` FOREIGN KEY (`DIVISION_ID`) REFERENCES `division` (`DIVISION_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDSGRP_EDUFORM` FOREIGN KEY (`EDUFORM_ID`) REFERENCES `eduform` (`EDUFORM_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDSGRP_SGROUP` FOREIGN KEY (`SGROUP_ID`) REFERENCES `sgroup` (`SGROUP_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `FK_STUDSGRP_STUDENT` FOREIGN KEY (`STUDENT_ID`) REFERENCES `student` (`STUDENT_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=7621 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studsgrp`
--


--
-- Table structure for table `studstatus`
--

DROP TABLE IF EXISTS `studstatus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `studstatus` (
  `STUDSTATUS_ID` int(11) NOT NULL AUTO_INCREMENT,
  `STATUSTYPE_ID` int(11) NOT NULL,
  `STUDSTATUS_NAME` varchar(255) DEFAULT NULL,
  `STUDSTATUS_ACTIVE` tinyint(1) NOT NULL,
  `STUDSTATUS_DESC` tinytext DEFAULT NULL,
  PRIMARY KEY (`STUDSTATUS_ID`),
  UNIQUE KEY `UIDX_STUDSTATUS` (`STUDSTATUS_NAME`),
  KEY `FK_STUDSTATUS_STATUSTYPE` (`STATUSTYPE_ID`),
  CONSTRAINT `FK_STUDSTATUS_STATUSTYPE` FOREIGN KEY (`STATUSTYPE_ID`) REFERENCES `statustype` (`STATUSTYPE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studstatus`
--


--
-- Table structure for table `subj`
--

DROP TABLE IF EXISTS `subj`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subj` (
  `SUBJ_ID` int(11) NOT NULL AUTO_INCREMENT,
  `SUBJ_ABBR` varchar(25) NOT NULL,
  `SUBJ_NAME` varchar(255) NOT NULL,
  `SUBJ_DESC` tinytext DEFAULT NULL,
  `CRT_` datetime DEFAULT NULL,
  `CUSR_` int(11) DEFAULT NULL,
  `UPD_` datetime DEFAULT NULL,
  `UUSR_` int(11) DEFAULT NULL,
  PRIMARY KEY (`SUBJ_ID`),
  UNIQUE KEY `UI_SUBJ` (`SUBJ_ABBR`),
  UNIQUE KEY `UIDX_SUBJA` (`SUBJ_ABBR`),
  UNIQUE KEY `UIDX_SUBJN` (`SUBJ_NAME`)
) ENGINE=InnoDB AUTO_INCREMENT=1128 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subj`
--


--
-- Table structure for table `subspec`
--

DROP TABLE IF EXISTS `subspec`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subspec` (
  `SUBSPEC_ID` int(11) NOT NULL AUTO_INCREMENT,
  `GOSTITLE_ID` int(11) NOT NULL,
  `SUBSPEC_CODE` varchar(25) NOT NULL,
  `SUBSPEC_NAME` varchar(255) NOT NULL,
  PRIMARY KEY (`SUBSPEC_ID`),
  UNIQUE KEY `UIDX_SUBSPEC` (`SUBSPEC_CODE`),
  KEY `FK_SUBSPEC_GOSTITLE` (`GOSTITLE_ID`),
  CONSTRAINT `FK_SUBSPEC_GOSTITLE` FOREIGN KEY (`GOSTITLE_ID`) REFERENCES `gostitle` (`GOSTITLE_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subspec`
--


--
-- Table structure for table `syslog`
--

DROP TABLE IF EXISTS `syslog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `syslog` (
  `SYSLOG_ID` int(11) NOT NULL AUTO_INCREMENT,
  `SYSLOG_TIMESTAMP` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `DUSER_ID` int(11) NOT NULL,
  `SYSLOG_IP` int(11) NOT NULL,
  `SYSLOG_STATEMENT` varchar(255) NOT NULL,
  `SYSLOG_ERRNO` int(11) NOT NULL,
  `SYSLOG_ERRDESC` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`SYSLOG_ID`),
  KEY `FK_SYSLOG_DUSER` (`DUSER_ID`),
  CONSTRAINT `FK_SYSLOG_DUSER` FOREIGN KEY (`DUSER_ID`) REFERENCES `duser` (`DUSER_ID`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `syslog`
--


--
-- Table structure for table `version`
--

DROP TABLE IF EXISTS `version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `version` (
  `VERNO` decimal(6,3) NOT NULL,
  `VERDATE` datetime NOT NULL,
  PRIMARY KEY (`VERNO`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `version`
--


DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-06  0:30:04
