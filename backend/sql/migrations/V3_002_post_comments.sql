-- MoodWalls V3 · 帖子评论表（含 R03 回复字段）
-- 适用：库中尚无 post_comments 表时一次性执行
-- 执行：mysql -u root -p moodwalls < sql/migrations/V3_002_post_comments.sql

USE moodwalls;

CREATE TABLE IF NOT EXISTS post_comments (
  id               BIGINT       NOT NULL AUTO_INCREMENT,
  post_id          BIGINT       NOT NULL COMMENT '关联帖子ID',
  user_id          BIGINT       NOT NULL COMMENT '评论用户ID',
  content          VARCHAR(200) NOT NULL COMMENT '评论内容（最多200字）',
  comment_type     VARCHAR(16)  NOT NULL DEFAULT 'resonance'
    COMMENT '评论类型：resonance公开共鸣 / whisper悄悄话',
  parent_id        BIGINT       DEFAULT NULL
    COMMENT '父评论ID，NULL为一级评论；非NULL为回复',
  reply_to_user_id BIGINT       DEFAULT NULL
    COMMENT '被回复用户ID（展示「回复 @昵称」）',
  status           TINYINT      NOT NULL DEFAULT 1
    COMMENT '状态：1正常 0删除 2审核拦截',
  created_at       DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at       DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_post_comments_post_id (post_id),
  KEY idx_post_comments_user_id (user_id),
  KEY idx_post_comments_type (comment_type),
  KEY idx_post_comments_status_created (status, created_at),
  KEY idx_post_comments_parent (parent_id),
  CONSTRAINT fk_post_comments_post
    FOREIGN KEY (post_id) REFERENCES posts (id),
  CONSTRAINT fk_post_comments_user
    FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_post_comments_parent
    FOREIGN KEY (parent_id) REFERENCES post_comments (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子评论记录';
