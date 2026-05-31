-- MoodWalls 数据库初始化脚本
-- 在 MySQL 中执行：mysql -u root -p < sql/init.sql

CREATE DATABASE IF NOT EXISTS moodwalls
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE moodwalls;

-- JPA ddl-auto=update 会自动建表，此脚本供手动初始化参考
CREATE TABLE IF NOT EXISTS users (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  nickname      VARCHAR(64)  NOT NULL,
  phone         VARCHAR(20)  NOT NULL,
  student_id    VARCHAR(32)  DEFAULT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    DATETIME(6)  NOT NULL,
  updated_at    DATETIME(6)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_phone (phone),
  UNIQUE KEY uk_users_student_id (student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
