-- MoodWalls V3 · 帖子送云记录（D06 持久化）
-- 执行：mysql -u root -p moodwalls < sql/migrations/V3_007_post_cloud_gifts.sql

USE moodwalls;

CREATE TABLE IF NOT EXISTS post_cloud_gifts (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL COMMENT '送云用户ID',
  post_id    BIGINT      NOT NULL COMMENT '目标帖子ID',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_post_cloud_gifts_post_id (post_id),
  KEY idx_post_cloud_gifts_user_post_created (user_id, post_id, created_at),
  CONSTRAINT fk_post_cloud_gifts_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_post_cloud_gifts_post FOREIGN KEY (post_id) REFERENCES posts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子送云记录';
