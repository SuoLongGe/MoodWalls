-- MoodWalls V3 · 鼓励小纸条独立表 + 抽取记录改关联 note_id
-- 执行：mysql -u root -p moodwalls < sql/migrations/V3_006_encouragement_notes.sql

USE moodwalls;

CREATE TABLE IF NOT EXISTS encouragement_notes (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '作者用户ID（抽取时不展示）',
  content    VARCHAR(200) NOT NULL COMMENT '鼓励内容，8~120字',
  mood       VARCHAR(32)  NOT NULL DEFAULT 'calm' COMMENT '情绪语气：happy/calm/moved',
  status     TINYINT      NOT NULL DEFAULT 1 COMMENT '1正常 0删除',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_encouragement_notes_user_id (user_id),
  KEY idx_encouragement_notes_status_created (status, created_at),
  CONSTRAINT fk_encouragement_notes_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='鼓励小纸条';

-- 若旧表使用 post_id，迁移为 note_id
SET @has_post_id := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'inspiration_draws'
    AND COLUMN_NAME = 'post_id'
);

SET @sql_drop_post := IF(
  @has_post_id > 0,
  'ALTER TABLE inspiration_draws DROP COLUMN post_id',
  'SELECT 1'
);
PREPARE stmt_drop_post FROM @sql_drop_post;
EXECUTE stmt_drop_post;
DEALLOCATE PREPARE stmt_drop_post;

SET @has_note_id := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'inspiration_draws'
    AND COLUMN_NAME = 'note_id'
);

SET @sql_add_note := IF(
  @has_note_id = 0,
  'ALTER TABLE inspiration_draws ADD COLUMN note_id BIGINT DEFAULT NULL COMMENT ''来源小纸条ID'' AFTER user_id',
  'SELECT 1'
);
PREPARE stmt_add_note FROM @sql_add_note;
EXECUTE stmt_add_note;
DEALLOCATE PREPARE stmt_add_note;

SET @has_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'inspiration_draws'
    AND CONSTRAINT_NAME = 'fk_inspiration_note'
);

SET @sql_add_fk := IF(
  @has_fk = 0,
  'ALTER TABLE inspiration_draws ADD CONSTRAINT fk_inspiration_note FOREIGN KEY (note_id) REFERENCES encouragement_notes (id)',
  'SELECT 1'
);
PREPARE stmt_add_fk FROM @sql_add_fk;
EXECUTE stmt_add_fk;
DEALLOCATE PREPARE stmt_add_fk;
