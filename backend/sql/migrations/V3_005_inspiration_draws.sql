-- MoodWalls V3 · 陌生人小纸条抽取记录（H05）
-- 执行：mysql -u root -p moodwalls < sql/migrations/V3_005_inspiration_draws.sql

USE moodwalls;

CREATE TABLE IF NOT EXISTS inspiration_draws (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  user_id    BIGINT       NOT NULL COMMENT '抽取用户ID',
  post_id    BIGINT       DEFAULT NULL COMMENT '来源帖子ID，种子句为空',
  content    VARCHAR(200) NOT NULL COMMENT '展示摘句快照',
  mood       VARCHAR(16)  DEFAULT NULL COMMENT '情绪key',
  draw_date  DATE         NOT NULL COMMENT '抽取日期（上海时区）',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_inspiration_user_date (user_id, draw_date),
  KEY idx_inspiration_user_post (user_id, post_id),
  CONSTRAINT fk_inspiration_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='每日小纸条抽取记录';
