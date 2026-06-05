-- MoodWalls V3 · 搜索历史表（可选，R07 服务端同步时才需要）
-- 默认方案用客户端本地存储时可跳过本脚本
-- 执行：mysql -u root -p moodwalls < sql/migrations/V3_004_search_history.sql

USE moodwalls;

CREATE TABLE IF NOT EXISTS search_history (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '用户ID',
  keyword    VARCHAR(64)  NOT NULL COMMENT '搜索关键词',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_search_history_user (user_id, created_at),
  CONSTRAINT fk_search_history_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户搜索历史（可选）';
