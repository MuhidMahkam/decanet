-- decanet schema placeholder
-- This file should contain the full SQL schema extracted from sql/decanet_demo.zip
-- TODO: Replace this placeholder with the actual CREATE TABLE / INDEX / CONSTRAINT statements
-- If you want, I can extract the SQL from the zip and update this file. For now, this is a scaffold to keep schema in repo.

-- Example placeholder table to validate import (remove when real schema is added)
CREATE TABLE IF NOT EXISTS `dc_version` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `version` VARCHAR(64) NOT NULL,
  `applied_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;